# AOSP 15 for Raspberry Pi 5
## Complete Build Environment for ED-HMI3010-101C Display

This repository provides everything you need to build Android 15 (AOSP) for the Raspberry Pi 5 with the **ED-HMI3010-101C** 10.1" touchscreen display (1280x800, 10-point capacitive touch).

### 🚀 Quick Start

**Just want to build? Start here:**

```bash
git clone https://github.com/JeffMolenaar/AOSP15-RPI5.git
cd AOSP15-RPI5
./setup-aosp.sh
./build-helper.sh build
```

See [**QUICKSTART.md**](QUICKSTART.md) for the streamlined guide.

### 📋 What's Included

- **Automated Setup Script** (`setup-aosp.sh`) - Downloads and configures everything
- **Build Helper** (`build-helper.sh`) - Simplifies building, flashing, and maintenance
- **Device Tree Overlay** (`device-tree/`) - Touch controller configuration for ED-HMI3010-101C
- **Easy Customization** (`customization/`) - Portrait mode, auto-start apps, custom boot animation
- **Comprehensive Documentation** - Step-by-step build instructions and troubleshooting

### 🖥️ Display Specifications

**ED-HMI3010-101C**:
- 10.1" TFT LCD
- 1280 x 800 resolution
- 10-point capacitive multi-touch
- HDMI display output
- I2C touch interface
- 250 cd/m² brightness
- Industrial grade build quality

### 💻 System Requirements

**Host Machine**:
- Ubuntu 24.04.3 LTS or similar
- 8+ CPU cores (16 recommended)
- 32GB+ RAM (64GB recommended)
- 100GB+ free storage (SSD preferred)
- Fast internet connection

**Target Hardware**:
- Raspberry Pi 5 (8GB recommended)
- ED-HMI3010-101C display
- 64GB+ microSD card (Class 10 UHS-I)
- 5V/3A USB-C power supply

### 📚 Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Fast-track build guide (start here!)
- **[BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md)** - Detailed build instructions, customization, and troubleshooting
- **[customization/README.md](customization/README.md)** - Easy customization: portrait mode, auto-start apps, boot animation
- **[device-tree/README.md](device-tree/README.md)** - Touch controller configuration details

### 🛠️ Build Process Overview

1. **Setup** (30 min - 2 hours): Run `./setup-aosp.sh` to install dependencies and download AOSP sources
2. **Build** (2-6 hours): Run `./build-helper.sh build` to compile Android 15
3. **Flash** (5-10 minutes): Run `./build-helper.sh flash /dev/sdX` to write to SD card
4. **Boot** (2-3 minutes): Insert SD card and power on Raspberry Pi 5

### 🎯 Features

✅ **Automated Setup** - One command to fetch everything  
✅ **AOSP 15.0.0_r32** - Latest Android 15 release  
✅ **Raspberry Pi 5 Optimized** - Uses raspberry-vanilla manifests  
✅ **Touch Support** - 10-point capacitive touch via device tree overlay  
✅ **HDMI Display** - Auto-detected 1280x800 output  
✅ **Easy Customization** - Portrait mode, auto-start apps, custom boot animation  
✅ **Helper Scripts** - Simplified build, flash, and maintenance  
✅ **Complete Documentation** - From setup to troubleshooting  

### 🔧 Helper Commands

```bash
./build-helper.sh build      # Build complete AOSP
./build-helper.sh kernel     # Build kernel only
./build-helper.sh sync       # Update source code
./build-helper.sh flash /dev/sdX  # Flash to SD card
./build-helper.sh info       # Show build information
./build-helper.sh help       # Show all commands
```

### 🎨 Easy Customization

**Want to customize your build?** We've made it easy:

#### 📱 Portrait Mode (Vertical Orientation)
Set the device to use portrait mode by default instead of landscape.
```bash
# See customization/display/README.md for details
```

#### 🚀 Auto-Start Your App on Boot
Install your APK and make it launch automatically when the device boots - perfect for kiosk mode!
```bash
# See customization/auto-start-app/README.md for details
```

#### 🎭 Custom Boot Animation & Splash Screen
Add your company logo and branding to the boot animation.
```bash
# See customization/boot-animation/README.md for details
cd customization/boot-animation
./create-bootanimation.sh your-logo.png
```

**📖 [Full Customization Guide](customization/README.md)** - Detailed instructions for all customization options

### 🐛 Troubleshooting

**Build Fails**:
- Check `~/aosp-rpi5/out/error.log`
- Try reducing parallel jobs: `make -j4`
- Ensure 100GB+ free space

**Touch Not Working**:
- Verify I2C connection in kernel logs
- Check device tree overlay is applied
- See BUILD_INSTRUCTIONS.md for detailed debugging

**Display Issues**:
- HDMI should auto-detect resolution
- Test display with Raspberry Pi OS first
- Check HDMI cable and power supply

### 📖 Additional Resources

- **AOSP Official**: https://source.android.com/
- **Raspberry-Vanilla**: https://github.com/raspberry-vanilla/android_local_manifest
- **KonstaKANG Builds**: https://konstakang.com/devices/rpi5/AOSP15/
- **EDATEC Documentation**: https://edatec.cn/docs/
- **XDA Forums**: https://xdaforums.com/

### 🤝 Contributing

Contributions are welcome! Whether it's:
- Bug fixes
- Documentation improvements
- Hardware testing reports
- Build optimizations

### 📄 License

AOSP is released under various open source licenses. See individual component licenses for details.
This repository's scripts and documentation are provided as-is for educational and development purposes.

### ⚡ Quick Links

- [Quick Start Guide](QUICKSTART.md) - Get building fast
- [Detailed Instructions](BUILD_INSTRUCTIONS.md) - Complete guide
- [Customization Guide](customization/README.md) - Portrait mode, auto-start apps, boot animation
- [Device Tree Info](device-tree/README.md) - Touch configuration
- [Setup Script](setup-aosp.sh) - Automated setup
- [Build Helper](build-helper.sh) - Build commands

---

**Ready to build your own Android OS? Start with [QUICKSTART.md](QUICKSTART.md)!** 🎉-0000
