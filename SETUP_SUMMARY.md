# AOSP 15 for Raspberry Pi 5 - Complete Setup Summary

## What This Repository Provides

This repository contains **everything you need** to build Android 15 (AOSP) for Raspberry Pi 5 with the ED-HMI3010-101C display. You don't need to search for additional resources or configurations - just clone this repo and run the scripts.

## ✅ What's Included

### 🔧 Automated Setup
- **`setup-aosp.sh`** - One-command setup that:
  - Installs all required dependencies (build tools, Java, etc.)
  - Configures git and repo tool
  - Initializes AOSP repository with Android 15.0.0_r32
  - Downloads Raspberry Pi 5 specific manifests from raspberry-vanilla
  - Optionally syncs ~100GB of AOSP source code
  - Creates ready-to-build environment at `~/aosp-rpi5/`

### 🏗️ Build Helper
- **`build-helper.sh`** - Simplifies the build process:
  - `build` - Complete AOSP build
  - `kernel` - Kernel-only build (faster iteration)
  - `sync` - Update source code
  - `flash /dev/sdX` - Flash image to SD card
  - `clean` / `clobber` - Clean build artifacts
  - `info` - Show build information
  - `help` - All available commands

### 📱 Hardware Support
- **Device Tree Overlay** for ED-HMI3010-101C:
  - 10.1" 1280x800 HDMI display (auto-detected)
  - 10-point capacitive touch via I2C
  - GPIO configuration for touch controller
  - Customizable parameters (invert axes, swap X/Y, etc.)

### 📚 Comprehensive Documentation
1. **QUICKSTART.md** - Get building in 3 steps
2. **BUILD_INSTRUCTIONS.md** - Detailed build guide (7.5KB)
3. **TROUBLESHOOTING.md** - Common issues & solutions (9KB)
4. **FAQ.md** - 50+ frequently asked questions (9KB)
5. **MANIFEST_REFERENCE.md** - What gets downloaded and why
6. **REPOSITORY_STRUCTURE.md** - File organization guide
7. **CONTRIBUTING.md** - How to contribute
8. **device-tree/README.md** - Touch controller configuration

## 🎯 Key Features

✅ **Complete Automation** - Run one script to fetch everything  
✅ **Latest AOSP** - Android 15.0.0_r32 (latest stable release)  
✅ **Raspberry Pi 5 Optimized** - Using raspberry-vanilla project manifests  
✅ **Display Support** - HDMI 1280x800 auto-detected  
✅ **Touch Support** - 10-point multi-touch via device tree overlay  
✅ **Build Tools** - Helper scripts for common operations  
✅ **Documentation** - Comprehensive guides for every scenario  
✅ **Troubleshooting** - Solutions for common issues  
✅ **Open Source** - MIT licensed, community contributions welcome  

## 🚀 Quick Start (3 Steps)

```bash
# 1. Clone and setup (30 min - 2 hours)
git clone https://github.com/JeffMolenaar/AOSP15-RPI5.git
cd AOSP15-RPI5
./setup-aosp.sh

# 2. Build (2-6 hours)
./build-helper.sh build

# 3. Flash to SD card (5-10 minutes)
./build-helper.sh flash /dev/sdX
```

Boot your Raspberry Pi 5 and enjoy Android 15!

## 📋 What Gets Fetched

When you run `./setup-aosp.sh`, here's what happens:

### 1. System Dependencies
Automatically installs via apt:
- Build essentials (gcc, make, ninja)
- Development libraries
- Java OpenJDK 11
- Python and tools
- Device firmware tools

### 2. AOSP Repository Setup
- Downloads repo tool from Google
- Initializes Android 15.0.0_r32 manifest
- Configures local manifests for Raspberry Pi 5

### 3. Raspberry Pi Manifests
Fetches from raspberry-vanilla project:
- **manifest_brcm_rpi.xml** - Adds RPI5 device configs, kernel, HALs, firmware
- **remove_projects.xml** - Removes incompatible AOSP components

### 4. Source Code Sync (Optional)
Downloads ~100GB of source code:
- Android frameworks and system apps
- Raspberry Pi 5 device configuration
- Linux kernel (BCM2712/RPI5)
- Hardware abstraction layers (HALs)
- Broadcom firmware and drivers
- Build tools and toolchains

### Complete Directory Structure

After setup, you'll have:
```
~/aosp-rpi5/              # ~250GB total
├── device/brcm/rpi5/    # RPI5 device configuration
├── kernel/arpi/linux/   # Linux kernel for RPI5
├── hardware/arpi/       # RPI-specific HALs
├── vendor/brcm/rpi/     # Firmware and vendor files
├── frameworks/          # Android frameworks
├── packages/            # System apps
├── build/               # Build system
└── (many more...)
```

## 🖥️ Hardware Specifications

### Host Build Machine (Recommended)
- **OS**: Ubuntu 24.04.3 LTS
- **CPU**: 16-core (8-core minimum)
- **RAM**: 64GB (32GB minimum, 16GB possible with swap)
- **Storage**: 100GB free (SSD/NVMe strongly recommended)
- **Internet**: Fast connection for ~100GB download

### Target Hardware
- **Raspberry Pi 5** (8GB model recommended)
- **Display**: ED-HMI3010-101C
  - 10.1" TFT LCD
  - 1280 x 800 resolution
  - 10-point capacitive touch
  - HDMI connection
  - I2C touch interface
  - 250 cd/m² brightness
- **Storage**: 64GB+ microSD (Class 10 UHS-I minimum)
- **Power**: 5V/3A USB-C power supply

## 📦 Build Output

After successful build, you get:
- **rpi5.img** - Complete flashable SD card image (~4-6GB)
- **boot.img** - Kernel and boot partition
- **system.img** - Android system partition  
- **vendor.img** - Vendor partition with drivers

## 🎓 Learning Resources

This repository is also educational. By examining the files, you'll learn:
- How AOSP is structured
- How to configure builds for custom hardware
- Device tree overlay creation
- Shell scripting best practices
- Android build system (Soong/Make)

## 🤝 What Makes This Different

Compared to other AOSP RPI guides:
1. ✅ **Everything in one place** - No hunting for manifests or configs
2. ✅ **Automated** - Scripts handle the complexity
3. ✅ **Hardware-specific** - Preconfigured for ED-HMI3010-101C
4. ✅ **Well-documented** - 40KB+ of documentation
5. ✅ **Tested** - Build process validated
6. ✅ **Maintained** - Up-to-date with latest AOSP releases
7. ✅ **Community-driven** - Open to contributions

## 🛠️ Customization Options

While configured for ED-HMI3010-101C, you can easily adapt for:
- Different displays (edit device tree overlay)
- Different Raspberry Pi models (change lunch target)
- Android variants (TV, Automotive, standard)
- Custom features (modify device configs)
- Performance tuning (edit build flags)

## 📊 Time and Resource Estimates

| Phase | Time | Disk Space | Notes |
|-------|------|------------|-------|
| Setup | 30m - 2h | 0 → 100GB | Depends on internet speed |
| Download | Included | 100 → 150GB | Source extraction |
| Build | 2 - 6h | 150 → 250GB | Depends on CPU/storage |
| Flash | 5 - 10m | No change | Writes ~5GB to SD |
| First Boot | 2 - 3m | No change | Initial Android setup |

**Total**: 3-9 hours, mostly automated (you can leave it running)

## 🐛 Troubleshooting Quick Links

Common issues are documented:
- **Build fails with OOM**: Reduce parallel jobs, add swap (TROUBLESHOOTING.md)
- **Touch not working**: Check I2C, verify overlay (TROUBLESHOOTING.md)
- **Display wrong resolution**: Boot config tweaks (TROUBLESHOOTING.md)
- **Slow performance**: Use NVMe, add cooling (FAQ.md)
- **Can't flash image**: Check device path, use correct dd command (QUICKSTART.md)

## 🌟 Use Cases

This setup is perfect for:
- **Learning**: Understanding AOSP and Android internals
- **Development**: Custom Android app/feature development
- **Prototyping**: Android-based product prototypes
- **Kiosks**: Interactive display systems
- **Education**: Teaching Android development
- **IoT**: Android-powered IoT devices
- **Experimentation**: Trying custom Android builds

## 📜 License & Attribution

- **This repository**: MIT License (scripts, docs, configs)
- **AOSP**: Various open-source licenses (Apache, GPL, etc.)
- **Raspberry-Vanilla**: See their repository for license
- **Broadcom firmware**: Proprietary (included in vendor)

## 🎯 Success Criteria

You've successfully completed the setup when:
1. ✅ `~/aosp-rpi5/` directory exists with full source
2. ✅ Build completes without errors
3. ✅ `rpi5.img` is created in output directory
4. ✅ Image flashes to SD card successfully
5. ✅ Raspberry Pi 5 boots to Android 15
6. ✅ Display shows 1280x800 resolution
7. ✅ Touch input works correctly

## 🔄 Updates and Maintenance

Stay current:
```bash
# Update this repository
git pull origin main

# Update AOSP sources
./build-helper.sh sync

# Rebuild
./build-helper.sh build
```

## 🌐 Community

- **Issues**: Report bugs or request features on GitHub
- **Discussions**: Ask questions in GitHub Discussions
- **Contributions**: See CONTRIBUTING.md
- **XDA Forums**: Broader Raspberry Pi Android community
- **Raspberry Pi Forums**: Hardware-specific questions

## 💡 Pro Tips

1. **Use SSD**: Dramatically faster builds (4x+)
2. **Enable ccache**: Speeds up rebuilds
3. **NVMe boot**: Much faster than SD card
4. **Test incrementally**: Build kernel first, then full build
5. **Save images**: Keep known-good builds
6. **Document changes**: Track your customizations
7. **Check logs**: Always check logs when issues occur

## 🎉 Ready to Build?

Everything is set up and ready to go. Just run:
```bash
./setup-aosp.sh
```

Then grab some coffee ☕ while AOSP downloads and builds!

---

## Summary of Repository Contents

```
AOSP15-RPI5/
├── setup-aosp.sh                 # Automated setup script ⭐
├── build-helper.sh               # Build management script ⭐
│
├── QUICKSTART.md                 # 3-step quick start
├── BUILD_INSTRUCTIONS.md         # Detailed instructions
├── TROUBLESHOOTING.md            # Problem solving
├── FAQ.md                        # Common questions
├── MANIFEST_REFERENCE.md         # What gets downloaded
├── REPOSITORY_STRUCTURE.md       # File organization
├── CONTRIBUTING.md               # Contribution guide
├── README.md                     # Main overview
├── LICENSE                       # MIT License
│
└── device-tree/
    ├── hmi3010-touch-overlay.dts # Touch controller config ⭐
    └── README.md                 # DT documentation
```

⭐ = Essential files

---

**You now have everything needed to build Android 15 for Raspberry Pi 5 with the ED-HMI3010-101C display. Happy building! 🚀**
