#!/bin/bash
################################################################################
# AOSP 15 Build Script for Raspberry Pi 5
# DSI Display Configuration + Kernel Integration + Optimized Build
# Target: ED-HMI3010-070C 7" Display with GT911 Touch
# RAM: 55GB optimized build
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
WORKSPACE_DIR="${HOME}/aosp-rpi5"
AOSP_DIR="${WORKSPACE_DIR}/aosp"
KERNEL_DIR="${WORKSPACE_DIR}/kernel/linux"
DEVICE_TREE_DIR="${WORKSPACE_DIR}/device-tree"
DEVICE_DIR="${AOSP_DIR}/device/rpi/rpi5"
OUTPUT_DIR="${WORKSPACE_DIR}/output"

# Build optimization for 55GB RAM
MAX_RAM_GB=55
JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx20g"
BUILD_JOBS=$(($(nproc) + 2))  # Slightly more jobs than cores for I/O wait

# Kernel configuration
KERNEL_BRANCH="rpi-6.8.y"
KERNEL_DEFCONFIG="bcm2712_defconfig"

################################################################################
# Helper Functions
################################################################################

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_section() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

log_step() {
    echo -e "${CYAN}>>> $1${NC}"
}

check_prerequisites() {
    log_section "Checking Prerequisites"
    
    # Check if AOSP source exists
    if [ ! -d "${AOSP_DIR}" ] || [ ! -d "${AOSP_DIR}/.repo" ]; then
        log_error "AOSP source not found at ${AOSP_DIR}"
        log_error "Please run automated-aosp-setup.sh first"
        exit 1
    fi
    
    # Check if kernel source exists
    if [ ! -d "${KERNEL_DIR}" ]; then
        log_error "Kernel source not found at ${KERNEL_DIR}"
        log_error "Please run automated-aosp-setup.sh first"
        exit 1
    fi
    
    # Check available RAM
    AVAILABLE_RAM=$(free -g | awk 'NR==2 {print $7}')
    log_info "Available RAM: ${AVAILABLE_RAM}GB / ${MAX_RAM_GB}GB total"
    
    if [ "$AVAILABLE_RAM" -lt 20 ]; then
        log_warn "Low available RAM. Consider closing other applications."
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    log_info "Prerequisites check passed ✓"
}

update_kernel_to_latest() {
    log_section "Updating Kernel to Latest Version"
    
    cd "${KERNEL_DIR}"
    
    log_step "Fetching latest kernel updates..."
    git fetch origin "${KERNEL_BRANCH}"
    
    CURRENT_COMMIT=$(git rev-parse HEAD)
    LATEST_COMMIT=$(git rev-parse origin/${KERNEL_BRANCH})
    
    if [ "$CURRENT_COMMIT" = "$LATEST_COMMIT" ]; then
        log_info "Kernel already at latest version ✓"
    else
        log_step "Updating kernel to latest commit..."
        git reset --hard origin/${KERNEL_BRANCH}
        log_info "Kernel updated to latest ${KERNEL_BRANCH} ✓"
    fi
    
    KERNEL_VERSION=$(make kernelversion)
    log_info "Kernel version: ${KERNEL_VERSION}"
}

configure_kernel_for_dsi() {
    log_section "Configuring Kernel for DSI Display"
    
    cd "${KERNEL_DIR}"
    
    log_step "Loading bcm2712 defconfig..."
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- ${KERNEL_DEFCONFIG}
    
    log_step "Enabling DSI and touchscreen drivers..."
    
    # Enable required kernel options for DSI and GT911
    cat >> .config << 'EOF'

# DSI Display Configuration
CONFIG_DRM=y
CONFIG_DRM_KMS_HELPER=y
CONFIG_DRM_PANEL=y
CONFIG_DRM_PANEL_SIMPLE=y
CONFIG_DRM_BRIDGE=y
CONFIG_DRM_MIPI_DSI=y
CONFIG_DRM_VC4=y
CONFIG_DRM_VC4_HDMI_CEC=y

# Broadcom VideoCore
CONFIG_BCM2835_VCHIQ=y
CONFIG_BCM2835_VCHIQ_MMAL=y

# I2C Support
CONFIG_I2C=y
CONFIG_I2C_CHARDEV=y
CONFIG_I2C_BCM2835=y

# Touchscreen - GT911
CONFIG_INPUT_TOUCHSCREEN=y
CONFIG_TOUCHSCREEN_GOODIX=y
CONFIG_TOUCHSCREEN_GOODIX_I2C=y

# GPIO
CONFIG_GPIOLIB=y
CONFIG_GPIO_SYSFS=y
CONFIG_GPIO_BCM2835=y

# Backlight
CONFIG_BACKLIGHT_CLASS_DEVICE=y
CONFIG_BACKLIGHT_GPIO=y
CONFIG_BACKLIGHT_PWM=y

# Framebuffer Console
CONFIG_FRAMEBUFFER_CONSOLE=y
CONFIG_FRAMEBUFFER_CONSOLE_DETECT_PRIMARY=y
CONFIG_LOGO=y

# Device Tree
CONFIG_OF=y
CONFIG_OF_OVERLAY=y
EOF

    log_step "Merging configuration changes..."
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- olddefconfig
    
    log_info "Kernel configured for DSI display and GT911 touch ✓"
}

build_kernel() {
    log_section "Building Raspberry Pi Kernel"
    
    cd "${KERNEL_DIR}"
    
    log_step "Building kernel Image, modules, and device trees..."
    log_info "Using ${BUILD_JOBS} parallel jobs"
    
    make -j${BUILD_JOBS} \
        ARCH=arm64 \
        CROSS_COMPILE=aarch64-linux-gnu- \
        Image modules dtbs
    
    if [ ! -f "arch/arm64/boot/Image" ]; then
        log_error "Kernel build failed!"
        exit 1
    fi
    
    log_info "Kernel built successfully ✓"
    
    KERNEL_SIZE=$(du -h arch/arm64/boot/Image | cut -f1)
    log_info "Kernel size: ${KERNEL_SIZE}"
}

install_kernel_modules() {
    log_section "Installing Kernel Modules"
    
    cd "${KERNEL_DIR}"
    
    MODULES_DIR="${OUTPUT_DIR}/modules"
    mkdir -p "${MODULES_DIR}"
    
    log_step "Installing modules to ${MODULES_DIR}..."
    make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- \
        INSTALL_MOD_PATH="${MODULES_DIR}" modules_install
    
    log_info "Kernel modules installed ✓"
}

setup_device_tree_overlay() {
    log_section "Setting Up DSI Device Tree Overlay"
    
    mkdir -p "${DEVICE_TREE_DIR}"
    cd "${DEVICE_TREE_DIR}"
    
    # Create enhanced device tree overlay for ED-HMI3010-070C
    log_step "Creating device tree overlay for ED-HMI3010-070C..."
    
    cat > ed-hmi3010-070c.dts << 'EOF'
/dts-v1/;
/plugin/;

/ {
    compatible = "brcm,bcm2712";

    fragment@0 {
        target = <&dsi1>;
        __overlay__ {
            status = "okay";
            #address-cells = <1>;
            #size-cells = <0>;
            
            port {
                dsi1_out: endpoint {
                    remote-endpoint = <&panel_dsi_in>;
                };
            };
        };
    };

    fragment@1 {
        target = <&i2c_csi_dsi>;
        __overlay__ {
            #address-cells = <1>;
            #size-cells = <0>;
            status = "okay";

            gt911: touchscreen@5d {
                compatible = "goodix,gt911";
                reg = <0x5d>;
                interrupt-parent = <&gpio>;
                interrupts = <27 2>; /* GPIO27, IRQ_TYPE_EDGE_FALLING */
                irq-gpios = <&gpio 27 0>;
                reset-gpios = <&gpio 22 0>;
                touchscreen-size-x = <1024>;
                touchscreen-size-y = <600>;
                touchscreen-inverted-x;
                touchscreen-inverted-y;
            };
        };
    };

    fragment@2 {
        target-path = "/";
        __overlay__ {
            panel_backlight: backlight {
                compatible = "gpio-backlight";
                gpios = <&gpio 12 0>;
                default-on;
            };
        };
    };

    fragment@3 {
        target = <&dsi1>;
        __overlay__ {
            panel@0 {
                compatible = "simple-panel-dsi";
                reg = <0>;
                backlight = <&panel_backlight>;
                
                dsi-lanes = <2>;
                
                port {
                    panel_dsi_in: endpoint {
                        remote-endpoint = <&dsi1_out>;
                    };
                };
                
                display-timings {
                    native-mode = <&timing0>;
                    timing0: timing0 {
                        clock-frequency = <51200000>;
                        hactive = <1024>;
                        vactive = <600>;
                        hfront-porch = <160>;
                        hback-porch = <160>;
                        hsync-len = <10>;
                        vfront-porch = <12>;
                        vback-porch = <23>;
                        vsync-len = <1>;
                        hsync-active = <0>;
                        vsync-active = <0>;
                        de-active = <1>;
                        pixelclk-active = <1>;
                    };
                };
            };
        };
    };

    __overrides__ {
        rotate = <&gt911>, "touchscreen-swapped-x-y?";
    };
};
EOF

    log_step "Compiling device tree overlay..."
    dtc -@ -I dts -O dtb -o ed-hmi3010-070c.dtbo ed-hmi3010-070c.dts
    
    if [ ! -f "ed-hmi3010-070c.dtbo" ]; then
        log_error "Device tree compilation failed!"
        exit 1
    fi
    
    log_info "Device tree overlay compiled ✓"
}

create_boot_config() {
    log_section "Creating Boot Configuration"
    
    cd "${DEVICE_TREE_DIR}"
    
    log_step "Generating config.txt for DSI display..."
    
    cat > config.txt << 'EOF'
# Raspberry Pi 5 Boot Configuration
# AOSP 15 with ED-HMI3010-070C DSI Display

[pi5]
kernel=kernel8.img
arm_64bit=1

# Memory
gpu_mem=512
total_mem=4096

# CPU Performance
arm_freq=2400
over_voltage=2

# Display - DSI Configuration
dtoverlay=vc4-kms-v3d
dtoverlay=vc4-kms-dsi1
display_auto_detect=0
disable_overscan=1

# Load custom display overlay
dtoverlay=ed-hmi3010-070c

# I2C for touchscreen
dtparam=i2c_arm=on
dtparam=i2c1=on
i2c_arm_baudrate=100000

# SPI (if needed)
dtparam=spi=on

# Enable DSI1 port
dtparam=dsi1=on

# Camera disabled (DSI port used for display)
camera_auto_detect=0
start_x=0

# Audio
dtparam=audio=on

# UART for debugging
enable_uart=1
uart_2ndstage=1

# Disable unused features
disable_splash=1
enable_tvout=0

# Bluetooth (optional - disable to free resources)
# dtoverlay=disable-bt

# Boot delay for display init
boot_delay=1
EOF

    log_info "Boot configuration created ✓"
}

setup_aosp_device_tree() {
    log_section "Setting Up AOSP Device Configuration"
    
    mkdir -p "${DEVICE_DIR}"
    cd "${DEVICE_DIR}"
    
    log_step "Creating Android.mk..."
    cat > Android.mk << 'EOF'
LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),rpi5)
include $(call all-makefiles-under,$(LOCAL_PATH))
endif
EOF

    log_step "Creating AndroidProducts.mk..."
    cat > AndroidProducts.mk << 'EOF'
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/aosp_rpi5.mk

COMMON_LUNCH_CHOICES := \
    aosp_rpi5-userdebug \
    aosp_rpi5-eng
EOF

    log_step "Creating BoardConfig.mk..."
    cat > BoardConfig.mk << 'EOF'
# BoardConfig for Raspberry Pi 5

TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := cortex-a76

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a76

# Kernel
TARGET_NO_KERNEL := false
BOARD_KERNEL_IMAGE_NAME := Image
TARGET_PREBUILT_KERNEL := device/rpi/rpi5/kernel/Image

# Display
TARGET_SCREEN_WIDTH := 1024
TARGET_SCREEN_HEIGHT := 600
TARGET_SCREEN_DENSITY := 160

# Partitions
BOARD_FLASH_BLOCK_SIZE := 4096
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3221225472
BOARD_USERDATAIMAGE_PARTITION_SIZE := 4294967296
BOARD_CACHEIMAGE_PARTITION_SIZE := 268435456

# Graphics
USE_OPENGL_RENDERER := true
TARGET_USES_HWC2 := true
BOARD_GPU_DRIVERS := v3d vc4

# Audio
BOARD_USES_GENERIC_AUDIO := true

# Filesystem
TARGET_USERIMAGES_USE_EXT4 := true
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
EOF

    log_step "Creating aosp_rpi5.mk..."
    cat > aosp_rpi5.mk << 'EOF'
# Product configuration for Raspberry Pi 5

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base.mk)

PRODUCT_NAME := aosp_rpi5
PRODUCT_DEVICE := rpi5
PRODUCT_BRAND := RaspberryPi
PRODUCT_MODEL := Raspberry Pi 5
PRODUCT_MANUFACTURER := RaspberryPi

# Display configuration for ED-HMI3010-070C
PRODUCT_AAPT_CONFIG := normal large xlarge hdpi xhdpi
PRODUCT_AAPT_PREF_CONFIG := hdpi

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=160 \
    ro.opengles.version=196608 \
    debug.sf.disable_backpressure=1 \
    debug.sf.enable_gl_backpressure=1

# Kernel
PRODUCT_COPY_FILES += \
    device/rpi/rpi5/kernel/Image:kernel8.img \
    device/rpi/rpi5/config.txt:config.txt

# Device tree overlays
PRODUCT_COPY_FILES += \
    device/rpi/rpi5/overlays/ed-hmi3010-070c.dtbo:overlays/ed-hmi3010-070c.dtbo

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.screen.landscape.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.screen.landscape.xml \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml

PRODUCT_PACKAGES += \
    libGLES_mesa
EOF

    log_step "Creating device directories..."
    mkdir -p kernel
    mkdir -p overlays
    
    log_info "AOSP device configuration created ✓"
}

copy_kernel_and_dtb() {
    log_section "Copying Kernel and Device Tree Files"
    
    log_step "Copying kernel Image..."
    cp "${KERNEL_DIR}/arch/arm64/boot/Image" "${DEVICE_DIR}/kernel/"
    
    log_step "Copying device tree overlay..."
    cp "${DEVICE_TREE_DIR}/ed-hmi3010-070c.dtbo" "${DEVICE_DIR}/overlays/"
    
    log_step "Copying config.txt..."
    cp "${DEVICE_TREE_DIR}/config.txt" "${DEVICE_DIR}/"
    
    log_info "Kernel and device tree files copied ✓"
}

configure_build_environment() {
    log_section "Configuring Build Environment"
    
    cd "${AOSP_DIR}"
    
    log_step "Setting up build environment variables..."
    
    # Export build optimization variables
    export USE_CCACHE=1
    export CCACHE_DIR="${HOME}/.ccache"
    export CCACHE_EXEC=/usr/bin/ccache
    
    # Jack server settings for 55GB RAM
    export JACK_SERVER_VM_ARGUMENTS="${JACK_SERVER_VM_ARGUMENTS}"
    export ANDROID_JACK_VM_ARGS="${JACK_SERVER_VM_ARGUMENTS}"
    
    # Ninja parallel jobs
    export NINJA_PARALLEL_JOBS=${BUILD_JOBS}
    
    # Prevent OOM
    export JAVA_TOOL_OPTIONS="-Xmx8g"
    
    log_info "Build environment configured:"
    log_info "  - ccache: enabled"
    log_info "  - Build jobs: ${BUILD_JOBS}"
    log_info "  - Jack heap: 20GB"
    log_info "  - Java heap: 8GB"
}

verify_dsi_configuration() {
    log_section "Verifying DSI Configuration"
    
    log_step "Checking kernel configuration..."
    cd "${KERNEL_DIR}"
    
    REQUIRED_CONFIGS=(
        "CONFIG_DRM_VC4"
        "CONFIG_DRM_MIPI_DSI"
        "CONFIG_TOUCHSCREEN_GOODIX"
        "CONFIG_I2C_BCM2835"
    )
    
    for config in "${REQUIRED_CONFIGS[@]}"; do
        if grep -q "^${config}=y" .config; then
            log_info "✓ ${config} enabled"
        else
            log_warn "✗ ${config} not enabled"
        fi
    done
    
    log_step "Checking device tree overlay..."
    if [ -f "${DEVICE_DIR}/overlays/ed-hmi3010-070c.dtbo" ]; then
        log_info "✓ Device tree overlay present"
    else
        log_error "✗ Device tree overlay missing"
        exit 1
    fi
    
    log_step "Checking config.txt..."
    if [ -f "${DEVICE_DIR}/config.txt" ]; then
        if grep -q "dtoverlay=ed-hmi3010-070c" "${DEVICE_DIR}/config.txt"; then
            log_info "✓ DSI overlay configured in config.txt"
        else
            log_warn "✗ DSI overlay not referenced in config.txt"
        fi
    fi
    
    log_info "DSI configuration verified ✓"
}

build_aosp() {
    log_section "Building AOSP 15"
    
    cd "${AOSP_DIR}"
    
    log_step "Sourcing build environment..."
    source build/envsetup.sh
    
    log_step "Selecting lunch target: aosp_rpi5-userdebug"
    lunch aosp_rpi5-userdebug
    
    log_info "Starting AOSP build..."
    log_info "This will take several hours. Using ${BUILD_JOBS} jobs."
    log_warn "Build started at: $(date)"
    
    START_TIME=$(date +%s)
    
    # Build with error handling
    if make -j${BUILD_JOBS} 2>&1 | tee "${OUTPUT_DIR}/build.log"; then
        END_TIME=$(date +%s)
        DURATION=$((END_TIME - START_TIME))
        HOURS=$((DURATION / 3600))
        MINUTES=$(((DURATION % 3600) / 60))
        
        log_info "Build completed successfully! ✓"
        log_info "Build time: ${HOURS}h ${MINUTES}m"
    else
        log_error "Build failed! Check ${OUTPUT_DIR}/build.log for details"
        exit 1
    fi
}

create_output_package() {
    log_section "Creating Output Package"
    
    mkdir -p "${OUTPUT_DIR}/deploy"
    
    log_step "Collecting build artifacts..."
    
    # Copy kernel
    if [ -f "${DEVICE_DIR}/kernel/Image" ]; then
        cp "${DEVICE_DIR}/kernel/Image" "${OUTPUT_DIR}/deploy/kernel8.img"
    fi
    
    # Copy device tree
    if [ -f "${DEVICE_DIR}/overlays/ed-hmi3010-070c.dtbo" ]; then
        mkdir -p "${OUTPUT_DIR}/deploy/overlays"
        cp "${DEVICE_DIR}/overlays/ed-hmi3010-070c.dtbo" "${OUTPUT_DIR}/deploy/overlays/"
    fi
    
    # Copy config
    if [ -f "${DEVICE_DIR}/config.txt" ]; then
        cp "${DEVICE_DIR}/config.txt" "${OUTPUT_DIR}/deploy/"
    fi
    
    # Copy AOSP images if they exist
    if [ -d "${AOSP_DIR}/out/target/product/rpi5" ]; then
        log_step "Copying AOSP system images..."
        cp -r "${AOSP_DIR}/out/target/product/rpi5/"*.img "${OUTPUT_DIR}/deploy/" 2>/dev/null || true
    fi
    
    log_info "Output package created at: ${OUTPUT_DIR}/deploy"
}

show_build_summary() {
    log_section "Build Summary"
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           AOSP 15 Build Complete!                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo "Build Configuration:"
    echo "  • Display: ED-HMI3010-070C (1024x600)"
    echo "  • Interface: DSI with GT911 touch"
    echo "  • Kernel: Latest rpi-6.8.y branch"
    echo "  • Target: Raspberry Pi 5"
    echo ""
    echo "Build Settings:"
    echo "  • Parallel jobs: ${BUILD_JOBS}"
    echo "  • RAM allocated: 55GB optimized"
    echo "  • ccache: enabled"
    echo ""
    echo "Output Location:"
    echo "  ${OUTPUT_DIR}/deploy"
    echo ""
    echo "Files ready for deployment:"
    ls -lh "${OUTPUT_DIR}/deploy" 2>/dev/null || echo "  (No files found)"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Create bootable SD card"
    echo "  2. Copy files from ${OUTPUT_DIR}/deploy to SD card"
    echo "  3. Boot Raspberry Pi 5 with ED-HMI3010-070C display"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    log_section "AOSP 15 Build Script with DSI Configuration"
    echo "Display: ED-HMI3010-070C 7\" TFT (1024x600)"
    echo "Kernel: Latest Raspberry Pi 6.8+"
    echo "RAM: Optimized for 55GB"
    echo ""
    
    log_warn "This script will:"
    log_warn "  • Update kernel to latest version"
    log_warn "  • Configure and build kernel for DSI"
    log_warn "  • Set up device tree for your display"
    log_warn "  • Build complete AOSP 15 system"
    log_warn "  • Take 4-8 hours to complete"
    echo ""
    
    read -p "Start build? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Build cancelled by user"
        exit 0
    fi
    
    # Create output directory
    mkdir -p "${OUTPUT_DIR}"
    
    # Execute build steps
    check_prerequisites
    update_kernel_to_latest
    configure_kernel_for_dsi
    build_kernel
    install_kernel_modules
    setup_device_tree_overlay
    create_boot_config
    setup_aosp_device_tree
    copy_kernel_and_dtb
    configure_build_environment
    verify_dsi_configuration
    build_aosp
    create_output_package
    show_build_summary
    
    log_info "All done! Check ${OUTPUT_DIR}/deploy for output files."
}

# Run main function
main "$@"
