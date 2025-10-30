#!/bin/bash
################################################################################
# AOSP Validation and Setup Script
# Validates existing AOSP installation and configures missing components
# Works with: repo init --partial-clone from android-latest-release
# Location: /root/aosp-rpi5
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
AOSP_DIR="/root/aosp-rpi5"
KERNEL_DIR="/root/aosp-rpi5-kernel"
DEVICE_TREE_DIR="/root/aosp-rpi5-devicetree"
TOOLS_DIR="/root/aosp-rpi5-tools"

# Kernel configuration
KERNEL_VERSION="rpi-6.8.y"

# Build optimization
MAX_RAM_GB=55

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

log_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

log_fix() {
    echo -e "${YELLOW}⚠${NC} $1"
}

################################################################################
# Validation Functions
################################################################################

validate_aosp_installation() {
    log_section "Validating AOSP Installation"
    
    local issues=0
    
    # Check if AOSP directory exists
    if [ ! -d "${AOSP_DIR}" ]; then
        log_error "AOSP directory not found: ${AOSP_DIR}"
        log_error "Expected location: /root/aosp-rpi5"
        exit 1
    fi
    log_ok "AOSP directory exists: ${AOSP_DIR}"
    
    # Check if .repo exists
    if [ ! -d "${AOSP_DIR}/.repo" ]; then
        log_error ".repo directory not found in ${AOSP_DIR}"
        log_error "This doesn't appear to be a valid AOSP repository"
        exit 1
    fi
    log_ok ".repo directory found"
    
    # Check repo manifest
    if [ -f "${AOSP_DIR}/.repo/manifest.xml" ]; then
        log_ok "Repository manifest found"
        
        # Show current branch/version
        cd "${AOSP_DIR}"
        REPO_BRANCH=$(repo info -o 2>/dev/null | grep "Manifest branch:" | cut -d: -f2 | xargs || echo "unknown")
        log_info "Current branch: ${REPO_BRANCH}"
    else
        log_warn "Manifest file not found"
        issues=$((issues + 1))
    fi
    
    # Check if source code is downloaded
    CRITICAL_DIRS=("build" "frameworks" "system" "device")
    for dir in "${CRITICAL_DIRS[@]}"; do
        if [ -d "${AOSP_DIR}/${dir}" ]; then
            log_ok "Core directory found: ${dir}/"
        else
            log_fix "Missing core directory: ${dir}/"
            issues=$((issues + 1))
        fi
    done
    
    # Check disk usage
    if [ -d "${AOSP_DIR}" ]; then
        AOSP_SIZE=$(du -sh "${AOSP_DIR}" 2>/dev/null | cut -f1)
        log_info "AOSP directory size: ${AOSP_SIZE}"
        
        # If size is too small, source might not be fully synced
        AOSP_SIZE_GB=$(du -sb "${AOSP_DIR}" 2>/dev/null | awk '{print int($1/1024/1024/1024)}')
        if [ "${AOSP_SIZE_GB}" -lt 50 ]; then
            log_warn "AOSP directory is only ${AOSP_SIZE_GB}GB - may not be fully synced"
            log_warn "Expected size: 200-350GB for full AOSP source"
            issues=$((issues + 1))
        fi
    fi
    
    return $issues
}

sync_aosp_source() {
    log_section "Syncing AOSP Source Code"
    
    cd "${AOSP_DIR}"
    
    log_step "Checking for incomplete sync..."
    
    # Check if sync is needed
    if repo status 2>&1 | grep -q "error:\|fatal:"; then
        log_warn "Repository has errors, attempting to fix..."
    fi
    
    log_step "Syncing AOSP repository (this may take a while)..."
    log_info "Using $(nproc) parallel jobs"
    
    # Sync with recovery options
    if repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags 2>&1 | tee /tmp/repo-sync.log; then
        log_ok "AOSP source synced successfully"
    else
        log_warn "Sync completed with some warnings (this is often normal)"
        log_info "Check /tmp/repo-sync.log for details"
    fi
}

check_system_dependencies() {
    log_section "Checking System Dependencies"
    
    local missing_packages=()
    
    # Essential packages for AOSP build
    REQUIRED_PACKAGES=(
        "git"
        "curl"
        "build-essential"
        "python3"
        "python-is-python3"
        "openjdk-17-jdk"
        "ccache"
        "device-tree-compiler"
        "gcc-aarch64-linux-gnu"
        "g++-aarch64-linux-gnu"
    )
    
    log_step "Checking for required packages..."
    
    for package in "${REQUIRED_PACKAGES[@]}"; do
        if dpkg -l | grep -q "^ii  ${package}"; then
            log_ok "${package}"
        else
            log_fix "Missing: ${package}"
            missing_packages+=("${package}")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        log_warn "Found ${#missing_packages[@]} missing packages"
        return 1
    else
        log_ok "All required packages installed"
        return 0
    fi
}

install_missing_dependencies() {
    log_section "Installing Missing Dependencies"
    
    log_step "Updating package lists..."
    apt-get update
    
    log_step "Installing AOSP build dependencies..."
    apt-get install -y \
        git-core gnupg flex bison build-essential zip curl zlib1g-dev \
        libc6-dev-i386 x11proto-core-dev libx11-dev lib32z1-dev \
        libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig \
        python3 python3-pip python3-dev python-is-python3 \
        bc cpio rsync kmod libssl-dev
    
    log_step "Installing kernel and cross-compilation tools..."
    apt-get install -y \
        gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
        gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
        device-tree-compiler u-boot-tools \
        libelf-dev dwarves debhelper pahole
    
    log_step "Installing build tools..."
    apt-get install -y \
        git git-lfs ccache \
        vim nano wget curl \
        openjdk-17-jdk \
        libncurses6 libncurses-dev
    
    log_step "Cleaning up..."
    apt-get autoremove -y
    apt-get clean
    
    log_ok "All dependencies installed"
}

setup_git_config() {
    log_section "Configuring Git"
    
    if [ -z "$(git config --global user.name)" ]; then
        log_step "Setting up git configuration..."
        git config --global user.name "AOSP Builder"
        git config --global user.email "builder@localhost"
        log_info "Set default git config (you can change this later)"
    else
        log_ok "Git already configured:"
        log_info "  Name: $(git config --global user.name)"
        log_info "  Email: $(git config --global user.email)"
    fi
    
    # Optimize git for large repositories
    git config --global color.ui true
    git config --global core.compression 0
    git config --global http.postBuffer 1048576000
    git config --global pack.threads $(nproc)
    
    log_ok "Git configuration complete"
}

setup_ccache() {
    log_section "Setting Up ccache"
    
    # Set ccache size to 100GB
    ccache -M 100G
    
    # Configure environment
    if ! grep -q "USE_CCACHE" /root/.bashrc; then
        cat >> /root/.bashrc << 'EOF'

# AOSP ccache configuration
export USE_CCACHE=1
export CCACHE_DIR=/root/.ccache
export CCACHE_EXEC=/usr/bin/ccache
EOF
        log_ok "ccache environment configured in .bashrc"
    else
        log_ok "ccache already configured"
    fi
    
    export USE_CCACHE=1
    export CCACHE_DIR=/root/.ccache
    export CCACHE_EXEC=/usr/bin/ccache
    
    log_ok "ccache configured with 100GB cache"
}

download_rpi_kernel() {
    log_section "Setting Up Raspberry Pi Kernel"
    
    if [ -d "${KERNEL_DIR}/linux" ]; then
        log_step "Kernel source found, updating..."
        cd "${KERNEL_DIR}/linux"
        git fetch origin "${KERNEL_VERSION}"
        git checkout "${KERNEL_VERSION}"
        git pull origin "${KERNEL_VERSION}"
        log_ok "Kernel updated to latest ${KERNEL_VERSION}"
    else
        log_step "Downloading Raspberry Pi kernel ${KERNEL_VERSION}..."
        mkdir -p "${KERNEL_DIR}"
        cd "${KERNEL_DIR}"
        git clone --depth=1 --branch "${KERNEL_VERSION}" \
            https://github.com/raspberrypi/linux.git
        log_ok "Kernel downloaded"
    fi
    
    KERNEL_VER=$(cd "${KERNEL_DIR}/linux" && make kernelversion)
    log_info "Kernel version: ${KERNEL_VER}"
}

create_device_configuration() {
    log_section "Creating Raspberry Pi 5 Device Configuration"
    
    local DEVICE_DIR="${AOSP_DIR}/device/rpi/rpi5"
    
    mkdir -p "${DEVICE_DIR}"
    cd "${DEVICE_DIR}"
    
    # Check if configuration already exists
    if [ -f "aosp_rpi5.mk" ] && [ -f "BoardConfig.mk" ]; then
        log_ok "Device configuration already exists"
        return 0
    fi
    
    log_step "Creating device configuration files..."
    
    # Create Android.mk
    cat > Android.mk << 'EOF'
LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),rpi5)
include $(call all-makefiles-under,$(LOCAL_PATH))
endif
EOF

    # Create AndroidProducts.mk
    cat > AndroidProducts.mk << 'EOF'
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/aosp_rpi5.mk

COMMON_LUNCH_CHOICES := \
    aosp_rpi5-userdebug \
    aosp_rpi5-eng
EOF

    # Create BoardConfig.mk
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

# Display - ED-HMI3010-070C
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

    # Create aosp_rpi5.mk
    cat > aosp_rpi5.mk << 'EOF'
# Product configuration for Raspberry Pi 5
# ED-HMI3010-070C Display (1024x600)

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
    debug.sf.disable_backpressure=1

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
    frameworks/native/data/etc/android.hardware.screen.landscape.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.screen.landscape.xml
EOF

    mkdir -p kernel overlays
    
    log_ok "Device configuration created"
}

create_display_device_tree() {
    log_section "Creating DSI Display Device Tree"
    
    mkdir -p "${DEVICE_TREE_DIR}"
    cd "${DEVICE_TREE_DIR}"
    
    if [ -f "ed-hmi3010-070c.dtbo" ]; then
        log_ok "Device tree overlay already exists"
        return 0
    fi
    
    log_step "Creating device tree source for ED-HMI3010-070C..."
    
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
                interrupts = <27 2>;
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
            #address-cells = <1>;
            #size-cells = <0>;
            
            panel@0 {
                compatible = "simple-panel-dsi";
                reg = <0>;
                backlight = <&panel_backlight>;
                dsi-lanes = <2>;
                
                display-timings {
                    timing0 {
                        clock-frequency = <51200000>;
                        hactive = <1024>;
                        vactive = <600>;
                        hfront-porch = <160>;
                        hback-porch = <160>;
                        hsync-len = <10>;
                        vfront-porch = <12>;
                        vback-porch = <23>;
                        vsync-len = <1>;
                    };
                };
            };
        };
    };
};
EOF

    log_step "Compiling device tree overlay..."
    dtc -@ -I dts -O dtb -o ed-hmi3010-070c.dtbo ed-hmi3010-070c.dts
    
    if [ -f "ed-hmi3010-070c.dtbo" ]; then
        log_ok "Device tree overlay compiled"
    else
        log_error "Failed to compile device tree"
        return 1
    fi
    
    # Copy to device directory
    cp ed-hmi3010-070c.dtbo "${AOSP_DIR}/device/rpi/rpi5/overlays/"
    log_ok "Device tree overlay copied to device directory"
}

create_boot_config() {
    log_section "Creating Boot Configuration"
    
    local CONFIG_FILE="${AOSP_DIR}/device/rpi/rpi5/config.txt"
    
    if [ -f "${CONFIG_FILE}" ]; then
        log_ok "config.txt already exists"
        return 0
    fi
    
    log_step "Creating config.txt for DSI display..."
    
    cat > "${CONFIG_FILE}" << 'EOF'
# Raspberry Pi 5 Boot Configuration
# AOSP with ED-HMI3010-070C DSI Display

[pi5]
kernel=kernel8.img
arm_64bit=1

# Memory
gpu_mem=512

# CPU Performance
arm_freq=2400
over_voltage=2

# Display - DSI Configuration
dtoverlay=vc4-kms-v3d
dtoverlay=vc4-kms-dsi1
display_auto_detect=0
disable_overscan=1

# Custom display overlay
dtoverlay=ed-hmi3010-070c

# I2C for touchscreen
dtparam=i2c_arm=on
dtparam=i2c1=on

# Enable DSI1
dtparam=dsi1=on

# Camera disabled
camera_auto_detect=0

# Audio
dtparam=audio=on

# UART
enable_uart=1
EOF

    log_ok "config.txt created"
}

create_validation_report() {
    log_section "Creating Validation Report"
    
    local REPORT_FILE="/root/aosp-validation-report.txt"
    
    cat > "${REPORT_FILE}" << EOF
================================================================================
AOSP Installation Validation Report
Generated: $(date)
================================================================================

AOSP INSTALLATION:
  Location: ${AOSP_DIR}
  Size: $(du -sh "${AOSP_DIR}" 2>/dev/null | cut -f1)
  Branch: $(cd "${AOSP_DIR}" && repo info -o 2>/dev/null | grep "Manifest branch:" | cut -d: -f2 | xargs || echo "unknown")

KERNEL:
  Location: ${KERNEL_DIR}/linux
  Version: $(cd "${KERNEL_DIR}/linux" 2>/dev/null && make kernelversion || echo "not built")
  Branch: ${KERNEL_VERSION}

DEVICE CONFIGURATION:
  Target: Raspberry Pi 5
  Display: ED-HMI3010-070C (1024x600)
  Interface: DSI with GT911 touch
  Device files: ${AOSP_DIR}/device/rpi/rpi5/

BUILD ENVIRONMENT:
  ccache: $(ccache -s 2>/dev/null | grep "cache size" || echo "configured")
  Java: $(java -version 2>&1 | head -n1)
  Python: $(python --version)
  Git: $(git --version)

SYSTEM RESOURCES:
  RAM: $(free -h | awk 'NR==2 {print $2}')
  Available: $(free -h | awk 'NR==2 {print $7}')
  Disk: $(df -h "${AOSP_DIR}" | awk 'NR==2 {print $4}') available

STATUS: Ready for build
  
NEXT STEPS:
1. Build kernel:
   cd ${KERNEL_DIR}/linux
   make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2712_defconfig
   make -j\$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs

2. Build AOSP:
   cd ${AOSP_DIR}
   source build/envsetup.sh
   lunch aosp_rpi5-userdebug
   make -j\$(nproc)

================================================================================
EOF

    log_ok "Validation report created: ${REPORT_FILE}"
    
    # Display report
    cat "${REPORT_FILE}"
}

################################################################################
# Main Execution
################################################################################

main() {
    log_section "AOSP Validation and Setup Script"
    echo "Working directory: ${AOSP_DIR}"
    echo "Target: Raspberry Pi 5 with ED-HMI3010-070C display"
    echo ""
    
    # Validate existing installation
    if validate_aosp_installation; then
        log_ok "AOSP installation validated"
    else
        log_warn "AOSP installation has issues, will attempt to fix"
        
        # Sync AOSP if needed
        read -p "Sync AOSP source code? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            sync_aosp_source
        fi
    fi
    
    # Check and install dependencies
    if ! check_system_dependencies; then
        read -p "Install missing dependencies? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            install_missing_dependencies
        fi
    fi
    
    # Setup build environment
    setup_git_config
    setup_ccache
    
    # Download/update kernel
    download_rpi_kernel
    
    # Create device configuration
    create_device_configuration
    create_display_device_tree
    create_boot_config
    
    # Generate validation report
    create_validation_report
    
    log_section "Setup Complete!"
    echo -e "${GREEN}✓ AOSP installation validated and configured${NC}"
    echo -e "${GREEN}✓ Raspberry Pi kernel ready${NC}"
    echo -e "${GREEN}✓ Device configuration created${NC}"
    echo -e "${GREEN}✓ DSI display configured${NC}"
    echo ""
    echo "Check the validation report: /root/aosp-validation-report.txt"
    echo ""
    echo "Ready to build! Run: ./build-aosp-with-dsi.sh"
}

# Run main function
main "$@"
