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

# Directory where we save traces of the actions (artifacts, copies, logs)
SCRIPT_BUILD_DIR="${REPO_DIR}/script-folder/build"
mkdir -p "${SCRIPT_BUILD_DIR}"

# Your custom APK file (must exist)
YOUR_APK="/path/to/your/app.apk"

# Your app's package name (e.g., com.yourcompany.app)
YOUR_PACKAGE="com.example.yourapp"

# Your logo file for boot animation (must exist)
YOUR_LOGO="/path/to/your/logo.png"

# Boot animation resolution (portrait: 600x800, landscape: 800x600)
BOOT_WIDTH=600
BOOT_HEIGHT=800

# AOSP lunch target (default: aosp_rpi5-bp1a-userdebug)
LUNCH_TARGET="aosp_rpi5-bp1a-userdebug"

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
cp "$REPO_DIR/customization/display/portrait-mode.mk" "${SCRIPT_BUILD_DIR}/portrait-mode-$(date +%Y%m%d-%H%M%S).mk" || true

# ============================================================================
# ED-HMI3010-070C (DSI) panel overlay and build fragment
# ============================================================================
echo -e "\n${GREEN}[1a/3] Preparing ED-HMI3010-070C panel overlay...${NC}"
mkdir -p "$AOSP_DIR/device/brcm/rpi5/overlays"
mkdir -p "$AOSP_DIR/device/brcm/rpi5/ed-hmi3010-070c"

# Compile the DTS to DTBO (if dtc available)
DT_SRC="$REPO_DIR/customization/display/ed-hmi3010-070c/ed-hmi3010-070c.dts"
DTBO_DST="$REPO_DIR/customization/display/ed-hmi3010-070c/ed-hmi3010-070c.dtbo"
if command -v dtc >/dev/null 2>&1 && [ -f "$DT_SRC" ]; then
    echo "Compiling DSI overlay: $DT_SRC -> $DTBO_DST"
    dtc -@ -I dts -O dtb -o "$DTBO_DST" "$DT_SRC" || true
fi

# Copy compiled dtbo (if present) into AOSP device overlays directory
if [ -f "$DTBO_DST" ]; then
    cp "$DTBO_DST" "$AOSP_DIR/device/brcm/rpi5/overlays/ed-hmi3010-070c.dtbo"
    cp "$DTBO_DST" "${SCRIPT_BUILD_DIR}/ed-hmi3010-070c-$(date +%Y%m%d-%H%M%S).dtbo" || true
    echo "✓ Copied DTBO to AOSP device overlays"
else
    echo "${YELLOW}Warning: DTBO not found. Please compile the DTS or check the DTS template at $DT_SRC${NC}"
fi

# Copy the device.mk fragment into the device folder so it can be included
cp "$REPO_DIR/customization/display/ed-hmi3010-070c/ed-hmi3010-070c.mk" "$AOSP_DIR/device/brcm/rpi5/ed-hmi3010-070c.mk"
echo "✓ Added ed-hmi3010-070c.mk to device folder"

# Ensure device.mk includes the panel fragment (append if missing)
DEVICE_MK="$AOSP_DIR/device/brcm/rpi5/device.mk"
if [ -f "$DEVICE_MK" ] && ! grep -q "ed-hmi3010-070c.mk" "$DEVICE_MK"; then
    echo "\n# Include ED-HMI3010-070C panel overlay" >> "$DEVICE_MK"
    echo "include device/brcm/rpi5/ed-hmi3010-070c.mk" >> "$DEVICE_MK"
    echo "✓ Included ed-hmi3010-070c.mk in device.mk"
else
    echo "${YELLOW}Note: device.mk not found in AOSP device folder; please include ed-hmi3010-070c.mk manually in your device.mk if necessary.${NC}"
fi

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

# Create sample-app directory if it doesn't exist
mkdir -p "$AOSP_DIR/device/brcm/rpi5/sample-app"

# Copy APK to sample-app directory
cp "$YOUR_APK" "$AOSP_DIR/device/brcm/rpi5/sample-app/YourApp.apk"
echo "✓ Copied APK to device directory"
cp "$YOUR_APK" "${SCRIPT_BUILD_DIR}/YourApp-$(date +%Y%m%d-%H%M%S).apk" || true

# Update auto-start.mk with package name
sed "s/com.example.yourapp/$YOUR_PACKAGE/g" \
    "$REPO_DIR/customization/auto-start-app/auto-start.mk" \
    > "$AOSP_DIR/device/brcm/rpi5/auto-start.mk"
echo "✓ Created auto-start.mk with package: $YOUR_PACKAGE"
cp "$AOSP_DIR/device/brcm/rpi5/auto-start.mk" "${SCRIPT_BUILD_DIR}/auto-start-$(date +%Y%m%d-%H%M%S).mk" || true

# Copy AutoStartHelper
cp -r "$REPO_DIR/customization/auto-start-app/AutoStartHelper" "$AOSP_DIR/packages/apps/"
echo "✓ Copied AutoStartHelper app"
# Save a copy of the helper app for traceability
ARCHIVE_TS="${SCRIPT_BUILD_DIR}/autostarthelper-$(date +%Y%m%d-%H%M%S)"
rm -rf "${ARCHIVE_TS}"
cp -r "$REPO_DIR/customization/auto-start-app/AutoStartHelper" "${ARCHIVE_TS}" || true

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

# Verify create-bootanimation.sh exists and is executable
BOOT_SCRIPT="$REPO_DIR/customization/boot-animation/create-bootanimation.sh"
if [ ! -f "$BOOT_SCRIPT" ]; then
    echo -e "${RED}Error: Boot animation script not found: $BOOT_SCRIPT${NC}"
    exit 1
fi

if [ ! -x "$BOOT_SCRIPT" ]; then
    chmod +x "$BOOT_SCRIPT"
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
cp "$REPO_DIR/customization/boot-animation/bootanimation.zip" "${SCRIPT_BUILD_DIR}/bootanimation-$(date +%Y%m%d-%H%M%S).zip" || true

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

# Save a copy of the modified device.mk to the trace folder
cp "$DEVICE_MK" "${SCRIPT_BUILD_DIR}/device.mk.modified-$(date +%Y%m%d-%H%M%S)" || true

# final marker for customizations
echo "Customizations applied on: $(date)" > "${SCRIPT_BUILD_DIR}/customizations-summary.txt"

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
echo "   lunch $LUNCH_TARGET"
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
