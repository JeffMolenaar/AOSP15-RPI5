# Troubleshooting Guide

Common issues and solutions for building and running AOSP 15 on Raspberry Pi 5 with ED-HMI3010-101C display.

## Table of Contents
- [Build Issues](#build-issues)
- [Display Issues](#display-issues)
- [Touch Issues](#touch-issues)
- [Boot Issues](#boot-issues)
- [Performance Issues](#performance-issues)
- [General Tips](#general-tips)

## Build Issues

### Error: Out of Memory During Build

**Symptoms**: Build crashes with "killed" or "out of memory" errors

**Solutions**:
1. Reduce parallel jobs:
   ```bash
   make -j4  # Instead of -j$(nproc)
   ```

2. Add swap space:
   ```bash
   sudo fallocate -l 16G /swapfile
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

3. Close other applications during build

4. Use a machine with more RAM or upgrade existing RAM

### Error: Disk Space Issues

**Symptoms**: "No space left on device" errors

**Solutions**:
1. Check available space:
   ```bash
   df -h
   ```

2. Clean build artifacts:
   ```bash
   ./build-helper.sh clean
   ```

3. Remove old builds:
   ```bash
   rm -rf ~/aosp-rpi5/out
   ```

4. Use ccache efficiently:
   ```bash
   export CCACHE_DIR=~/.ccache
   ccache -M 50G  # Limit cache size
   ```

### Error: Missing Dependencies

**Symptoms**: Build fails with missing library or tool errors

**Solution**: Reinstall dependencies:
```bash
sudo apt-get update
sudo apt-get install -y git-core gnupg flex bison build-essential zip curl zlib1g-dev \
    gcc-multilib g++-multilib libc6-dev-i386 libncurses5 lib32ncurses5-dev x11proto-core-dev \
    libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig \
    bc coreutils dosfstools e2fsprogs fdisk kpartx mtools ninja-build pkg-config python3-pip rsync \
    openjdk-11-jdk
```

### Error: Java Version Issues

**Symptoms**: "Unsupported Java version" or Java-related errors

**Solution**:
```bash
# Install OpenJDK 11
sudo apt-get install openjdk-11-jdk

# Set as default
sudo update-alternatives --config java
sudo update-alternatives --config javac

# Verify
java -version  # Should show version 11
```

### Error: repo sync Failures

**Symptoms**: Sync fails or hangs

**Solutions**:
1. Resume sync:
   ```bash
   repo sync -j4  # Use fewer jobs
   ```

2. Sync specific project:
   ```bash
   repo sync --force-sync path/to/project
   ```

3. Reset specific project:
   ```bash
   cd path/to/project
   git reset --hard
   git clean -fd
   cd -
   repo sync path/to/project
   ```

## Display Issues

### No Display Output

**Symptoms**: Black screen, no video output

**Checklist**:
1. ✓ HDMI cable properly connected
2. ✓ Display powered on
3. ✓ Display set to correct HDMI input
4. ✓ Raspberry Pi power supply adequate (5V/3A)

**Solutions**:
1. Test display with Raspberry Pi OS to verify hardware
2. Check boot messages via serial console
3. Try different HDMI cable
4. Verify display works at 1280x800 on another device

### Wrong Resolution

**Symptoms**: Display shows but resolution is incorrect

**Solution**: Boot config should auto-detect, but if not:
```bash
# Mount boot partition
# Edit config.txt (or cmdline.txt depending on setup)
# Add:
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 800 60 6 0 0 0
```

### Display Rotated or Flipped

**Solution**: Add to boot config:
```bash
# Rotate 90 degrees
display_rotate=1

# Rotate 180 degrees  
display_rotate=2

# Rotate 270 degrees
display_rotate=3

# Flip horizontally
display_hdmi_rotate=0x10000

# Flip vertically
display_hdmi_rotate=0x20000
```

## Touch Issues

### Touch Not Working

**Symptoms**: Display works but touch input doesn't register

**Debugging Steps**:

1. Check if touch controller is detected:
   ```bash
   adb shell
   dmesg | grep -i touch
   dmesg | grep -i ft5
   dmesg | grep -i edt
   ```

2. Verify I2C device:
   ```bash
   adb shell
   i2cdetect -y 1
   # Should show device at address 0x38
   ```

3. Check input devices:
   ```bash
   adb shell getevent
   # Touch screen - should see events when touching
   ```

4. Verify device tree overlay:
   ```bash
   adb shell
   ls -l /sys/firmware/devicetree/base/soc/i2c*/touchscreen*
   ```

**Solutions**:

1. Ensure device tree overlay is compiled and loaded:
   ```bash
   # Check if overlay is in boot partition
   ls /boot/overlays/hmi3010-touch.dtbo
   
   # Verify it's enabled in config.txt
   grep hmi3010 /boot/config.txt
   ```

2. Manually enable I2C:
   ```bash
   # Add to config.txt
   dtparam=i2c_arm=on
   ```

3. Check GPIO connections (hardware issue)

### Touch Inverted or Swapped

**Symptoms**: Touch works but coordinates are wrong

**Solution**: Edit device tree parameters in `/boot/config.txt`:
```bash
# Invert X axis
dtoverlay=hmi3010-touch,invx=1

# Invert Y axis
dtoverlay=hmi3010-touch,invy=1

# Swap X and Y
dtoverlay=hmi3010-touch,swapxy=1

# Combine parameters
dtoverlay=hmi3010-touch,invx=1,invy=1,swapxy=1
```

### Touch Sensitivity Issues

**Solution**: Adjust in Android settings:
```
Settings > System > Developer options > Pointer location
Settings > Accessibility > Touch & hold delay
```

## Boot Issues

### Won't Boot / Blank Screen

**Checklist**:
1. ✓ SD card properly flashed
2. ✓ SD card not corrupted
3. ✓ Power supply adequate (5V/3A minimum)
4. ✓ All connections secure

**Solutions**:

1. Verify image integrity:
   ```bash
   md5sum rpi5.img
   ```

2. Re-flash SD card:
   ```bash
   ./build-helper.sh flash /dev/sdX
   ```

3. Test SD card on another device

4. Use serial console to see boot messages

### Boot Loops

**Symptoms**: Raspberry Pi boots but crashes and reboots repeatedly

**Solutions**:

1. Check kernel panic messages via serial console

2. Verify you're using RPI5-specific build:
   ```bash
   # Should be rpi5, not rpi4
   lunch aosp_rpi5-bp1a-userdebug
   ```

3. Ensure firmware is compatible

4. Re-sync and rebuild:
   ```bash
   ./build-helper.sh sync
   ./build-helper.sh clobber
   ./build-helper.sh build
   ```

### Slow Boot

**Symptoms**: Boot takes >5 minutes

**Solutions**:
1. First boot always takes longer (2-3 minutes is normal)
2. Use faster SD card (UHS-I Class 10 minimum)
3. Check for SD card errors
4. Consider using NVMe boot instead of SD

## Performance Issues

### Slow Performance

**Solutions**:

1. Ensure using 8GB Raspberry Pi 5 model

2. Check temperature:
   ```bash
   adb shell cat /sys/class/thermal/thermal_zone*/temp
   ```

3. Add heatsink/fan if throttling

4. Use faster storage (NVMe > SD Card)

5. Disable unnecessary services

### Video Playback Issues

**Solutions**:
1. Ensure hardware video decoding is enabled
2. Update firmware
3. Use supported codecs (H.264, VP8)

## General Tips

### Enable ADB Over USB

```bash
# On host machine
adb devices

# Enable in Android
Settings > About > Tap "Build number" 7 times
Settings > Developer options > Enable USB debugging
```

### Enable ADB Over Network

```bash
# On Android (via terminal or ADB)
setprop service.adb.tcp.port 5555
stop adbd
start adbd

# On host
adb connect <rpi-ip-address>:5555
```

### Collect Logs

**Boot logs**:
```bash
adb shell dmesg > boot.log
```

**System logs**:
```bash
adb logcat -d > logcat.log
```

**Kernel logs**:
```bash
adb shell cat /proc/kmsg > kmsg.log
```

### Factory Reset

```bash
# Via ADB
adb shell recovery --wipe_data

# Or via recovery mode
# Hold button during boot (if configured)
```

### Common ADB Commands

```bash
# Reboot
adb reboot

# Reboot to recovery
adb reboot recovery

# Reboot to bootloader
adb reboot bootloader

# Install APK
adb install app.apk

# Push file
adb push local_file /sdcard/

# Pull file
adb pull /sdcard/remote_file

# Shell access
adb shell
```

## Getting Help

### Check Logs First
Always check:
1. Build logs: `~/aosp-rpi5/out/error.log`
2. Kernel logs: `adb shell dmesg`
3. System logs: `adb logcat`

### Useful Resources
- XDA Forums: https://xdaforums.com/
- Raspberry Pi Forums: https://forums.raspberrypi.com/
- AOSP Issue Tracker: https://issuetracker.google.com/
- Stack Overflow: https://stackoverflow.com/

### Report Issues

When reporting issues, include:
- Host system info (OS, RAM, CPU)
- Build command used
- Error messages (full text)
- Log files
- Steps to reproduce

## Hardware Testing

### Test Display Separately
Boot Raspberry Pi OS to verify:
- Display output works
- Touch input works
- Resolution is correct

This isolates AOSP-specific issues from hardware issues.

### Test SD Card
```bash
# Check for bad sectors
sudo badblocks -v /dev/sdX

# Test read speed
sudo hdparm -t /dev/sdX

# Test write speed
dd if=/dev/zero of=/dev/sdX bs=4M count=100 status=progress
```

### Verify Power Supply
Use a USB multimeter to verify:
- Voltage: 5V ±0.25V
- Current: Capable of 3A minimum
- No voltage drops under load

## Still Having Issues?

1. **Re-read documentation**: Often the answer is in BUILD_INSTRUCTIONS.md
2. **Search forums**: Someone likely had the same issue
3. **Test with known-good image**: Try KonstaKANG's prebuilt images to verify hardware
4. **Simplify**: Remove customizations and test with stock build
5. **Ask for help**: Post on forums with detailed information

---

**Most issues are due to**:
- Insufficient RAM during build
- Wrong Java version
- Inadequate power supply
- Bad/slow SD card
- Missing dependencies

Check these first! 🔍
