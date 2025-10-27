#!/bin/bash
# Create a simple boot animation from a logo image

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}Error: Please provide a logo image${NC}"
    echo "Usage: $0 <logo.png> [width] [height]"
    echo ""
    echo "Examples:"
    echo "  $0 mylogo.png              # Uses default 800x600"
    echo "  $0 mylogo.png 1280 800     # Custom resolution"
    echo "  $0 mylogo.png 600 800      # Portrait mode"
    exit 1
fi

LOGO_FILE="$1"
WIDTH="${2:-800}"
HEIGHT="${3:-600}"

if [ ! -f "$LOGO_FILE" ]; then
    echo -e "${RED}Error: File not found: $LOGO_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}Creating boot animation...${NC}"
echo "Logo: $LOGO_FILE"
echo "Resolution: ${WIDTH}x${HEIGHT}"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
mkdir -p "$TEMP_DIR/part0"

# Copy or convert logo
echo -e "${YELLOW}Processing logo...${NC}"

if command -v convert &> /dev/null; then
    # Use ImageMagick to resize and center the logo
    convert "$LOGO_FILE" -resize "${WIDTH}x${HEIGHT}" -background none -gravity center -extent "${WIDTH}x${HEIGHT}" "$TEMP_DIR/part0/0000.png"
else
    # Just copy if ImageMagick is not available
    echo -e "${YELLOW}Note: Install ImageMagick for automatic resizing${NC}"
    cp "$LOGO_FILE" "$TEMP_DIR/part0/0000.png"
fi

# Create desc.txt
cat > "$TEMP_DIR/desc.txt" << EOF
$WIDTH $HEIGHT 30
p 1 0 part0
EOF

# Create the ZIP file
echo -e "${YELLOW}Creating bootanimation.zip...${NC}"
cd "$TEMP_DIR"
zip -0qry -i \*.txt \*.png @ bootanimation.zip desc.txt part0

# Copy to customization directory
cp bootanimation.zip "$(dirname "$0")/bootanimation.zip"

# Cleanup
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo -e "${GREEN}✓ Boot animation created successfully!${NC}"
echo -e "Location: $(dirname "$0")/bootanimation.zip"
echo ""
echo "Next steps:"
echo "1. Review the boot animation (optional):"
echo "   unzip -l $(dirname "$0")/bootanimation.zip"
echo ""
echo "2. Apply to your AOSP build:"
echo "   ./build-helper.sh apply-customization boot-animation"
echo ""
echo "3. Or copy manually to:"
echo "   device/brcm/rpi5/bootanimation/"
