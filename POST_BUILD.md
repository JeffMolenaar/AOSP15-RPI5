# Post-Build Instructions
## What to do after your AOSP build completes

Congratulations! Your AOSP build has completed successfully. Here's what to do next to get Android running on your Raspberry Pi 5.

## Quick Summary

After running `make -j$(nproc)` or `./build-helper.sh build`, you need to:

1. ✅ **Create a flashable SD card image** (if not done automatically)
2. ✅ **Flash the image to an SD card**
3. ✅ **Boot your Raspberry Pi 5**

## Step 1: Verify Build Completion

Your build is complete when you see:
```
#### build completed successfully (HH:MM:SS (HH:MM)) ####
```

The build outputs are located in:
```bash
~/aosp-rpi5/out/target/product/rpi5/
```

## Step 2: Create Flashable Image

The build process creates individual partition images that need to be combined into a single bootable SD card image.

### If you used `./build-helper.sh build`:
The image was automatically created. Skip to Step 3.

### If you built manually with `make -j$(nproc)`:

You need to create the image:

```bash
cd ~/aosp-rpi5
./rpi5-mkimg.sh
```

This script combines all the partition images into:
```
~/aosp-rpi5/out/target/product/rpi5/rpi5.img
```

**If rpi5-mkimg.sh doesn't exist**, you have two options:

#### Option A: Use the repository's flash helper
```bash
cd /path/to/AOSP15-RPI5
./build-helper.sh flash /dev/sdX
```
This will handle the image automatically.

#### Option B: Manual partition flashing
The individual partition images are in `~/aosp-rpi5/out/target/product/rpi5/`:
- `boot.img` - Kernel and boot files
- `system.img` - Android system partition
- `vendor.img` - Vendor partition
- `userdata.img` - User data partition

You would need to manually partition and flash these to an SD card (advanced - not recommended for beginners).

## Step 3: Flash to SD Card

**⚠️ WARNING**: This will completely erase all data on your SD card!

### Find Your SD Card Device

Insert your SD card and identify it:
```bash
lsblk
```

Look for your SD card (typically `/dev/sdb`, `/dev/sdc`, or `/dev/mmcblk0`). 

**Important**: Make sure you identify the correct device - flashing the wrong device can destroy your data!

### Flash the Image

#### Method A: Using build-helper.sh (Recommended)
```bash
cd /path/to/AOSP15-RPI5
./build-helper.sh flash /dev/sdX
```
Replace `/dev/sdX` with your SD card device.

The script will:
- Verify the image exists
- Confirm the device
- Flash the image safely
- Sync to ensure all data is written

#### Method B: Manual flashing with dd
```bash
sudo dd if=~/aosp-rpi5/out/target/product/rpi5/rpi5.img of=/dev/sdX bs=4M status=progress oflag=sync
sync
```

**Explanation**:
- `if=` - Input file (your built image)
- `of=` - Output file (your SD card device)
- `bs=4M` - Block size (4MB for faster writing)
- `status=progress` - Show progress
- `oflag=sync` - Ensure data is written immediately

**Time estimate**: 5-10 minutes depending on SD card speed

### Safely Remove SD Card

After flashing completes:
```bash
sync  # Ensure all data is written
sudo eject /dev/sdX  # Or safely remove via GUI
```

## Step 4: Boot Raspberry Pi 5

### Hardware Setup

1. **Remove SD card from your computer**
2. **Insert SD card into Raspberry Pi 5**
3. **Connect ED-HMI3010-101C display via HDMI**
4. **Connect power supply** (5V/3A minimum)

### First Boot

1. Power on the Raspberry Pi 5
2. You should see the Raspberry Pi boot screen
3. Android boot animation will appear
4. **First boot takes 2-3 minutes** (subsequent boots are faster)
5. Android setup wizard will appear

### Expected Boot Sequence

```
Raspberry Pi Boot Screen (rainbow/logo)
    ↓
Kernel Loading
    ↓
Android Boot Animation
    ↓
Android Setup Wizard
```

## Step 5: Complete Android Setup

1. **Language & Region**: Select your preferences
2. **WiFi**: Connect to your network (recommended)
3. **Date & Time**: Verify/set correctly
4. **Accessibility**: Configure if needed
5. **Skip Google Sign-in** (AOSP doesn't include Google services)

## Troubleshooting

### Issue: No display output
- ✓ Check HDMI cable connection
- ✓ Verify display is powered on
- ✓ Try a different HDMI cable
- ✓ Test the display with Raspberry Pi OS first

### Issue: Boot loops or crashes
- ✓ Verify you flashed the correct image for RPI5
- ✓ Try reflashing the SD card
- ✓ Check power supply is adequate (5V/3A minimum)
- ✓ Test with a different SD card

### Issue: Touch screen doesn't work
- ✓ Display should show video via HDMI
- ✓ Touch uses I2C - check kernel logs: `adb shell dmesg | grep -i touch`
- ✓ Verify device tree overlay is loaded
- ✓ See TROUBLESHOOTING.md for detailed steps

### Issue: Image file not found
If `rpi5.img` doesn't exist:
```bash
# Check what was built
ls ~/aosp-rpi5/out/target/product/rpi5/

# If you see boot.img, system.img, etc., the build succeeded
# but image creation failed. Try running:
cd ~/aosp-rpi5
./rpi5-mkimg.sh
```

## What's Next?

After successful boot:

### 1. Enable Developer Options
```
Settings > About tablet > Tap "Build number" 7 times
Settings > System > Developer options > Enable USB debugging
```

### 2. Connect via ADB
```bash
# USB connection
adb devices

# Or network connection (get IP from Settings > Network)
adb connect <raspberry-pi-ip>:5555
```

### 3. Install Apps
AOSP doesn't include Google Play Store. Use:
- **F-Droid**: Open-source app store
- **Aurora Store**: Google Play proxy  
- **APK files**: `adb install app.apk`

### 4. Customize
See [CUSTOMIZATION_GUIDE.md](CUSTOMIZATION_GUIDE.md) for:
- Portrait mode orientation
- Auto-start apps (kiosk mode)
- Custom boot animation
- System modifications

## Common Commands

### Check device status
```bash
adb devices
adb shell getprop ro.build.version.release  # Android version
adb shell getprop ro.build.id  # Build ID
```

### Install APK
```bash
adb install myapp.apk
```

### Access shell
```bash
adb shell
su  # Root access (userdebug builds)
```

### View logs
```bash
adb logcat  # System logs
adb shell dmesg  # Kernel logs
```

### Reboot
```bash
adb reboot
```

## Build Output Reference

After a successful build, you'll have these files in `~/aosp-rpi5/out/target/product/rpi5/`:

| File | Description | Size (approx) |
|------|-------------|---------------|
| `rpi5.img` | Complete flashable image | 4-6 GB |
| `boot.img` | Kernel and ramdisk | ~50 MB |
| `system.img` | Android system partition | ~1.5 GB |
| `vendor.img` | Vendor partition | ~500 MB |
| `userdata.img` | User data partition | ~1 GB |
| `ramdisk.img` | Initial ramdisk | ~5 MB |
| `kernel` | Linux kernel binary | ~30 MB |

## Additional Resources

- **[BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md)** - Complete build guide
- **[QUICKSTART.md](QUICKSTART.md)** - Fast-track guide
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Detailed troubleshooting
- **[FAQ.md](FAQ.md)** - Frequently asked questions
- **[CUSTOMIZATION_GUIDE.md](CUSTOMIZATION_GUIDE.md)** - Customization options

## Need Help?

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
2. Review [FAQ.md](FAQ.md) for frequently asked questions
3. Open an issue on GitHub with:
   - Your build command
   - Error messages (if any)
   - System information
   - Steps you've tried

---

**Congratulations on building Android 15 from source! 🎉**

Enjoy your custom AOSP installation on Raspberry Pi 5!
