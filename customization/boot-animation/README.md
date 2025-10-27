# Custom Boot Animation (Splash Screen)

This directory contains configuration for creating a custom boot animation with your own logo and branding for the Raspberry Pi 5 AOSP build.

## Overview

The Android boot animation is what you see when the device starts up. This guide helps you create a custom boot animation with your company logo or branding.

## Boot Animation Format

Android boot animations are ZIP files containing:
- PNG images (frames of the animation)
- A `desc.txt` file describing the animation parameters

## Directory Structure

```
boot-animation/
├── README.md                    # This file
├── bootanimation.zip           # Your custom boot animation
├── template/                   # Template to create your own
│   ├── desc.txt               # Animation configuration
│   ├── part0/                 # Splash screen (static logo)
│   │   └── 0000.png          # Your logo image
│   └── part1/                 # Animation loop (optional)
│       ├── 0000.png
│       ├── 0001.png
│       └── ...
└── examples/                   # Example boot animations
    └── simple-logo/
        └── bootanimation.zip
```

## Quick Start Guide

### Option 1: Use Simple Logo Template

The easiest way is to use a single static image (your logo) as the boot animation.

1. **Prepare your logo:**
   - Format: PNG with transparency
   - Recommended size: 800x600 pixels (or 600x800 for portrait)
   - Name it: `logo.png`

2. **Generate boot animation:**
   ```bash
   cd customization/boot-animation
   ./create-bootanimation.sh logo.png
   ```

3. **Apply to build:**
   ```bash
   ./build-helper.sh apply-customization boot-animation
   ```

### Option 2: Create Custom Animation Manually

For a more complex animated boot sequence:

1. **Create your animation frames:**
   - Create PNG images (800x600 or your display resolution)
   - Name them sequentially: 0000.png, 0001.png, 0002.png, etc.
   - All frames should be the same size
   - Use PNG format for transparency support

2. **Organize frames into parts:**
   - `part0/` - Intro animation (plays once)
   - `part1/` - Loop animation (repeats until boot finishes)
   - You can have multiple parts

3. **Create desc.txt:**
   ```
   800 600 30
   p 1 0 part0
   p 0 0 part1
   ```
   
   Format: `WIDTH HEIGHT FPS`
   - WIDTH: Animation width in pixels (800 for landscape, 600 for portrait)
   - HEIGHT: Animation height in pixels (600 for landscape, 800 for portrait)
   - FPS: Frames per second (typically 30)

   Each line starting with 'p':
   - `p COUNT PAUSE FOLDER`
   - COUNT: Number of times to play (0 = infinite loop)
   - PAUSE: Pause in frames between loops
   - FOLDER: Directory name (part0, part1, etc.)

4. **Create the ZIP file:**
   ```bash
   cd template/
   zip -0qry -i \*.txt \*.png @ ../bootanimation.zip *.txt part*
   ```

   Important: Use `-0` flag for no compression!

5. **Apply to build** (see below)

## Applying Custom Boot Animation

### Method 1: Using Build Helper (Recommended)

```bash
./build-helper.sh apply-customization boot-animation
```

This will automatically copy your `bootanimation.zip` to the correct location in the AOSP build.

### Method 2: Manual Installation

1. Copy to AOSP build:
   ```bash
   cd ~/aosp-rpi5
   mkdir -p device/brcm/rpi5/bootanimation
   cp ~/AOSP15-RPI5/customization/boot-animation/bootanimation.zip \
      device/brcm/rpi5/bootanimation/
   ```

2. Edit `device/brcm/rpi5/device.mk` and add:
   ```makefile
   # Custom boot animation
   PRODUCT_COPY_FILES += \
       device/brcm/rpi5/bootanimation/bootanimation.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation.zip
   ```

3. Build AOSP:
   ```bash
   cd ~/aosp-rpi5
   source build/envsetup.sh
   lunch aosp_rpi5-bp1a-userdebug
   make -j$(nproc)
   ```

### Method 3: Replace on Running Device (Testing Only)

For quick testing without rebuilding:

```bash
adb root
adb remount
adb push bootanimation.zip /system/media/bootanimation.zip
adb reboot
```

Note: This will be lost after factory reset. For permanent changes, include in the build.

## Resolution Guidelines

### For Landscape Mode (Default)
- Resolution: 1280x800 pixels
- desc.txt: `1280 800 30`

### For Portrait Mode
- Resolution: 800x1280 pixels  
- desc.txt: `800 1280 30`

You can also use smaller resolutions and they will be scaled:
- 800x600 (landscape)
- 600x800 (portrait)
- 640x480 (4:3)

## Creating Frames from Video

If you have a video you want to convert to a boot animation:

```bash
# Install ffmpeg if not already installed
sudo apt-get install ffmpeg

# Extract frames from video
ffmpeg -i your-video.mp4 -vf "scale=800:600" -r 30 part1/%04d.png

# This creates frames: part1/0001.png, part1/0002.png, etc.
```

Adjust resolution and frame rate as needed.

## Example desc.txt Configurations

### Simple Static Logo (No Animation)

```
800 600 30
p 1 0 part0
```

Just one folder with one image that displays once.

### Logo Then Loop Animation

```
800 600 30
p 1 0 part0
p 0 0 part1
```

Shows `part0` once (your logo), then loops `part1` forever.

### Complex Multi-Part Animation

```
1280 800 30
p 1 0 part0
p 2 10 part1
p 0 15 part2
```

- Plays `part0` once
- Plays `part1` twice with 10-frame pause
- Loops `part2` forever with 15-frame pause

## Optimizing File Size

Boot animations should be reasonably sized:

1. **Use appropriate resolution:**
   - Don't use 4K images for an 800x600 display
   - Scale images to display resolution

2. **Optimize PNG files:**
   ```bash
   # Install optipng
   sudo apt-get install optipng
   
   # Optimize all PNGs
   optipng -o7 part*/*.png
   ```

3. **Reduce colors if possible:**
   ```bash
   # Convert to 256 colors (if image allows)
   convert input.png -colors 256 output.png
   ```

4. **Limit frame count:**
   - A 5-second animation at 30 FPS = 150 frames
   - More frames = larger file = longer flash time

Recommended: Keep bootanimation.zip under 5MB.

## Testing Your Boot Animation

### Preview on PC

Use a video player or image viewer to preview your frames:

```bash
# Create a video preview
ffmpeg -framerate 30 -i part1/%04d.png -c:v libx264 preview.mp4
```

### Test on Device

```bash
# Push to device
adb root
adb remount
adb push bootanimation.zip /system/media/bootanimation.zip

# Force display the boot animation
adb shell "setprop service.bootanim.exit 0; start bootanim"

# Reboot to see it during actual boot
adb reboot
```

## Troubleshooting

### Boot Animation Doesn't Show

1. **Check file location:**
   ```bash
   adb shell ls -l /system/media/bootanimation.zip
   ```

2. **Verify ZIP format:**
   ```bash
   unzip -l bootanimation.zip
   ```
   
   Should show `desc.txt` and `part0/0000.png`, etc.

3. **Check logs:**
   ```bash
   adb logcat | grep -i boot
   ```

### Animation is Distorted

- Verify resolution in `desc.txt` matches your images
- Check that all images are the same size
- Ensure ZIP was created with `-0` flag (no compression)

### Animation Too Fast/Slow

Adjust FPS in desc.txt:
- Slower: Reduce FPS (e.g., 15 or 20)
- Faster: Increase FPS (e.g., 60)

### Images Don't Load

1. **File naming:** Must be 0000.png, 0001.png (4 digits)
2. **Format:** Must be PNG, not JPG or other formats
3. **ZIP compression:** Must use `-0` flag when creating ZIP

## Advanced Customization

### Audio During Boot

Android boot animations can include audio:

1. Add `audio.wav` or `audio.mp3` to the ZIP
2. Audio will play during the animation

Example:
```bash
zip -0qry -i \*.txt \*.png \*.wav @ bootanimation.zip *.txt *.wav part*
```

### High-Resolution Displays

For high-DPI displays, create higher resolution images:
- 1920x1080 (Full HD)
- 2560x1600 (Retina)

Update desc.txt accordingly.

### Themed Boot Animations

Create multiple boot animations for different themes:
- Dark mode version
- Light mode version  
- Seasonal themes

Use system properties or scripts to swap between them.

## Examples and Templates

### Simple Logo Template

See `template/simple-logo/` for a basic single-image boot animation template.

### Animated Logo Template

See `template/animated-logo/` for a template with fade-in/fade-out effects.

## Tools and Resources

**Image Editors:**
- GIMP (Free): https://www.gimp.org/
- Inkscape (Vector, Free): https://inkscape.org/
- Adobe Photoshop
- Affinity Designer

**Animation Tools:**
- Blender (3D, Free): https://www.blender.org/
- Adobe After Effects
- DaVinci Resolve (Free)

**Utilities:**
- ffmpeg: Video to frames conversion
- ImageMagick: Batch image processing
- optipng: PNG optimization

## Best Practices

1. **Keep it simple:** Complex animations increase boot time
2. **Test on device:** What looks good on PC may differ on device
3. **Use appropriate resolution:** Match your display
4. **Optimize images:** Reduce file size without quality loss
5. **Consider boot time:** Very long animations delay user interaction
6. **Maintain branding consistency:** Match your app's look and feel

## Related Files

- `frameworks/base/cmds/bootanimation/` - Boot animation service
- `system/core/rootdir/init.rc` - Boot initialization
- `device/brcm/rpi5/device.mk` - Device configuration

## References

- [Android Boot Animation Format](https://android.googlesource.com/platform/frameworks/base/+/master/cmds/bootanimation/FORMAT.md)
- [Custom Boot Animations Guide](https://source.android.com/docs/core/display/boot-animation)
- [AOSP Boot Process](https://source.android.com/docs/core/architecture/bootloader)
