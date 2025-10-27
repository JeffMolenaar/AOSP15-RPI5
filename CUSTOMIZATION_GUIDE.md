# AOSP Customization Quick Reference

This guide provides quick reference for the three main customization features available for your AOSP Raspberry Pi 5 build.

## 🎯 Quick Links

- **[Portrait Mode](customization/display/README.md)** - Set vertical orientation as default
- **[Auto-Start App](customization/auto-start-app/README.md)** - Launch your app on boot (kiosk mode)
- **[Custom Boot Animation](customization/boot-animation/README.md)** - Add your logo/branding
- **[Complete Guide](customization/README.md)** - Detailed documentation for all features

## 📱 Portrait Mode

**What:** Configure the device to use portrait (vertical) orientation by default.

**Quick Setup:**
```bash
# 1. Copy configuration
cp customization/display/portrait-mode.mk ~/aosp-rpi5/device/brcm/rpi5/

# 2. Add to device.mk
echo "include device/brcm/rpi5/portrait-mode.mk" >> ~/aosp-rpi5/device/brcm/rpi5/device.mk

# 3. Build
cd ~/aosp-rpi5
source build/envsetup.sh
lunch aosp_rpi5-bp1a-userdebug
make -j$(nproc)
```

**Key Configuration:**
- Rotation: 90° (portrait mode)
- LCD Density: 160 dpi (adjustable)
- Location: `customization/display/portrait-mode.mk`

📖 [Full Documentation](customization/display/README.md)

---

## 🚀 Auto-Start Application

**What:** Automatically install and launch your custom APK when the device boots.

**Quick Setup:**
```bash
# 1. Place your APK
cp /path/to/your/app.apk customization/auto-start-app/sample-app/YourApp.apk

# 2. Edit auto-start.mk and update:
#    - LOCAL_SRC_FILES := sample-app/YourApp.apk
#    - persist.autostart.package=com.your.package.name

# 3. Edit AutoStartHelper/src/com/rpi/autostarthelper/BootReceiver.java
#    - Change DEFAULT_PACKAGE to your app's package name

# 4. Copy files to AOSP
cp customization/auto-start-app/auto-start.mk ~/aosp-rpi5/device/brcm/rpi5/
cp -r customization/auto-start-app/AutoStartHelper ~/aosp-rpi5/packages/apps/

# 5. Add to device.mk
cat >> ~/aosp-rpi5/device/brcm/rpi5/device.mk << 'EOF'
include device/brcm/rpi5/auto-start.mk
PRODUCT_PACKAGES += AutoStartHelper
EOF

# 6. Build
cd ~/aosp-rpi5
source build/envsetup.sh
lunch aosp_rpi5-bp1a-userdebug
make -j$(nproc)
```

**Find Your Package Name:**
```bash
aapt dump badging YourApp.apk | grep package:
```

📖 [Full Documentation](customization/auto-start-app/README.md)

---

## 🎭 Custom Boot Animation

**What:** Replace the default Android boot animation with your custom logo or animation.

**Quick Setup (Simple Logo):**
```bash
# 1. Create boot animation from your logo
cd customization/boot-animation
./create-bootanimation.sh /path/to/your/logo.png

# For portrait mode, specify dimensions:
./create-bootanimation.sh /path/to/your/logo.png 600 800

# 2. Copy to AOSP
mkdir -p ~/aosp-rpi5/device/brcm/rpi5/bootanimation
cp bootanimation.zip ~/aosp-rpi5/device/brcm/rpi5/bootanimation/

# 3. Add to device.mk
cat >> ~/aosp-rpi5/device/brcm/rpi5/device.mk << 'EOF'
PRODUCT_COPY_FILES += \
    device/brcm/rpi5/bootanimation/bootanimation.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation.zip
EOF

# 4. Build
cd ~/aosp-rpi5
source build/envsetup.sh
lunch aosp_rpi5-bp1a-userdebug
make -j$(nproc)
```

**Test Without Rebuilding:**
```bash
adb root
adb remount
adb push bootanimation.zip /system/media/bootanimation.zip
adb reboot
```

📖 [Full Documentation](customization/boot-animation/README.md)

---

## 🎨 Use All Three Together

Complete customization example combining all features:

```bash
#!/bin/bash
# Complete AOSP customization setup

# Variables
AOSP_DIR=~/aosp-rpi5
CUSTOM_DIR=$(pwd)/customization
YOUR_APK=/path/to/your/app.apk
YOUR_LOGO=/path/to/your/logo.png
YOUR_PACKAGE=com.example.yourapp

# 1. Portrait Mode
cp $CUSTOM_DIR/display/portrait-mode.mk $AOSP_DIR/device/brcm/rpi5/

# 2. Auto-Start App
cp $YOUR_APK $CUSTOM_DIR/auto-start-app/sample-app/YourApp.apk
# Edit auto-start.mk with your package name
sed -i "s/com.example.yourapp/$YOUR_PACKAGE/g" $CUSTOM_DIR/auto-start-app/auto-start.mk
cp $CUSTOM_DIR/auto-start-app/auto-start.mk $AOSP_DIR/device/brcm/rpi5/
cp -r $CUSTOM_DIR/auto-start-app/AutoStartHelper $AOSP_DIR/packages/apps/

# 3. Boot Animation (portrait)
cd $CUSTOM_DIR/boot-animation
./create-bootanimation.sh $YOUR_LOGO 600 800
mkdir -p $AOSP_DIR/device/brcm/rpi5/bootanimation
cp bootanimation.zip $AOSP_DIR/device/brcm/rpi5/bootanimation/
cd -

# 4. Update device.mk
cat >> $AOSP_DIR/device/brcm/rpi5/device.mk << 'EOF'

# ===== CUSTOMIZATIONS =====
# Portrait mode
include device/brcm/rpi5/portrait-mode.mk

# Auto-start application
include device/brcm/rpi5/auto-start.mk
PRODUCT_PACKAGES += AutoStartHelper

# Custom boot animation
PRODUCT_COPY_FILES += \
    device/brcm/rpi5/bootanimation/bootanimation.zip:$(TARGET_COPY_OUT_PRODUCT)/media/bootanimation.zip
EOF

# 5. Build
cd $AOSP_DIR
source build/envsetup.sh
lunch aosp_rpi5-bp1a-userdebug
make -j$(nproc)

echo "Build complete! Flash the image and your customizations will be applied."
```

---

## 📋 Verification Checklist

After flashing your customized build:

### Portrait Mode
```bash
adb shell getprop ro.sf.rotation
# Should return: 90
```

### Auto-Start App
```bash
# Check app is installed
adb shell pm list packages | grep yourpackage

# Check AutoStartHelper
adb logcat | grep AutoStartHelper

# Reboot and verify app launches
adb reboot
```

### Boot Animation
```bash
# Check file exists
adb shell ls -l /system/media/bootanimation.zip

# Test manually
adb shell "setprop service.bootanim.exit 0; start bootanim"
```

---

## 🛠️ Common Use Cases

### Kiosk Device
```bash
✅ Auto-start kiosk app
✅ Portrait/landscape orientation
✅ Custom branding on boot
```

### Digital Signage
```bash
✅ Auto-launch media player
✅ Custom company logo
✅ Orientation based on display mount
```

### Point of Sale (POS)
```bash
✅ Auto-start POS app
✅ Portrait mode for vertical displays
✅ Store branding
```

### Industrial Control Panel
```bash
✅ Auto-launch control interface
✅ Custom orientation
✅ Company logo
```

---

## 🐛 Troubleshooting

### Build Errors

**Missing files:**
```bash
# Verify all files are in place
ls ~/aosp-rpi5/device/brcm/rpi5/portrait-mode.mk
ls ~/aosp-rpi5/device/brcm/rpi5/auto-start.mk
ls ~/aosp-rpi5/packages/apps/AutoStartHelper/Android.bp
ls ~/aosp-rpi5/device/brcm/rpi5/bootanimation/bootanimation.zip
```

**Syntax errors in device.mk:**
```bash
# Check for typos
cat ~/aosp-rpi5/device/brcm/rpi5/device.mk
```

### Runtime Issues

**Portrait mode not working:**
```bash
# Check property
adb shell getprop ro.sf.rotation

# Check build.prop
adb shell cat /system/build.prop | grep rotation
```

**App doesn't auto-start:**
```bash
# Check logs
adb logcat -s AutoStartHelper

# Verify package installed
adb shell pm list packages | grep yourpackage

# Check boot receiver
adb shell dumpsys package com.rpi.autostarthelper | grep "Boot"
```

**Boot animation not showing:**
```bash
# Verify file
adb shell ls -lh /system/media/bootanimation.zip

# Check format
unzip -l bootanimation.zip

# View logs
adb logcat | grep bootanim
```

---

## 📚 Additional Resources

- **Main Repository:** [README.md](README.md)
- **Build Instructions:** [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md)
- **Complete Customization Guide:** [customization/README.md](customization/README.md)
- **AOSP Documentation:** https://source.android.com/

---

## 💡 Tips

1. **Test Individually:** Apply and test each customization separately before combining
2. **Keep Backups:** Save working configurations before making changes
3. **Clean Builds:** Run `make clean` if you encounter strange build errors
4. **Incremental Testing:** Test on device with ADB before full rebuild
5. **Document Changes:** Keep notes on your specific configurations

---

**Need Help?** See the detailed documentation in [customization/README.md](customization/README.md) for comprehensive guides and troubleshooting.
