#!/bin/bash
################################################################################
# AOSP 15 Raspberry Pi 5 - Automated Setup Script
# Target: Ubuntu Server 24.04 LTS
# Display: ED-HMI3010-070C 7" TFT (1024x600) via DSI with GT911 touch
# Kernel: Raspberry Pi 5 kernel 6.8+
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
AOSP_VERSION="android-15.0.0_r1"
KERNEL_VERSION="rpi-6.8.y"
WORKSPACE_DIR="${HOME}/aosp-rpi5"
AOSP_DIR="${WORKSPACE_DIR}/aosp"
KERNEL_DIR="${WORKSPACE_DIR}/kernel"
DEVICE_TREE_DIR="${WORKSPACE_DIR}/device-tree"
TOOLS_DIR="${WORKSPACE_DIR}/tools"

# System requirements
MIN_DISK_SPACE_GB=400
MIN_RAM_GB=16

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

check_system_requirements() {
    log_section "Checking System Requirements"
    
    # Check Ubuntu version
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$VERSION_ID" != "24.04" ]]; then
            log_warn "This script is optimized for Ubuntu 24.04 LTS. You have version $VERSION_ID"
            read -p "Continue anyway? (y/n) " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        else
            log_info "Ubuntu 24.04 LTS detected ✓"
        fi
    fi
    
    # Check available disk space
    AVAILABLE_SPACE=$(df -BG "${HOME}" | awk 'NR==2 {print $4}' | sed 's/G//')
    log_info "Available disk space: ${AVAILABLE_SPACE}GB"
    if [ "$AVAILABLE_SPACE" -lt "$MIN_DISK_SPACE_GB" ]; then
        log_error "Insufficient disk space. Need at least ${MIN_DISK_SPACE_GB}GB, have ${AVAILABLE_SPACE}GB"
        exit 1
    fi
    
    # Check RAM
    TOTAL_RAM=$(free -g | awk 'NR==2 {print $2}')
    log_info "Total RAM: ${TOTAL_RAM}GB"
    if [ "$TOTAL_RAM" -lt "$MIN_RAM_GB" ]; then
        log_warn "Recommended RAM is ${MIN_RAM_GB}GB, you have ${TOTAL_RAM}GB. Build may be slow."
    fi
    
    log_info "System requirements check complete ✓"
}

install_dependencies() {
    log_section "Installing System Dependencies"
    
    log_info "Updating package lists..."
    sudo apt-get update
    
    log_info "Upgrading existing packages..."
    sudo apt-get upgrade -y
    
    log_info "Installing AOSP build dependencies..."
    sudo apt-get install -y \
        git-core gnupg flex bison build-essential zip curl zlib1g-dev \
        libc6-dev-i386 x11proto-core-dev libx11-dev lib32z1-dev \
        libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig \
        python3 python3-pip python3-dev python-is-python3 \
        bc cpio rsync kmod libssl-dev
    
    log_info "Installing additional build tools..."
    sudo apt-get install -y \
        gcc-aarch64-linux-gnu g++-aarch64-linux-gnu \
        gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
        device-tree-compiler u-boot-tools
    
    log_info "Installing version control and utilities..."
    sudo apt-get install -y \
        git git-lfs repo ccache \
        vim nano wget curl \
        openjdk-11-jdk \
        libncurses5 libncurses5-dev
    
    log_info "Installing kernel build dependencies..."
    sudo apt-get install -y \
        libelf-dev dwarves debhelper \
        pahole
    
    log_info "Cleaning up package cache..."
    sudo apt-get autoremove -y
    sudo apt-get clean
    
    log_info "All dependencies installed successfully ✓"
}

setup_git_config() {
    log_section "Configuring Git"
    
    # Check if git config exists
    if [ -z "$(git config --global user.name)" ]; then
        log_info "Setting up git configuration..."
        read -p "Enter your Git name: " GIT_NAME
        read -p "Enter your Git email: " GIT_EMAIL
        git config --global user.name "$GIT_NAME"
        git config --global user.email "$GIT_EMAIL"
    else
        log_info "Git already configured:"
        log_info "  Name: $(git config --global user.name)"
        log_info "  Email: $(git config --global user.email)"
    fi
    
    # Configure git for large repositories
    git config --global color.ui true
    git config --global core.compression 0
    git config --global http.postBuffer 1048576000
    
    log_info "Git configuration complete ✓"
}

setup_ccache() {
    log_section "Setting up ccache"
    
    # Set ccache size to 100GB
    ccache -M 100G
    
    # Add ccache to bashrc if not already present
    if ! grep -q "USE_CCACHE" "${HOME}/.bashrc"; then
        echo "" >> "${HOME}/.bashrc"
        echo "# AOSP ccache configuration" >> "${HOME}/.bashrc"
        echo "export USE_CCACHE=1" >> "${HOME}/.bashrc"
        echo "export CCACHE_DIR=${HOME}/.ccache" >> "${HOME}/.bashrc"
        echo "export CCACHE_EXEC=/usr/bin/ccache" >> "${HOME}/.bashrc"
    fi
    
    export USE_CCACHE=1
    export CCACHE_DIR="${HOME}/.ccache"
    export CCACHE_EXEC=/usr/bin/ccache
    
    log_info "ccache configured with 100GB cache ✓"
}

create_workspace() {
    log_section "Creating Workspace Directories"
    
    mkdir -p "${WORKSPACE_DIR}"
    mkdir -p "${AOSP_DIR}"
    mkdir -p "${KERNEL_DIR}"
    mkdir -p "${DEVICE_TREE_DIR}"
    mkdir -p "${TOOLS_DIR}"
    
    log_info "Workspace created at: ${WORKSPACE_DIR}"
    log_info "  - AOSP: ${AOSP_DIR}"
    log_info "  - Kernel: ${KERNEL_DIR}"
    log_info "  - Device Tree: ${DEVICE_TREE_DIR}"
    log_info "  - Tools: ${TOOLS_DIR}"
}

install_repo_tool() {
    log_section "Installing Repo Tool"
    
    if command -v repo &> /dev/null; then
        log_info "Repo tool already installed ✓"
        return
    fi
    
    log_info "Downloading and installing repo..."
    sudo curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo
    sudo chmod a+x /usr/local/bin/repo
    
    log_info "Repo tool installed ✓"
}

download_aosp() {
    log_section "Downloading AOSP Source Code"
    
    cd "${AOSP_DIR}"
    
    if [ -d ".repo" ]; then
        log_warn "AOSP repository already initialized. Syncing..."
        repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags
    else
        log_info "Initializing AOSP repository for ${AOSP_VERSION}..."
        repo init -u https://android.googlesource.com/platform/manifest -b ${AOSP_VERSION} --depth=1
        
        log_info "Downloading AOSP source code (this will take a while)..."
        log_info "Using $(nproc) parallel jobs..."
        repo sync -c -j$(nproc) --force-sync --no-clone-bundle --no-tags
    fi
    
    log_info "AOSP source code ready ✓"
}

download_rpi_kernel() {
    log_section "Downloading Raspberry Pi Kernel"
    
    cd "${KERNEL_DIR}"
    
    if [ -d "linux" ]; then
        log_warn "Kernel source already exists. Updating..."
        cd linux
        git fetch origin "${KERNEL_VERSION}"
        git checkout "${KERNEL_VERSION}"
        git pull origin "${KERNEL_VERSION}"
    else
        log_info "Cloning Raspberry Pi kernel ${KERNEL_VERSION}..."
        git clone --depth=1 --branch "${KERNEL_VERSION}" \
            https://github.com/raspberrypi/linux.git
        cd linux
    fi
    
    log_info "Raspberry Pi kernel source ready ✓"
}

create_display_device_tree() {
    log_section "Creating Device Tree for ED-HMI3010-070C Display"
    
    cd "${DEVICE_TREE_DIR}"
    
    log_info "Creating DSI display device tree overlay..."
    
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
                dsi_out: endpoint {
                    remote-endpoint = <&panel_in>;
                };
            };
        };
    };

    fragment@1 {
        target-path = "/";
        __overlay__ {
            panel: panel@0 {
                compatible = "simple-panel";
                reg = <0>;
                backlight = <&backlight>;
                
                port {
                    panel_in: endpoint {
                        remote-endpoint = <&dsi_out>;
                    };
                };

                display-timings {
                    timing0: timing0 {
                        clock-frequency = <51200000>;
                        hactive = <1024>;
                        vactive = <600>;
                        hfront-porch = <160>;
                        hsync-len = <10>;
                        hback-porch = <160>;
                        vfront-porch = <12>;
                        vsync-len = <1>;
                        vback-porch = <23>;
                        hsync-active = <0>;
                        vsync-active = <0>;
                        de-active = <1>;
                        pixelclk-active = <1>;
                    };
                };
            };

            backlight: backlight {
                compatible = "gpio-backlight";
                gpios = <&gpio 12 0>;
                default-on;
            };
        };
    };

    fragment@2 {
        target = <&i2c_csi_dsi>;
        __overlay__ {
            #address-cells = <1>;
            #size-cells = <0>;
            status = "okay";

            gt911: touchscreen@5d {
                compatible = "goodix,gt911";
                reg = <0x5d>;
                interrupt-parent = <&gpio>;
                interrupts = <27 2>; /* GPIO27, falling edge */
                irq-gpios = <&gpio 27 0>;
                reset-gpios = <&gpio 22 0>;
                touchscreen-inverted-x;
                touchscreen-inverted-y;
                touchscreen-size-x = <1024>;
                touchscreen-size-y = <600>;
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
                
                dsi-lanes = <2>;
                video-mode = <2>; /* MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_VIDEO_SYNC_PULSE */
                
                panel-timing {
                    clock-frequency = <51200000>;
                    hactive = <1024>;
                    vactive = <600>;
                    hfront-porch = <160>;
                    hsync-len = <10>;
                    hback-porch = <160>;
                    vfront-porch = <12>;
                    vsync-len = <1>;
                    vback-porch = <23>;
                };
            };
        };
    };

    __overrides__ {
        rotate = <&panel>, "rotation:0";
        touchscreen-inverted-x = <&gt911>, "touchscreen-inverted-x?";
        touchscreen-inverted-y = <&gt911>, "touchscreen-inverted-y?";
        touchscreen-swapped-x-y = <&gt911>, "touchscreen-swapped-x-y?";
    };
};
EOF

    log_info "Device tree source created: ed-hmi3010-070c.dts ✓"
}

compile_device_tree() {
    log_section "Compiling Device Tree Overlay"
    
    cd "${DEVICE_TREE_DIR}"
    
    log_info "Compiling device tree overlay..."
    dtc -@ -I dts -O dtb -o ed-hmi3010-070c.dtbo ed-hmi3010-070c.dts
    
    if [ -f "ed-hmi3010-070c.dtbo" ]; then
        log_info "Device tree overlay compiled successfully ✓"
    else
        log_error "Failed to compile device tree overlay"
        exit 1
    fi
}

create_config_txt() {
    log_section "Creating config.txt for Raspberry Pi"
    
    cd "${DEVICE_TREE_DIR}"
    
    log_info "Creating config.txt with display and touch configuration..."
    
    cat > config.txt << 'EOF'
# Raspberry Pi 5 Configuration for ED-HMI3010-070C Display
# AOSP 15 Build

[pi5]
kernel=kernel_2712.img
arm_64bit=1

# GPU Memory
gpu_mem=256

# Display Configuration
dtoverlay=vc4-kms-v3d
dtoverlay=vc4-kms-dsi-generic
dtoverlay=ed-hmi3010-070c

# DSI Display Settings
display_auto_detect=0
ignore_lcd=0

# Disable composite video
enable_tvout=0

# I2C for touchscreen
dtparam=i2c_arm=on
dtparam=i2c1=on

# Enable DSI1
dtparam=dsi1=on

# Touchscreen overlay
dtoverlay=goodix,interrupt=27,reset=22

# Camera disabled (DSI used for display)
camera_auto_detect=0

# Performance
over_voltage=2
arm_freq=2400

# Audio
dtparam=audio=on

# Enable UART for debugging (optional)
enable_uart=1

# Disable Bluetooth to free up UART (optional)
# dtoverlay=disable-bt
EOF

    log_info "config.txt created ✓"
}

create_rpi_device_config() {
    log_section "Creating Raspberry Pi Device Configuration"
    
    cd "${WORKSPACE_DIR}"
    
    log_info "Creating device configuration makefile..."
    
    mkdir -p device/rpi/rpi5
    
    cat > device/rpi/rpi5/device.mk << 'EOF'
# Raspberry Pi 5 Device Configuration for AOSP 15
# ED-HMI3010-070C Display (1024x600)

PRODUCT_NAME := aosp_rpi5
PRODUCT_DEVICE := rpi5
PRODUCT_BRAND := RaspberryPi
PRODUCT_MODEL := Raspberry Pi 5
PRODUCT_MANUFACTURER := RaspberryPi

# Display Configuration
PRODUCT_AAPT_CONFIG := normal large xlarge hdpi xhdpi
PRODUCT_AAPT_PREF_CONFIG := hdpi

# Display density for 7" 1024x600 display
PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=160

# Display resolution
PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.hwrotation=0

# Kernel
PRODUCT_COPY_FILES += \
    device/rpi/rpi5/kernel/Image:kernel \
    device/rpi/rpi5/config.txt:config.txt \
    device/rpi/rpi5/dtbo/ed-hmi3010-070c.dtbo:overlays/ed-hmi3010-070c.dtbo

# Touchscreen
PRODUCT_PACKAGES += \
    android.hardware.touchscreen@1.0-impl

# Graphics
PRODUCT_PACKAGES += \
    libGLES_mesa \
    gralloc.rpi5 \
    hwcomposer.rpi5

# Audio
PRODUCT_PACKAGES += \
    audio.primary.rpi5 \
    audio.usb.default

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.screen.landscape.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.screen.landscape.xml

$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)
EOF

    log_info "Device configuration created ✓"
}

create_build_instructions() {
    log_section "Creating Build Instructions"
    
    cd "${WORKSPACE_DIR}"
    
    cat > BUILD_INSTRUCTIONS.txt << EOF
================================================================================
AOSP 15 for Raspberry Pi 5 - Build Instructions
ED-HMI3010-070C Display (1024x600) with GT911 Touch
================================================================================

AUTOMATIC SETUP COMPLETE!

The following has been set up:
✓ Ubuntu 24.04 LTS updated with all dependencies
✓ AOSP 15 source code downloaded
✓ Raspberry Pi kernel ${KERNEL_VERSION} downloaded
✓ Device tree for ED-HMI3010-070C display created and compiled
✓ config.txt configured for DSI and touch support
✓ ccache configured (100GB)

NEXT STEPS TO BUILD AOSP:
================================================================================

1. Build the Raspberry Pi Kernel:
   cd ${KERNEL_DIR}/linux
   make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2712_defconfig
   make -j\$(nproc) ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs

2. Build AOSP:
   cd ${AOSP_DIR}
   source build/envsetup.sh
   lunch aosp_arm64-userdebug
   make -j\$(nproc)

3. Create SD Card Image:
   - Follow AOSP documentation to create bootable image
   - Copy kernel, device tree overlays, and config.txt to boot partition
   - Copy compiled device tree overlay from: ${DEVICE_TREE_DIR}/ed-hmi3010-070c.dtbo

IMPORTANT FILES:
================================================================================
- Device Tree Overlay: ${DEVICE_TREE_DIR}/ed-hmi3010-070c.dtbo
- Config.txt: ${DEVICE_TREE_DIR}/config.txt
- Kernel Source: ${KERNEL_DIR}/linux
- AOSP Source: ${AOSP_DIR}

DISPLAY CONFIGURATION:
================================================================================
- Display: ED-HMI3010-070C 7" TFT
- Resolution: 1024x600
- Interface: DSI
- Touch: GT911 (I2C)
- Touch GPIO: Interrupt=27, Reset=22

TROUBLESHOOTING:
================================================================================
If display doesn't work:
1. Check that ed-hmi3010-070c.dtbo is in the overlays folder on boot partition
2. Verify config.txt includes: dtoverlay=ed-hmi3010-070c
3. Check kernel logs: dmesg | grep -i dsi
4. Verify touch: dmesg | grep -i gt911

For more help, refer to AOSP and Raspberry Pi documentation.
================================================================================

Setup completed: $(date)
Workspace: ${WORKSPACE_DIR}

Happy building!
EOF

    log_info "Build instructions created: ${WORKSPACE_DIR}/BUILD_INSTRUCTIONS.txt"
}

show_summary() {
    log_section "Setup Complete!"
    
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║         AOSP 15 Raspberry Pi 5 Setup Complete!              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo "Workspace Location: ${WORKSPACE_DIR}"
    echo ""
    echo "What was installed:"
    echo "  ✓ All Ubuntu 24.04 LTS dependencies updated"
    echo "  ✓ AOSP ${AOSP_VERSION} source code"
    echo "  ✓ Raspberry Pi kernel ${KERNEL_VERSION}"
    echo "  ✓ Device tree for ED-HMI3010-070C display"
    echo "  ✓ GT911 touchscreen configuration"
    echo "  ✓ Build tools and ccache"
    echo ""
    echo "Display Configuration:"
    echo "  • Model: ED-HMI3010-070C"
    echo "  • Resolution: 1024x600"
    echo "  • Interface: DSI"
    echo "  • Touch: GT911 via I2C"
    echo ""
    echo "Next steps:"
    echo "  1. Read: ${WORKSPACE_DIR}/BUILD_INSTRUCTIONS.txt"
    echo "  2. Build kernel from: ${KERNEL_DIR}/linux"
    echo "  3. Build AOSP from: ${AOSP_DIR}"
    echo ""
    echo -e "${YELLOW}Estimated disk usage: ~350GB${NC}"
    echo -e "${YELLOW}Estimated total build time: 4-8 hours (depending on hardware)${NC}"
    echo ""
}

################################################################################
# Main Execution
################################################################################

main() {
    log_section "AOSP 15 Raspberry Pi 5 Automated Setup"
    echo "Target: Ubuntu Server 24.04 LTS"
    echo "Display: ED-HMI3010-070C 7\" TFT (1024x600)"
    echo "Kernel: Raspberry Pi ${KERNEL_VERSION}"
    echo ""
    
    log_warn "This script will:"
    log_warn "  • Update your system packages"
    log_warn "  • Install ~4GB of build dependencies"
    log_warn "  • Download ~350GB of source code"
    log_warn "  • Take several hours to complete"
    echo ""
    
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Setup cancelled by user"
        exit 0
    fi
    
    # Run setup steps
    check_system_requirements
    install_dependencies
    setup_git_config
    setup_ccache
    create_workspace
    install_repo_tool
    download_aosp
    download_rpi_kernel
    create_display_device_tree
    compile_device_tree
    create_config_txt
    create_rpi_device_config
    create_build_instructions
    show_summary
    
    log_info "All done! Check BUILD_INSTRUCTIONS.txt for next steps."
}

# Run main function
main "$@"
