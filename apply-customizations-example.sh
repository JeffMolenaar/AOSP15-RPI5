#!/bin/bash
# Example script showing how to apply all customizations
# This is a template - edit the variables below for your specific setup

set -e

# ============================================================================
# CONFIGURATION - Edit these variables for your setup
# ============================================================================

# Path to your AOSP directory (default: ~/aosp-rpi5)
AOSP_DIR="${HOME}/aosp-rpi5"

# Path to this repository (where you cloned AOSP15-RPI5)
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Your custom APK file (must exist)
YOUR_APK="/path/to/your/app.apk"

# Your app's package name (e.g., com.yourcompany.app)
YOUR_PACKAGE="com.example.yourapp"

# Your logo file for boot animation (must exist)
YOUR_LOGO="/path/to/your/logo.png"

# Boot animation resolution (portrait: 600x800, landscape: 800x600)
BOOT_WIDTH=600
BOOT_HEIGHT=800

# ============================================================================
# Script starts here - no need to edit below unless customizing further
# ============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}AOSP Customization Setup${NC}"
echo -e "${GREEN}========================================${NC}"

# Verify AOSP directory exists
if [ ! -d "$AOSP_DIR" ]; then
    echo -e "${RED}Error: AOSP directory not found: $AOSP_DIR${NC}"
    echo "Please run setup-aosp.sh first or update AOSP_DIR variable"
    exit 1
fi

echo -e "\n${YELLOW}Configuration:${NC}"
echo "AOSP Directory: $AOSP_DIR"
echo "Repository: $REPO_DIR"
echo "APK: $YOUR_APK"
echo "Package: $YOUR_PACKAGE"
echo "Logo: $YOUR_LOGO"
echo "Boot Animation: ${BOOT_WIDTH}x${BOOT_HEIGHT}"

read -p "Continue with these settings? (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "Aborted."
    exit 0
fi

# ============================================================================
# 1. PORTRAIT MODE
# ============================================================================

echo -e "\n${GREEN}[1/3] Setting up Portrait Mode...${NC}"
cp "$REPO_DIR/customization/display/portrait-mode.mk" "$AOSP_DIR/device/brcm/rpi5/"
echo "✓ Copied portrait-mode.mk"

# ============================================================================
# 2. AUTO-START APP
# ============================================================================

echo -e "\n${GREEN}[2/3] Setting up Auto-Start App...${NC}"

# Verify APK exists
if [ ! -f "$YOUR_APK" ]; then
    echo -e "${RED}Error: APK file not found: $YOUR_APK${NC}"
    echo "Please update YOUR_APK variable or place your APK at that location"
    exit 1
fi

# Copy APK to sample-app directory
cp "$YOUR_APK" "$AOSP_DIR/device/brcm/rpi5/sample-app/YourApp.apk"
echo "✓ Copied APK to device directory"

# Update auto-start.mk with package name
sed "s/com.example.yourapp/$YOUR_PACKAGE/g" \
    "$REPO_DIR/customization/auto-start-app/auto-start.mk" \
    > "$AOSP_DIR/device/brcm/rpi5/auto-start.mk"
echo "✓ Created auto-start.mk with package: $YOUR_PACKAGE"

# Copy AutoStartHelper
cp -r "$REPO_DIR/customization/auto-start-app/AutoStartHelper" "$AOSP_DIR/packages/apps/"
echo "✓ Copied AutoStartHelper app"

# ============================================================================
# 3. BOOT ANIMATION
# ============================================================================

echo -e "\n${GREEN}[3/3] Setting up Boot Animation...${NC}"

# Verify logo exists
if [ ! -f "$YOUR_LOGO" ]; then
    echo -e "${RED}Error: Logo file not found: $YOUR_LOGO${NC}"
    echo "Please update YOUR_LOGO variable or place your logo at that location"
    exit 1
fi

# Create boot animation
cd "$REPO_DIR/customization/boot-animation"
./create-bootanimation.sh "$YOUR_LOGO" "$BOOT_WIDTH" "$BOOT_HEIGHT"
cd - > /dev/null

# Copy to AOSP
mkdir -p "$AOSP_DIR/device/brcm/rpi5/bootanimation"
cp "$REPO_DIR/customization/boot-animation/bootanimation.zip" \
   "$AOSP_DIR/device/brcm/rpi5/bootanimation/"
echo "✓ Created and copied boot animation"

# ============================================================================
# 4. UPDATE device.mk
# ============================================================================

echo -e "\n${GREEN}Updating device.mk...${NC}"

DEVICE_MK="$AOSP_DIR/device/brcm/rpi5/device.mk"

# Check if customizations are already in device.mk
if grep -q "CUSTOMIZATIONS" "$DEVICE_MK"; then
    echo -e "${YELLOW}Warning: Customizations section already exists in device.mk${NC}"
    echo "Please review and update manually: $DEVICE_MK"
else
    # Add customizations to device.mk
    cat >> "$DEVICE_MK" << 'EOF'

# ===== CUSTOMIZATIONS =====
# Portrait mode configuration
include device/brcm/rpi5/portrait-mode.mk

# Auto-start application
include device/brcm/rpi5/auto-start.mk
PRODUCT_PACKAGES += AutoStartHelper

# Custom boot animation
PRODUCT_COPY_FILES += \
    device/brcm/rpi5/bootanimation/bootanimation.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation.zip
EOF
    echo "✓ Updated device.mk with customizations"
fi

# ============================================================================
# Summary
# ============================================================================

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Customization Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Applied customizations:"
echo "  ✓ Portrait mode (90° rotation)"
echo "  ✓ Auto-start app: $YOUR_PACKAGE"
echo "  ✓ Custom boot animation (${BOOT_WIDTH}x${BOOT_HEIGHT})"
echo ""
echo "Next steps:"
echo "1. Review the changes in $AOSP_DIR/device/brcm/rpi5/"
echo "2. Build AOSP:"
echo "   cd $AOSP_DIR"
echo "   source build/envsetup.sh"
echo "   lunch aosp_rpi5-bp1a-userdebug"
echo "   make -j\$(nproc)"
echo ""
echo "3. Flash to SD card:"
echo "   cd $(dirname $0)"
echo "   ./build-helper.sh flash /dev/sdX"
echo ""
echo "After flashing, your device will:"
echo "  - Boot in portrait mode"
echo "  - Show your custom boot animation"
echo "  - Automatically launch your app"
echo ""
echo -e "${GREEN}Ready to build!${NC}"
