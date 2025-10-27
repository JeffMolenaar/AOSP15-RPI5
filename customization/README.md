# AOSP Customization Guide for Raspberry Pi 5

This directory contains easy-to-use configurations for customizing your AOSP build.

## Available Customizations

### 1. Portrait Mode
**Location:** `customization/display/`

Set portrait mode (vertical orientation) as the default display orientation instead of landscape.

**Features:**
- ✅ Configure default rotation to portrait (90°)
- ✅ Adjustable display density for optimal UI
- ✅ Easy integration with AOSP build system

**Quick Start:**
```bash
# Copy configuration to AOSP
cp customization/display/portrait-mode.mk ~/aosp-rpi5/device/brcm/rpi5/

# Edit device.mk and add:
# include device/brcm/rpi5/portrait-mode.mk
```

📖 [Full Documentation](display/README.md)

---

### 2. Auto-Start Application
**Location:** `customization/auto-start-app/`

Automatically install and launch a custom APK when the device boots.

**Features:**
- ✅ Include custom APK in system image
- ✅ Auto-launch on boot (kiosk mode ready)
- ✅ Runs as privileged system app
- ✅ Survives factory resets

**Quick Start:**
```bash
# 1. Place your APK in sample-app/
cp /path/to/your/app.apk customization/auto-start-app/sample-app/YourApp.apk

# 2. Update package name in auto-start.mk
# Edit: persist.autostart.package=com.your.package

# 3. Copy to AOSP
cp customization/auto-start-app/auto-start.mk ~/aosp-rpi5/device/brcm/rpi5/
cp -r customization/auto-start-app/AutoStartHelper ~/aosp-rpi5/packages/apps/

# 4. Edit device.mk and add:
# include device/brcm/rpi5/auto-start.mk
# PRODUCT_PACKAGES += AutoStartHelper
```

📖 [Full Documentation](auto-start-app/README.md)

---

### 3. Custom Boot Animation (Splash Screen)
**Location:** `customization/boot-animation/`

Create a custom boot animation with your company logo or branding.

**Features:**
- ✅ Easy logo-to-boot-animation conversion
- ✅ Supports static images or animations
- ✅ Customizable resolution and timing
- ✅ Professional branding on boot

**Quick Start:**
```bash
# Create boot animation from your logo
cd customization/boot-animation
./create-bootanimation.sh /path/to/your/logo.png

# Copy to AOSP
cp bootanimation.zip ~/aosp-rpi5/device/brcm/rpi5/bootanimation/

# Edit device.mk and add:
# PRODUCT_COPY_FILES += \
#     device/brcm/rpi5/bootanimation/bootanimation.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation.zip
```

📖 [Full Documentation](boot-animation/README.md)

---

## Using Multiple Customizations

You can combine all three customizations in a single build:

### Complete Example

1. **Set up portrait mode:**
   ```bash
   cp customization/display/portrait-mode.mk ~/aosp-rpi5/device/brcm/rpi5/
   ```

2. **Add auto-start app:**
   ```bash
   cp customization/auto-start-app/auto-start.mk ~/aosp-rpi5/device/brcm/rpi5/
   cp -r customization/auto-start-app/AutoStartHelper ~/aosp-rpi5/packages/apps/
   cp /path/to/your/app.apk ~/aosp-rpi5/device/brcm/rpi5/sample-app/YourApp.apk
   ```

3. **Create custom boot animation:**
   ```bash
   cd customization/boot-animation
   ./create-bootanimation.sh /path/to/logo.png 600 800  # Portrait resolution
   mkdir -p ~/aosp-rpi5/device/brcm/rpi5/bootanimation
   cp bootanimation.zip ~/aosp-rpi5/device/brcm/rpi5/bootanimation/
   ```

4. **Edit `~/aosp-rpi5/device/brcm/rpi5/device.mk`:**
   ```makefile
   # Add at the end of the file:
   
   # Portrait mode configuration
   include device/brcm/rpi5/portrait-mode.mk
   
   # Auto-start application
   include device/brcm/rpi5/auto-start.mk
   PRODUCT_PACKAGES += AutoStartHelper
   
   # Custom boot animation
   PRODUCT_COPY_FILES += \
       device/brcm/rpi5/bootanimation/bootanimation.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation.zip
   ```

5. **Build:**
   ```bash
   cd ~/aosp-rpi5
   source build/envsetup.sh
   lunch aosp_rpi5-bp1a-userdebug
   make -j$(nproc)
   ```

---

## Build Helper Integration

We've enhanced the `build-helper.sh` script to simplify applying customizations:

```bash
# Apply individual customizations
./build-helper.sh apply-customization display
./build-helper.sh apply-customization auto-start
./build-helper.sh apply-customization boot-animation

# Apply all customizations at once
./build-helper.sh apply-customization all
```

---

## Directory Structure

```
customization/
├── README.md                          # This file
│
├── display/                           # Portrait mode configuration
│   ├── README.md                      # Detailed guide
│   └── portrait-mode.mk               # Makefile configuration
│
├── auto-start-app/                    # Auto-start application
│   ├── README.md                      # Detailed guide
│   ├── auto-start.mk                  # Makefile configuration
│   ├── AutoStartHelper/               # Boot receiver app
│   │   ├── Android.bp
│   │   ├── AndroidManifest.xml
│   │   └── src/
│   └── sample-app/                    # Place your APK here
│       └── README.md
│
└── boot-animation/                    # Custom boot animation
    ├── README.md                      # Detailed guide
    ├── create-bootanimation.sh        # Helper script
    ├── bootanimation.zip              # Generated boot animation
    ├── template/                      # Templates
    │   └── simple-logo/
    └── examples/                      # Example animations
```

---

## Common Use Cases

### Kiosk Device
Perfect for dedicated-purpose devices:
- ✅ Auto-start your kiosk app on boot
- ✅ Show your branding during boot
- ✅ Lock to portrait or landscape orientation

### Digital Signage
Create a professional digital signage solution:
- ✅ Auto-launch media player app
- ✅ Custom boot animation with company logo
- ✅ Configure orientation based on display mounting

### Industrial Control Panel
Build a custom industrial interface:
- ✅ Launch control app automatically
- ✅ Portrait mode for vertical control panels
- ✅ Professional boot screen

### Point-of-Sale (POS) System
Create a custom POS solution:
- ✅ Auto-start POS application
- ✅ Brand boot screen with store logo
- ✅ Set appropriate orientation

### Home Automation Dashboard
Build a home control interface:
- ✅ Launch dashboard on boot
- ✅ Custom branding
- ✅ Optimal screen orientation

---

## Testing Your Customizations

### Before Full Build

1. **Test boot animation on device:**
   ```bash
   adb root
   adb remount
   adb push bootanimation.zip /system/media/bootanimation.zip
   adb shell "setprop service.bootanim.exit 0; start bootanim"
   ```

2. **Test APK installation:**
   ```bash
   adb install -r your-app.apk
   adb shell am start -n com.your.package/.MainActivity
   ```

3. **Test orientation:**
   ```bash
   adb shell settings put system user_rotation 1  # 1=90°, 2=180°, 3=270°
   ```

### After Build

1. Flash the image to SD card
2. Boot the Raspberry Pi 5
3. Verify all customizations:
   - Check boot animation displays
   - Verify orientation is correct
   - Confirm app auto-starts

---

## Troubleshooting

### Build Errors

**Error:** `portrait-mode.mk: No such file or directory`
- **Solution:** Ensure you copied the file to the correct location
- **Check:** `ls ~/aosp-rpi5/device/brcm/rpi5/portrait-mode.mk`

**Error:** `AutoStartHelper module not found`
- **Solution:** Copy the entire AutoStartHelper directory to packages/apps/
- **Check:** `ls ~/aosp-rpi5/packages/apps/AutoStartHelper/Android.bp`

**Error:** `bootanimation.zip not found`
- **Solution:** Create the boot animation first using the helper script
- **Check:** `ls ~/aosp-rpi5/device/brcm/rpi5/bootanimation/bootanimation.zip`

### Runtime Issues

**Portrait mode not working:**
```bash
# Check property is set
adb shell getprop ro.sf.rotation

# Should return: 90
```

**App doesn't auto-start:**
```bash
# Check AutoStartHelper logs
adb logcat | grep AutoStartHelper

# Verify package name
adb shell pm list packages | grep yourapp
```

**Boot animation not showing:**
```bash
# Check file exists
adb shell ls -l /system/media/bootanimation.zip

# Check boot animation logs
adb logcat | grep bootanim
```

---

## Best Practices

1. **Test individually:** Apply and test each customization separately before combining
2. **Keep backups:** Save working configurations before making changes
3. **Document changes:** Note any modifications to default settings
4. **Version control:** Track your customization files in git
5. **Clean builds:** Use `make clean` between major customization changes

---

## Advanced Topics

### Creating Your Own Customizations

You can create additional customizations following the same pattern:

1. Create a directory under `customization/`
2. Add configuration files (`.mk`, source code, etc.)
3. Write a detailed README.md
4. Create helper scripts if needed
5. Update this main README

### Modifying Existing Customizations

All configuration files are designed to be easily edited:
- Makefiles use simple variable syntax
- Source code is well-commented
- README files explain all parameters

### Integration with CI/CD

For automated builds with customizations:

```bash
#!/bin/bash
# Apply customizations before build
cp customization/display/portrait-mode.mk device/brcm/rpi5/
cp customization/auto-start-app/auto-start.mk device/brcm/rpi5/
# ... etc

# Build
source build/envsetup.sh
lunch aosp_rpi5-bp1a-userdebug
make -j$(nproc)
```

---

## Resources

- [AOSP Build System](https://source.android.com/docs/setup/build)
- [Android Device Configuration](https://source.android.com/docs/core/architecture/configuration)
- [Boot Animation Format](https://android.googlesource.com/platform/frameworks/base/+/master/cmds/bootanimation/FORMAT.md)
- [System Apps Integration](https://source.android.com/docs/core/permissions/perms-allowlist)

---

## Support

For questions or issues:
1. Check the detailed README in each customization directory
2. Review the TROUBLESHOOTING.md in the main repository
3. Check logs using `adb logcat`
4. Search existing issues on GitHub

---

## Contributing

Found a bug or have an improvement? Contributions are welcome!

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

---

**Ready to customize your AOSP build?** Start with the customization that best fits your needs, or combine all three for a complete custom solution! 🚀
