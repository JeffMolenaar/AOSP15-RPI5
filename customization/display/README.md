# Portrait Mode Configuration

This directory contains configuration for setting the default display orientation to portrait mode on your Raspberry Pi 5 AOSP build.

## Overview

By default, Android on Raspberry Pi 5 boots in landscape mode (horizontal). This configuration allows you to set portrait mode (vertical) as the default orientation.

## How It Works

The configuration modifies the device configuration during the AOSP build process to set the default rotation to portrait mode (90 degrees from landscape).

## Configuration File

### `portrait-mode.mk`

This makefile fragment sets the default display rotation to portrait mode. It will be included in your device configuration during the build.

**What it does:**
- Sets `ro.sf.lcd_density` for portrait aspect ratio
- Configures default rotation to 90 degrees (portrait)
- Adjusts window manager settings for portrait orientation

## How to Apply

### Option 1: During Build Setup (Recommended)

1. After running `setup-aosp.sh`, navigate to your AOSP directory:
   ```bash
   cd ~/aosp-rpi5
   ```

2. Copy the portrait mode configuration to the device tree:
   ```bash
   cp ~/AOSP15-RPI5/customization/display/portrait-mode.mk \
      device/brcm/rpi5/
   ```

3. Edit `device/brcm/rpi5/device.mk` and add this line at the end:
   ```makefile
   # Enable portrait mode as default
   include device/brcm/rpi5/portrait-mode.mk
   ```

4. Build AOSP normally:
   ```bash
   cd ~/aosp-rpi5
   source build/envsetup.sh
   lunch aosp_rpi5-bp1a-userdebug
   make -j$(nproc)
   ```

### Option 2: Using the Build Helper Script

We've added a helper function to the build script:

```bash
./build-helper.sh apply-customization display
```

This will automatically copy the configuration files and update the necessary build files.

## Configuration Details

### Display Density

The configuration sets an appropriate LCD density for portrait mode:
- **Portrait (800x1280)**: 160 dpi

You can adjust this in `portrait-mode.mk` if needed.

### Rotation Settings

The system property `ro.sf.rotation` is set to `90` for portrait mode:
- `0` = Landscape (default)
- `90` = Portrait (90° clockwise)
- `180` = Landscape inverted
- `270` = Portrait inverted (90° counter-clockwise)

## Verifying Portrait Mode

After flashing and booting your device:

1. Connect via ADB:
   ```bash
   adb connect <raspberry-pi-ip>
   ```

2. Check the rotation setting:
   ```bash
   adb shell getprop ro.sf.rotation
   ```
   Should return: `90`

3. Check the display density:
   ```bash
   adb shell wm density
   ```

## Customization Options

### Different Rotation

To use a different rotation, edit `portrait-mode.mk` and change:
```makefile
PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.rotation=270
```

Values:
- `0` = Normal landscape
- `90` = Portrait (rotate 90° clockwise)
- `180` = Inverted landscape
- `270` = Portrait (rotate 90° counter-clockwise)

### Adjust Display Density

If text/icons are too large or small, adjust the density in `portrait-mode.mk`:
```makefile
PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=200
```

Common values:
- `120` = Low density (larger UI elements)
- `160` = Medium density (default for this resolution)
- `200` = High density (smaller UI elements)
- `240` = Extra high density

## Troubleshooting

### Display is Still in Landscape Mode

1. Verify the configuration was included:
   ```bash
   cd ~/aosp-rpi5
   grep -r "portrait-mode.mk" device/brcm/rpi5/device.mk
   ```

2. Check if the property is set in the build:
   ```bash
   cd ~/aosp-rpi5/out/target/product/rpi5
   grep "ro.sf.rotation" system/build.prop
   ```

3. Rebuild after ensuring configuration is included:
   ```bash
   cd ~/aosp-rpi5
   source build/envsetup.sh
   lunch aosp_rpi5-bp1a-userdebug
   make -j$(nproc)
   ```

### Touch Input is Misaligned

If touch works but coordinates are wrong in portrait mode, you may need to adjust the device tree overlay. Edit the touch overlay settings in `device-tree/hmi3010-touch-overlay.dts`:

```dts
touchscreen-swapped-x-y;    /* Swap X and Y for portrait */
touchscreen-inverted-x;      /* May need to invert */
touchscreen-inverted-y;      /* May need to invert */
```

Recompile the device tree and rebuild.

## Advanced Configuration

### Lock Orientation

To prevent apps from changing the orientation, add to `portrait-mode.mk`:

```makefile
PRODUCT_PROPERTY_OVERRIDES += \
    ro.lockscreen.disable.default=true
```

### Per-App Orientation

Individual apps can still request different orientations in their AndroidManifest.xml. The system default will be portrait, but apps can override this.

## Related Files

- `device/brcm/rpi5/device.mk` - Main device configuration
- `device/brcm/rpi5/BoardConfig.mk` - Board-specific configuration
- `frameworks/base/core/res/res/values/config.xml` - System UI configuration

## References

- [Android Display Configuration](https://source.android.com/docs/core/display)
- [Surface Flinger Properties](https://source.android.com/docs/core/graphics/surfaceflinger)
- [AOSP Build System](https://source.android.com/docs/setup/build)
