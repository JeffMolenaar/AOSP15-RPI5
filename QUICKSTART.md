# Quick Start Guide - AOSP 15 for Raspberry Pi 5

This is a streamlined guide to get you building AOSP 15 for your Raspberry Pi 5 with the ED-HMI3010-101C display as quickly as possible.

## Prerequisites

- Ubuntu 24.04.3 LTS (or similar) with 100GB+ free space
- Fast internet connection
- 4-8 hours for download and build

## Quick Build Process

### Step 1: Setup (30 min - 2 hours depending on internet speed)

```bash
git clone https://github.com/JeffMolenaar/AOSP15-RPI5.git
cd AOSP15-RPI5
./setup-aosp.sh
```

When prompted:
- Enter your name and email for git
- Type 'y' to sync source code
- Go grab coffee ☕ - this downloads ~100GB

### Step 2: Build (2-6 hours depending on hardware)

```bash
./build-helper.sh build
```

This will:
- Configure the build environment
- Compile AOSP for Raspberry Pi 5
- Create a flashable SD card image

### Step 3: Flash to SD Card

Find your SD card device:
```bash
lsblk
# Look for your SD card, typically /dev/sdb or /dev/sdc
```

Flash the image:
```bash
./build-helper.sh flash /dev/sdX  # Replace X with your device letter
```

**WARNING**: Double-check the device! This will erase everything on it.

### Step 4: Boot

1. Insert SD card into Raspberry Pi 5
2. Connect ED-HMI3010-101C display via HDMI
3. Connect power
4. Wait 2-3 minutes for first boot

That's it! Android 15 should now be running on your Raspberry Pi 5.

## Troubleshooting Quick Fixes

### Build fails with out of memory
```bash
# Reduce parallel jobs
cd ~/aosp-rpi5
source build/envsetup.sh
lunch aosp_rpi5-bp1a-userdebug
make -j4  # Use 4 jobs instead of all cores
```

### Touch screen not working
The device tree overlay should be automatically included. If touch doesn't work:
1. Verify I2C connection
2. Check boot logs: `adb shell dmesg | grep -i touch`
3. See detailed troubleshooting in BUILD_INSTRUCTIONS.md

### Display shows but low resolution
HDMI should auto-detect 1280x800. If not:
1. Check HDMI cable
2. Power cycle the display
3. Check boot config settings

## What Gets Built

The setup script creates `~/aosp-rpi5/` with:
- Complete Android 15 source code (~100GB)
- Raspberry Pi 5 specific configurations
- Device tree overlay for ED-HMI3010-101C touch
- Build tools and dependencies

The build process creates `~/aosp-rpi5/out/` with:
- Compiled system images
- Kernel and boot files
- Flashable SD card image (~4-6GB)

## Helper Commands

```bash
# Show build info
./build-helper.sh info

# Update source code
./build-helper.sh sync

# Rebuild after changes
./build-helper.sh build

# Build kernel only (faster for testing)
./build-helper.sh kernel

# Clean build outputs
./build-helper.sh clean

# Show all commands
./build-helper.sh help
```

## Next Steps

After successful boot:
- Complete Android setup wizard
- Connect to WiFi
- Install apps via ADB or alternative app stores
- Customize system settings

## Need More Details?

See **BUILD_INSTRUCTIONS.md** for:
- Detailed system requirements
- Manual setup instructions
- Customization options
- Comprehensive troubleshooting
- Display specifications

## Hardware Connections

```
Raspberry Pi 5
    │
    ├─ HDMI ─────> ED-HMI3010-101C Display
    ├─ I2C  ─────> Touch Controller (internal)
    ├─ Power ────> 5V/3A USB-C
    └─ SD Card ──> Flashed Android image
```

## Support

- Build issues: Check out/error.log
- Hardware issues: Test display with Raspberry Pi OS first
- Questions: See BUILD_INSTRUCTIONS.md or XDA Forums

## Time Expectations

- Setup + Download: 30 min - 2 hours
- Build: 2-6 hours (depends on CPU/storage)
- Flash: 5-10 minutes
- First boot: 2-3 minutes

Total: 3-9 hours (mostly automated)

---

**Happy Building! 🚀**
