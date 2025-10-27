#!/bin/bash
# AOSP 15 Setup Script for Raspberry Pi 5 with ED-HMI3010-101C Display
# This script will set up the AOSP build environment and fetch all necessary sources

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Constants
MIN_DISK_SPACE_GB=300
MIN_RAM_GB=16

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AOSP 15 for Raspberry Pi 5 Setup${NC}"
echo -e "${GREEN}Display: ED-HMI3010-101C (10.1\" 1280x800)${NC}"
echo -e "${GREEN}========================================${NC}"

# Check system requirements
echo -e "\n${YELLOW}Checking system requirements...${NC}"

# Check available disk space (need at least MIN_DISK_SPACE_GB)
AVAILABLE_SPACE=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt "$MIN_DISK_SPACE_GB" ]; then
    echo -e "${RED}Error: Insufficient disk space. Need at least ${MIN_DISK_SPACE_GB}GB, have ${AVAILABLE_SPACE}GB${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Disk space: ${AVAILABLE_SPACE}GB available${NC}"

# Check RAM
TOTAL_RAM=$(free -g | awk 'NR==2 {print $2}')
if [ "$TOTAL_RAM" -lt "$MIN_RAM_GB" ]; then
    echo -e "${YELLOW}Warning: Less than ${MIN_RAM_GB}GB RAM detected. Build may be slow.${NC}"
else
    echo -e "${GREEN}✓ RAM: ${TOTAL_RAM}GB${NC}"
fi

# Install required packages
echo -e "\n${YELLOW}Installing required packages...${NC}"
sudo apt-get update
sudo apt-get install -y git-core gnupg flex bison build-essential zip curl zlib1g-dev \
    gcc-multilib g++-multilib libc6-dev-i386 libncurses5 lib32ncurses5-dev x11proto-core-dev \
    libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig \
    bc coreutils dosfstools e2fsprogs fdisk kpartx mtools ninja-build pkg-config python3-pip rsync \
    openjdk-11-jdk

echo -e "${GREEN}✓ Packages installed${NC}"

# Set up git configuration
echo -e "\n${YELLOW}Configuring git...${NC}"
if [ -z "$(git config --global user.name)" ]; then
    read -p "Enter your name for git: " GIT_NAME
    git config --global user.name "$GIT_NAME"
fi
if [ -z "$(git config --global user.email)" ]; then
    read -p "Enter your email for git: " GIT_EMAIL
    git config --global user.email "$GIT_EMAIL"
fi
git config --global color.ui auto
echo -e "${GREEN}✓ Git configured${NC}"

# Install repo tool
echo -e "\n${YELLOW}Installing repo tool...${NC}"
mkdir -p ~/bin
if [ ! -f ~/bin/repo ]; then
    curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
    chmod a+x ~/bin/repo
fi
export PATH=~/bin:$PATH
echo 'export PATH=~/bin:$PATH' >> ~/.bashrc
echo -e "${GREEN}✓ Repo tool installed${NC}"

# Create AOSP working directory
AOSP_DIR="${HOME}/aosp-rpi5"
echo -e "\n${YELLOW}Setting up AOSP directory: ${AOSP_DIR}${NC}"

if [ -d "$AOSP_DIR" ]; then
    echo -e "${YELLOW}Warning: Directory ${AOSP_DIR} already exists.${NC}"
    read -p "Remove and re-initialize? (y/N): " REMOVE_DIR
    if [ "$REMOVE_DIR" = "y" ] || [ "$REMOVE_DIR" = "Y" ]; then
        rm -rf "$AOSP_DIR"
    else
        echo -e "${RED}Aborting. Please remove ${AOSP_DIR} manually or choose a different location.${NC}"
        exit 1
    fi
fi

mkdir -p "$AOSP_DIR"
cd "$AOSP_DIR"

# Initialize repo with Android 15
echo -e "\n${YELLOW}Initializing AOSP repository (Android 15.0.0_r32)...${NC}"
echo -e "${YELLOW}This may take a few minutes...${NC}"
~/bin/repo init -u https://android.googlesource.com/platform/manifest -b android-15.0.0_r32 --depth=1

# Create local_manifests directory
mkdir -p .repo/local_manifests

# Download Raspberry Pi specific manifests
echo -e "\n${YELLOW}Downloading Raspberry Pi 5 manifests...${NC}"
curl -o .repo/local_manifests/manifest_brcm_rpi.xml -L \
    https://raw.githubusercontent.com/raspberry-vanilla/android_local_manifest/android-15.0/manifest_brcm_rpi.xml

curl -o .repo/local_manifests/remove_projects.xml -L \
    https://raw.githubusercontent.com/raspberry-vanilla/android_local_manifest/android-15.0/remove_projects.xml

echo -e "${GREEN}✓ Manifests downloaded${NC}"

# Sync the source code
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}Starting source code sync...${NC}"
echo -e "${YELLOW}This will download ~100GB and may take several hours!${NC}"
echo -e "${YELLOW}========================================${NC}"
read -p "Continue with sync? (y/N): " CONTINUE_SYNC

if [ "$CONTINUE_SYNC" = "y" ] || [ "$CONTINUE_SYNC" = "Y" ]; then
    ~/bin/repo sync -j$(nproc) -c --no-tags --no-clone-bundle --optimized-fetch --prune
    echo -e "${GREEN}✓ Source code synced successfully${NC}"
else
    echo -e "${YELLOW}Skipping sync. You can run 'repo sync' manually later.${NC}"
fi

# Create a marker file to indicate successful setup
touch .aosp_setup_complete

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "\nAOSP source directory: ${AOSP_DIR}"
echo -e "\nNext steps:"
echo -e "1. cd ${AOSP_DIR}"
echo -e "2. source build/envsetup.sh"
echo -e "3. lunch aosp_rpi5-bp1a-userdebug"
echo -e "4. make -j\$(nproc)"
echo -e "\nSee BUILD_INSTRUCTIONS.md for detailed build steps."
