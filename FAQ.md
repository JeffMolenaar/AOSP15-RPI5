# Frequently Asked Questions (FAQ)

Common questions about building AOSP 15 for Raspberry Pi 5 with the ED-HMI3010-101C display.

## General Questions

### Q: What is AOSP?
**A:** AOSP (Android Open Source Project) is the open-source version of Android, maintained by Google. It's the base code that commercial Android builds (Samsung, Google Pixel, etc.) are based on.

### Q: Why build AOSP instead of using a pre-built image?
**A:** Building from source allows you to:
- Customize Android for your specific needs
- Add custom features or modifications
- Learn how Android works internally
- Create your own Android-based products
- Have full control over updates and security

### Q: How long does the entire process take?
**A:**
- **Setup + Download**: 30 minutes to 2 hours (depends on internet speed)
- **Build**: 2-6 hours (depends on your hardware)
- **Flash**: 5-10 minutes
- **Total**: 3-9 hours (mostly automated)

### Q: Can I use this on other Raspberry Pi models?
**A:** This setup is specifically for Raspberry Pi 5. For other models:
- **Raspberry Pi 4**: Use `aosp_rpi4-bp1a-userdebug` target
- **Raspberry Pi 3 or earlier**: Not officially supported for Android 15

## Hardware Questions

### Q: Will the ED-HMI3010-101C work with other single-board computers?
**A:** The display uses standard HDMI for video, so it can work with any device supporting HDMI output. However, the touch functionality is configured specifically for Raspberry Pi's GPIO/I2C, so touch may not work on other boards without modification.

### Q: Can I use a different display?
**A:** Yes! Any HDMI display will work for video output. For touch displays:
- HDMI/USB touch displays work out-of-the-box
- Other I2C/SPI touch displays need custom device tree overlays

### Q: Do I need exactly 32GB RAM on my build machine?
**A:** No, but:
- **16GB**: Will work with reduced parallel jobs (`make -j4`)
- **32GB**: Comfortable for full parallel builds
- **64GB**: Ideal for fastest builds
- **<16GB**: Possible with swap, but very slow

### Q: What's the minimum SD card size?
**A:** 
- **32GB**: Absolute minimum (tight fit)
- **64GB**: Recommended
- **128GB+**: Comfortable with room for apps and data

### Q: Can I boot from USB or NVMe instead of SD card?
**A:** Yes! Raspberry Pi 5 supports NVMe boot. You'll need to:
1. Update the bootloader
2. Flash the image to NVMe instead of SD card
3. NVMe is much faster than SD cards

## Build Questions

### Q: Do I need to download 100GB every time I build?
**A:** No! You only download once. After that:
- Source code stays on your disk
- Updates are incremental (small)
- Rebuilds use existing code

### Q: Can I pause and resume the download?
**A:** Yes! If `repo sync` is interrupted:
```bash
repo sync  # Resume where it left off
```

### Q: What if my build fails?
**A:** 
1. Check `~/aosp-rpi5/out/error.log` for errors
2. See TROUBLESHOOTING.md for common issues
3. Most failures are due to:
   - Insufficient RAM (reduce parallel jobs)
   - Missing dependencies (reinstall)
   - Disk space (clean old builds)

### Q: How much disk space do I need?
**A:**
- **Download**: ~100GB
- **Extracted**: ~150GB
- **Build output**: ~50-100GB
- **Total**: 100GB minimum, 150GB+ recommended

### Q: Can I build on Windows or macOS?
**A:** 
- **Windows**: No, AOSP requires Linux. Use WSL2 or a VM
- **macOS**: Theoretically possible but not recommended. Use Linux VM
- **Linux**: Yes, Ubuntu 24.04.3 LTS recommended

### Q: Can I build in a VM?
**A:** Yes, but allocate enough resources:
- 8+ CPU cores
- 32GB+ RAM
- 100GB+ disk space
- SSD storage highly recommended

### Q: How do I update to a newer Android version?
**A:**
1. Change branch: `repo init -b android-16.0`
2. Sync: `repo sync`
3. Rebuild: `./build-helper.sh build`

## Software Questions

### Q: Does Google Play Store work?
**A:** No, AOSP doesn't include Google services. Alternatives:
- **F-Droid**: Open-source app store
- **Aurora Store**: Google Play proxy
- **APK files**: Manual installation via ADB

### Q: Can I root the device?
**A:** The `userdebug` build includes root access via ADB:
```bash
adb root
adb shell
# You're now root
```

### Q: What apps are included?
**A:** AOSP includes basic apps:
- Settings
- Launcher
- Browser
- Calculator
- Clock
- Contacts
- Messaging

No Google apps (Gmail, Maps, YouTube, etc.).

### Q: Can I install Google apps?
**A:** Yes, but you need to flash GApps (Google Apps) package:
1. Download ARM64 GApps
2. Flash via recovery
3. Note: This is a gray area legally

### Q: Does Netflix/Banking app work?
**A:** Many apps requiring SafetyNet/Play Integrity won't work on AOSP without:
- Google services installed
- Passing SafetyNet checks
- This is a common AOSP limitation

## Touch Display Questions

### Q: Does multi-touch work?
**A:** Yes, the ED-HMI3010-101C supports 10-point capacitive touch, and the device tree overlay enables this.

### Q: What if touch coordinates are wrong?
**A:** Adjust in boot config:
```bash
dtoverlay=hmi3010-touch,invx=1,invy=1,swapxy=1
```
See TROUBLESHOOTING.md for details.

### Q: Can I use a stylus?
**A:** Capacitive styluses work. Active/pressure-sensitive styluses need special hardware support.

### Q: How do I calibrate the touchscreen?
**A:** Android auto-calibrates. If needed:
```
Settings > Developer options > Pointer location
```

## Performance Questions

### Q: How fast is Android on Raspberry Pi 5?
**A:** 
- **General use**: Smooth for basic tasks
- **Web browsing**: Good, comparable to budget tablets
- **Video playback**: 1080p works well, 4K may struggle
- **Gaming**: Casual games work, 3D games may be slow
- **Overall**: Suitable for kiosk, development, education

### Q: How do I improve performance?
**A:**
- Use NVMe instead of SD card
- Add active cooling (heatsink + fan)
- Overclock CPU (with adequate cooling)
- Reduce animations in Developer options
- Disable unnecessary services

### Q: What's the boot time?
**A:**
- **First boot**: 2-3 minutes
- **Subsequent boots**: 30-60 seconds
- Slower SD cards increase boot time

## Customization Questions

### Q: Can I change the launcher?
**A:** Yes! Install any Android launcher via APK:
- Nova Launcher
- Lawnchair
- Custom AOSP launchers

### Q: Can I modify system apps before building?
**A:** Yes! Source code is in `~/aosp-rpi5/packages/apps/`. Modify and rebuild.

### Q: Can I add custom kernel modules?
**A:** Yes! Kernel source is in `~/aosp-rpi5/kernel/arpi/linux/`. Build custom modules.

### Q: How do I change boot animation?
**A:** Replace `/system/media/bootanimation.zip` with your custom animation.

### Q: Can I change the device name?
**A:** Edit `device/brcm/rpi5/device.mk` and set:
```makefile
PRODUCT_NAME := MyCustomName
PRODUCT_MODEL := My Raspberry Pi 5
```

## Troubleshooting Questions

### Q: My build failed with "killed" - what happened?
**A:** Out of memory. Solutions:
- Reduce parallel jobs: `make -j4`
- Add swap space
- Close other applications
- Use a machine with more RAM

### Q: Touch doesn't work - what should I check?
**A:** 
1. Display via HDMI works? ✓
2. I2C device detected? `adb shell i2cdetect -y 1`
3. Device tree overlay loaded?
4. See TROUBLESHOOTING.md for detailed steps

### Q: Why is my display the wrong resolution?
**A:** Should auto-detect. If not, manually set in boot config. See TROUBLESHOOTING.md.

### Q: How do I get build logs?
**A:**
```bash
# Build logs
cat ~/aosp-rpi5/out/error.log

# System logs
adb logcat

# Kernel logs
adb shell dmesg
```

## Update Questions

### Q: How do I update the system?
**A:** AOSP doesn't have OTA updates by default. To update:
1. Sync new code: `repo sync`
2. Rebuild: `./build-helper.sh build`
3. Reflash SD card

### Q: Will I lose data when updating?
**A:** Yes, reflashing erases everything. To preserve data:
- Backup `/data` partition before flashing
- Or implement custom OTA updates (advanced)

### Q: How often should I update?
**A:** 
- **Security**: Monthly (Android security patches)
- **Features**: When new AOSP versions release
- **Stability**: Only when needed

## Advanced Questions

### Q: Can I cross-compile from another architecture?
**A:** Yes, but AOSP build system handles cross-compilation automatically. You build on x86_64, it produces ARM64 binaries.

### Q: Can I build for multiple targets?
**A:** Yes! Just change lunch target and rebuild:
```bash
lunch aosp_rpi5-bp1a-userdebug  # Standard
lunch aosp_rpi5_car-bp1a-userdebug  # Automotive
lunch aosp_rpi5_tv-bp1a-userdebug  # TV
```

### Q: How do I add custom HALs?
**A:** 
1. Create HAL in `hardware/your-company/`
2. Add to device makefile
3. Rebuild

### Q: Can I use this commercially?
**A:** AOSP is open-source, but:
- Check individual component licenses
- Some parts are GPL, Apache, etc.
- Google services require licensing
- Consult a lawyer for commercial use

### Q: How do I contribute back?
**A:** 
- AOSP: https://source.android.com/docs/setup/contribute
- Raspberry-Vanilla: https://github.com/raspberry-vanilla/android_local_manifest
- This repo: Open a pull request!

## Still Have Questions?

- **Documentation**: See BUILD_INSTRUCTIONS.md and TROUBLESHOOTING.md
- **Community**: XDA Forums, Raspberry Pi Forums
- **Issues**: Open an issue on GitHub

---

**Can't find your question?** Open an issue and we'll add it to this FAQ!
