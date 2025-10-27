# AOSP Manifest Reference

This document explains the manifests used to fetch AOSP sources for Raspberry Pi 5.

## Primary Manifest

**Source**: Android Open Source Project  
**Branch**: android-15.0.0_r32  
**URL**: https://android.googlesource.com/platform/manifest

This is the main AOSP manifest that contains all core Android components.

## Local Manifests (Raspberry Pi Specific)

These manifests are from the **raspberry-vanilla** project and add Raspberry Pi specific components.

### 1. manifest_brcm_rpi.xml

**URL**: https://raw.githubusercontent.com/raspberry-vanilla/android_local_manifest/android-15.0/manifest_brcm_rpi.xml

This manifest adds:
- Raspberry Pi device configurations
- BCM2712 (RPI5) hardware support
- Kernel sources for Raspberry Pi
- Graphics and multimedia HALs
- Firmware and boot components
- RPI-specific patches and overlays

Key repositories added:
```xml
<!-- Device Configuration -->
device/brcm/rpi5
device/brcm/rpi-common

<!-- Kernel -->
kernel/arpi/linux

<!-- HALs (Hardware Abstraction Layers) -->
hardware/arpi/audio
hardware/arpi/camera
hardware/arpi/graphics
hardware/arpi/gralloc
hardware/arpi/hwcomposer

<!-- Firmware -->
vendor/brcm/rpi/firmware
vendor/brcm/rpi/bootloader
```

### 2. remove_projects.xml

**URL**: https://raw.githubusercontent.com/raspberry-vanilla/android_local_manifest/android-15.0/remove_projects.xml

This manifest removes AOSP components that are replaced by Raspberry Pi specific versions:
- Generic kernel (replaced with RPI kernel)
- Generic device configs (replaced with RPI device configs)
- Incompatible HALs

This reduces download size and prevents conflicts.

## What Gets Downloaded

### Total Download Size
- **~100GB** of source code (compressed)
- **~150GB** after extraction and setup

### Main Components

1. **AOSP Base** (~80GB)
   - Android framework
   - System apps
   - Build tools
   - SDK and tools
   - Native libraries

2. **Raspberry Pi Additions** (~20GB)
   - Linux kernel for BCM2712
   - Device tree overlays
   - Broadcom firmware
   - RPI-specific HALs
   - Boot components

3. **Development Tools**
   - Compiler toolchains
   - Build system (Soong/Make)
   - SDK platform tools
   - Testing frameworks

## Repository Structure After Sync

```
~/aosp-rpi5/
├── art/                    # Android Runtime
├── bionic/                 # C library
├── bootable/              # Bootloader
├── build/                  # Build system
├── cts/                    # Compatibility Test Suite
├── dalvik/                 # Dalvik VM (legacy)
├── developers/            # Sample code
├── development/           # Development tools
├── device/
│   ├── brcm/
│   │   ├── rpi5/         # Raspberry Pi 5 device config
│   │   └── rpi-common/   # Common RPI components
│   └── generic/          # Generic device configs
├── external/              # Third-party projects
├── frameworks/            # Android frameworks
├── hardware/
│   ├── arpi/             # RPI hardware implementations
│   └── interfaces/       # HAL interfaces
├── kernel/
│   └── arpi/
│       └── linux/        # Linux kernel for RPI
├── packages/             # System apps and packages
├── pdk/                   # Platform Development Kit
├── platform_testing/     # Platform tests
├── prebuilts/            # Prebuilt binaries
├── sdk/                   # Software Development Kit
├── system/                # System components
├── toolchain/            # Compiler toolchains
├── tools/                 # Build and development tools
└── vendor/
    └── brcm/
        └── rpi/          # RPI vendor files and firmware
```

## Customizing the Manifest

To add the ED-HMI3010-101C device tree overlay to the build, you can create an additional local manifest:

**File**: `.repo/local_manifests/hmi3010.xml`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
  <!-- Add device tree overlay for ED-HMI3010-101C -->
  <project name="JeffMolenaar/AOSP15-RPI5" 
           path="device/edatec/hmi3010" 
           remote="github" 
           revision="main">
    <copyfile src="device-tree/hmi3010-touch-overlay.dts" 
              dest="device/brcm/rpi5/overlays/hmi3010-touch.dts"/>
  </project>
</manifest>
```

This would automatically include the touch overlay in the build.

## Updating the Source

To update to the latest code:

```bash
cd ~/aosp-rpi5
repo sync -j$(nproc)
```

This fetches updates from all repositories while preserving local changes.

## Selective Sync

To save bandwidth and time, you can sync only specific projects:

```bash
# Sync only kernel
repo sync kernel/arpi/linux

# Sync only device config
repo sync device/brcm/rpi5

# Sync everything except prebuilts
repo sync --exclude-project=prebuilts/*
```

## Manifest Branches

Available raspberry-vanilla branches:
- `android-15.0` - Android 15 (current)
- `android-14.0` - Android 14
- `android-13.0` - Android 13

To switch branches (requires re-sync):
```bash
repo init -b android-14.0
repo sync
```

## Troubleshooting Manifest Issues

### Issue: Sync fails with "cannot checkout"
**Solution**: Remove the problematic project and re-sync:
```bash
rm -rf path/to/project
repo sync path/to/project
```

### Issue: Manifest merge conflicts
**Solution**: Remove local manifests and re-add:
```bash
rm -rf .repo/local_manifests
mkdir -p .repo/local_manifests
# Re-download manifests
repo sync
```

### Issue: Repository not found
**Solution**: Check manifest URLs are accessible:
```bash
curl -I https://raw.githubusercontent.com/raspberry-vanilla/android_local_manifest/android-15.0/manifest_brcm_rpi.xml
```

## References

- **AOSP Manifest Documentation**: https://source.android.com/docs/setup/create/coding-tasks
- **Repo Tool Guide**: https://source.android.com/docs/setup/download
- **Raspberry-Vanilla Project**: https://github.com/raspberry-vanilla/android_local_manifest
- **Manifest XML Format**: https://gerrit.googlesource.com/git-repo/+/master/docs/manifest-format.md
