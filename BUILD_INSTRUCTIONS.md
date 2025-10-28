# AOSP 15 Build Instructions for Raspberry Pi 5
## ED-HMI3010-101C Display (10.1" 1280x800 Capacitive Touch)

This guide will help you build Android 15 (AOSP) for Raspberry Pi 5 with the ED-HMI3010-101C display.

## System Requirements

### Host Machine
- **OS**: Ubuntu 24.04.3 LTS (recommended) or similar Linux distribution
- **CPU**: 8-core minimum (16-core recommended)
- **RAM**: 32GB minimum (64GB recommended for faster builds)
- **Storage**: 100GB+ free space (SSD/NVMe strongly recommended)
- **Internet**: Fast connection for downloading ~100GB of source code

### Target Hardware
- **Raspberry Pi 5**: 8GB model recommended
- **Display**: ED-HMI3010-101C (10.1" 1280x800)
- **Storage**: microSD card 64GB+ (Class 10 UHS-I or better)
- **Power**: USB-C power supply 5V/3A minimum

## Display Specifications

The ED-HMI3010-101C features:
- **Resolution**: 1280 x 800 pixels
- **Touch**: 10-point capacitive multi-touch (I2C interface)
- **Connection**: HDMI for display, I2C for touch
- **Brightness**: 250 cd/m²
- **Viewing Angle**: 80° (all directions)

## Step-by-Step Build Process

### 1. Initial Setup

Run the automated setup script to prepare your build environment:

```bash
./setup-aosp.sh
```

This script will:
- Install all required dependencies
- Set up the repo tool
- Initialize the AOSP repository
- Download Raspberry Pi 5 specific manifests
- Optionally sync the source code (can take several hours)

Alternatively, you can perform these steps manually (see Manual Setup section below).

### 2. Build Configuration

After setup completes, navigate to the AOSP directory:

```bash
cd ~/aosp-rpi5
source build/envsetup.sh
```

Choose your build target:

```bash
# Standard Android build (recommended)
lunch aosp_rpi5-bp1a-userdebug

# Alternative targets:
# lunch aosp_rpi5_car-bp1a-userdebug  # Android Automotive
# lunch aosp_rpi5_tv-bp1a-userdebug   # Android TV
```

### 3. Apply Display Configuration

The ED-HMI3010-101C display connects via HDMI and should work automatically for video output. The touch interface uses I2C and requires device tree configuration.

The device tree overlay for the touch controller has been prepared in `device-tree/hmi3010-touch-overlay.dts`. This will be automatically included in the build process.

### 4. Build AOSP

Start the build process:

```bash
make -j$(nproc)
```

Build time depends on your system:
- 16-core with SSD: ~2-4 hours
- 8-core with HDD: ~6-10 hours

### 5. Create Flashable Image

After the build completes successfully, create the SD card image:

```bash
./rpi5-mkimg.sh
```

This creates a flashable image in the `out/` directory.

### 6. Flash to SD Card

**WARNING**: This will erase all data on the target SD card!

On Linux:
```bash
# Find your SD card device (e.g., /dev/sdX)
lsblk

# Flash the image (replace sdX with your SD card device)
sudo dd if=out/target/product/rpi5/rpi5.img of=/dev/sdX bs=4M status=progress
sync
```

On Windows, use Rufus or Win32 Disk Imager.

On macOS:
```bash
# Find your SD card device
diskutil list

# Unmount the SD card (replace diskN with your device)
diskutil unmountDisk /dev/diskN

# Flash the image
sudo dd if=out/target/product/rpi5/rpi5.img of=/dev/rdiskN bs=4m
sync
```

### 7. Boot Raspberry Pi 5

1. Insert the flashed SD card into your Raspberry Pi 5
2. Connect the ED-HMI3010-101C display via HDMI
3. Connect power and wait for Android to boot (first boot takes 2-3 minutes)

The display should show the Android boot animation, followed by the setup screen. Touch input should work automatically.

## Display and Touch Configuration

### HDMI Display
The HDMI output works out-of-the-box. The system auto-detects the 1280x800 resolution.

### Touch Input
The capacitive touch controller communicates via I2C. The device tree overlay enables:
- 10-point multi-touch support
- I2C communication on the appropriate pins
- Proper touch event mapping

### Troubleshooting Touch

If touch doesn't work:

1. Check touch controller detection:
```bash
adb shell
dmesg | grep -i touch
dmesg | grep -i i2c
```

2. Verify input device:
```bash
adb shell getevent
# Touch the screen - you should see events
```

3. Check I2C devices:
```bash
adb shell
i2cdetect -y 1
```

## Manual Setup (Alternative to setup-aosp.sh)

If you prefer to set up manually:

### Install Dependencies
```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y git gnupg flex bison build-essential zip curl zlib1g-dev \
    gcc-multilib g++-multilib libc6-dev-i386 libncurses6 libncurses-dev x11proto-core-dev \
    libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig \
    bc coreutils dosfstools e2fsprogs fdisk kpartx mtools ninja-build pkg-config python3-pip rsync \
    openjdk-11-jdk
```

### Install Repo Tool
```bash
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH
```

### Configure Git
```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --global color.ui auto
```

### Initialize Repository
```bash
mkdir aosp-rpi5 && cd aosp-rpi5
repo init -u https://android.googlesource.com/platform/manifest -b android-15.0.0_r32 --depth=1
```

### Add Raspberry Pi Manifests
```bash
curl -o .repo/local_manifests/manifest_brcm_rpi.xml -L \
    https://raw.githubusercontent.com/raspberry-vanilla/android_local_manifest/android-15.0/manifest_brcm_rpi.xml --create-dirs

curl -o .repo/local_manifests/remove_projects.xml -L \
    https://raw.githubusercontent.com/raspberry-vanilla/android_local_manifest/android-15.0/remove_projects.xml
```

### Sync Source Code
```bash
repo sync -j$(nproc) -c --no-tags --no-clone-bundle --optimized-fetch --prune
```

## Customization Options

### Build Variants
- **userdebug**: Development build with root access (recommended for testing)
- **user**: Production build (more secure, no root)
- **eng**: Engineering build (full debug features)

### Performance Tuning
Edit `device/brcm/rpi5/device.mk` to customize:
- Memory settings
- Display density
- Graphics acceleration
- Audio configuration

## Known Issues and Solutions

### Issue: Build Fails with "Out of Memory"
**Solution**: Reduce parallel jobs: `make -j4` instead of `make -j$(nproc)`

### Issue: Display Shows But Touch Doesn't Work
**Solution**: Check device tree overlay is properly applied. Verify in kernel logs.

### Issue: Display Resolution Incorrect
**Solution**: HDMI should auto-detect. If not, add to boot config:
```
hdmi_group=2
hdmi_mode=87
hdmi_cvt=1280 800 60
```

## Additional Resources

- **AOSP Official**: https://source.android.com/
- **Raspberry-Vanilla Project**: https://github.com/raspberry-vanilla/android_local_manifest
- **KonstaKANG AOSP Images**: https://konstakang.com/devices/rpi5/AOSP15/
- **ED-HMI3010-101C Datasheet**: https://edatec.cn/docs/assets/hmi3010-101c/
- **XDA Developers Forum**: https://xdaforums.com/t/rpi5-aosp-15

## Support

For build issues:
1. Check the build logs in `out/error.log`
2. Search for the error on XDA Forums or Stack Overflow
3. Ensure you're using the latest manifest version

For hardware issues:
1. Verify all connections
2. Test the display with Raspberry Pi OS first
3. Check power supply is adequate (5V/3A minimum)

## License

AOSP is released under various open source licenses. See individual project components for details.
Raspberry Pi specific components follow their respective licenses.
