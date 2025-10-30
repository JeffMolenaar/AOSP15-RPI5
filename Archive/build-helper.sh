#!/bin/bash
# AOSP Build Helper Script for Raspberry Pi 5
# This script simplifies the AOSP build process

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
AOSP_DIR="${HOME}/aosp-rpi5"
BUILD_TARGET="aosp_rpi5-bp1a-userdebug"
JOBS=$(nproc)

# Repository and trace directory to store build artifacts for reproducibility
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_BUILD_DIR="${REPO_DIR}/script-folder/build"

mkdir -p "${SCRIPT_BUILD_DIR}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}AOSP Build Helper for Raspberry Pi 5${NC}"
echo -e "${BLUE}========================================${NC}"

# Parse command line arguments
ACTION="${1:-build}"

# Help doesn't require AOSP directory
if [ "$ACTION" = "help" ] || [ "$ACTION" = "--help" ] || [ "$ACTION" = "-h" ]; then
    echo -e "\nUsage: $0 [action] [options]"
    echo -e "\nActions:"
    echo -e "  build         - Build complete AOSP (default)"
    echo -e "  clean         - Clean build output"
    echo -e "  clobber       - Remove all build output"
    echo -e "  kernel        - Build kernel only"
    echo -e "  sync          - Sync source code"
    echo -e "  info          - Show build information"
    echo -e "  flash DEVICE  - Flash image to SD card (e.g., flash /dev/sdc)"
    echo -e "  help          - Show this help"
    echo -e "\nExamples:"
    echo -e "  $0 build              # Full build"
    echo -e "  $0 kernel             # Build kernel only"
    echo -e "  $0 flash /dev/sdc     # Flash to SD card"
    echo -e "  $0 sync && $0 build   # Update and build"
    echo -e ""
    exit 0
fi

# Check if AOSP directory exists
if [ ! -d "$AOSP_DIR" ]; then
    echo -e "${RED}Error: AOSP directory not found at $AOSP_DIR${NC}"
    echo -e "${YELLOW}Please run setup-aosp.sh first or specify AOSP_DIR${NC}"
    exit 1
fi

# Check if setup is complete
if [ ! -f "$AOSP_DIR/.aosp_setup_complete" ]; then
    echo -e "${YELLOW}Warning: AOSP setup may not be complete${NC}"
    read -p "Continue anyway? (y/N): " CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        exit 1
    fi
fi

cd "$AOSP_DIR"

# Parse command line arguments (already set above for help)
# ACTION="${1:-build}"

case "$ACTION" in
    build)
        echo -e "\n${YELLOW}Starting AOSP build...${NC}"
        echo -e "Target: ${BUILD_TARGET}"
        echo -e "Jobs: ${JOBS}"
        echo -e "This will take several hours depending on your hardware.\n"

        # Run pre-build device prep script if available (installs overlays/config)
        PREP_SCRIPT="${REPO_DIR}/scripts/prep-device-for-build.sh"
        if [ -f "${PREP_SCRIPT}" ]; then
            echo -e "${YELLOW}Running pre-build device prep: ${PREP_SCRIPT}${NC}"
            bash "${PREP_SCRIPT}"
        else
            echo -e "${YELLOW}Pre-build prep script not found at ${PREP_SCRIPT} (skipping)${NC}"
        fi

        # Set up build environment
        source build/envsetup.sh

        # Select lunch target
        lunch "$BUILD_TARGET"

        # Start build
        echo -e "\n${GREEN}Building AOSP...${NC}"
    BUILD_LOG="${SCRIPT_BUILD_DIR}/build-$(date +%Y%m%d-%H%M%S).log"
    # Run make and tee output to a log file in the trace folder
    make -j${JOBS} 2>&1 | tee "${BUILD_LOG}"

        echo -e "\n${GREEN}Build completed successfully!${NC}"
        echo -e "Creating flashable image..."

        # Create image
        if [ -f "./rpi5-mkimg.sh" ]; then
            ./rpi5-mkimg.sh
            echo -e "\n${GREEN}Image created successfully!${NC}"
            echo -e "Location: out/target/product/rpi5/rpi5.img"
        else
            echo -e "${YELLOW}Image creation script not found. Image files are in out/target/product/rpi5/${NC}"
        fi
        # If image exists, copy to script-folder/build for traceability
        IMG_PATH="out/target/product/rpi5/rpi5.img"
        if [ -f "${IMG_PATH}" ]; then
            cp "${IMG_PATH}" "${SCRIPT_BUILD_DIR}/" || true
            echo "Copied build image to: ${SCRIPT_BUILD_DIR}/$(basename ${IMG_PATH})"
        fi
        ;;

    clean)
        echo -e "\n${YELLOW}Cleaning build output...${NC}"
        source build/envsetup.sh
        lunch "$BUILD_TARGET"
        make clean
        echo "clean completed: $(date)" > "${SCRIPT_BUILD_DIR}/clean-$(date +%Y%m%d-%H%M%S).txt"
        echo -e "${GREEN}Clean completed${NC}"
        ;;

    clobber)
        echo -e "\n${RED}WARNING: This will delete all build outputs!${NC}"
        read -p "Are you sure? (y/N): " CONFIRM
        if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
            source build/envsetup.sh
            lunch "$BUILD_TARGET"
            make clobber
            echo -e "${GREEN}Clobber completed${NC}"
            echo "clobber completed: $(date)" > "${SCRIPT_BUILD_DIR}/clobber-$(date +%Y%m%d-%H%M%S).txt"
        fi
        ;;

    kernel)
        echo -e "\n${YELLOW}Building kernel only...${NC}"
        source build/envsetup.sh
        lunch "$BUILD_TARGET"
        KERNEL_LOG="${SCRIPT_BUILD_DIR}/kernel-build-$(date +%Y%m%d-%H%M%S).log"
        make bootimage -j${JOBS} 2>&1 | tee "${KERNEL_LOG}"
        echo -e "${GREEN}Kernel build completed${NC}"
        echo "Kernel build log: ${KERNEL_LOG}"
        ;;

    sync)
        echo -e "\n${YELLOW}Syncing AOSP source code...${NC}"
        SYNC_LOG="${SCRIPT_BUILD_DIR}/repo-sync-$(date +%Y%m%d-%H%M%S).log"
        ~/bin/repo sync -j${JOBS} -c --no-tags --no-clone-bundle --optimized-fetch --prune 2>&1 | tee "${SYNC_LOG}"
        echo -e "${GREEN}Sync completed${NC}"
        echo "Repo sync log: ${SYNC_LOG}"
        ;;

    info)
        echo -e "\n${BLUE}Build Information:${NC}"
        echo -e "AOSP Directory: ${AOSP_DIR}"
        echo -e "Build Target: ${BUILD_TARGET}"
        echo -e "CPU Cores: ${JOBS}"

        if [ -d "out/target/product/rpi5" ]; then
            echo -e "\n${BLUE}Build Output:${NC}"
            du -sh out/target/product/rpi5
            if [ -f "out/target/product/rpi5/rpi5.img" ]; then
                echo -e "Image: $(stat -c%s out/target/product/rpi5/rpi5.img | numfmt --to=iec-i --suffix=B)"
            fi
        fi

        if [ -f "out/error.log" ]; then
            echo -e "\n${RED}Last build had errors. Check: out/error.log${NC}"
        fi
        ;;

    flash)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Please specify SD card device${NC}"
            echo -e "Usage: $0 flash /dev/sdX"
            exit 1
        fi

        DEVICE="$2"
        IMAGE="out/target/product/rpi5/rpi5.img"

        # Validate device path
        if [[ ! "$DEVICE" =~ ^/dev/sd[a-z]$ ]] && [[ ! "$DEVICE" =~ ^/dev/mmcblk[0-9]+$ ]]; then
            echo -e "${RED}Error: Invalid device path. Must be /dev/sdX or /dev/mmcblkN${NC}"
            exit 1
        fi

        if [ ! -b "$DEVICE" ]; then
            echo -e "${RED}Error: Device $DEVICE does not exist or is not a block device${NC}"
            exit 1
        fi

        if [ ! -f "$IMAGE" ]; then
            echo -e "${RED}Error: Image file not found: $IMAGE${NC}"
            echo -e "Please build first: $0 build"
            exit 1
        fi

        echo -e "\n${RED}WARNING: This will ERASE ALL DATA on $DEVICE${NC}"
        echo -e "Image: $IMAGE ($(stat -c%s "$IMAGE" | numfmt --to=iec-i --suffix=B))"
        read -p "Continue? (yes/N): " CONFIRM

        if [ "$CONFIRM" = "yes" ]; then
            echo -e "\n${YELLOW}Flashing image to $DEVICE...${NC}"
            sudo dd if="$IMAGE" of="$DEVICE" bs=4M status=progress oflag=sync
            sync
            echo -e "${GREEN}Flashing completed!${NC}"
            # record flash action
            echo "Flashed ${IMAGE} to ${DEVICE} on $(date)" >> "${SCRIPT_BUILD_DIR}/flash-history.txt"
        else
            echo -e "${YELLOW}Flashing cancelled${NC}"
        fi
        ;;

    *)
        echo -e "${RED}Error: Unknown action '$ACTION'${NC}"
        echo -e "Run '$0 help' for usage information"
        exit 1
        ;;
esac

echo -e "\n${GREEN}Done!${NC}"
