# Repository Structure

This document describes the organization of this repository.

## Repository Contents

```
AOSP15-RPI5/
├── README.md                    # Main repository overview
├── QUICKSTART.md               # Fast-track build guide
├── BUILD_INSTRUCTIONS.md       # Detailed build documentation
├── TROUBLESHOOTING.md          # Common issues and solutions
├── FAQ.md                      # Frequently asked questions
├── MANIFEST_REFERENCE.md       # Manifest documentation
├── CONTRIBUTING.md             # Contribution guidelines
├── LICENSE                     # Repository license
│
├── setup-aosp.sh              # Automated setup script (executable)
├── build-helper.sh            # Build helper script (executable)
│
└── device-tree/               # Device tree configurations
    ├── README.md              # Device tree documentation
    └── hmi3010-touch-overlay.dts  # Touch controller overlay
```

## After Running setup-aosp.sh

The script creates `~/aosp-rpi5/` with the complete AOSP source tree:

```
~/aosp-rpi5/                    # AOSP root directory (~250GB)
├── .repo/                      # Repo metadata and manifests
│   ├── manifests/             # Main AOSP manifest
│   ├── local_manifests/       # Raspberry Pi specific manifests
│   │   ├── manifest_brcm_rpi.xml
│   │   └── remove_projects.xml
│   └── ...
│
├── build/                      # Build system (Soong/Make)
├── device/                     # Device configurations
│   └── brcm/
│       ├── rpi5/              # Raspberry Pi 5 specific
│       └── rpi-common/        # Common RPI files
├── kernel/                     # Kernel source
│   └── arpi/
│       └── linux/             # Linux kernel for RPI
├── hardware/                   # HALs
│   └── arpi/                  # RPI hardware support
├── vendor/                     # Vendor files
│   └── brcm/
│       └── rpi/               # Broadcom/RPI firmware
│
├── frameworks/                 # Android frameworks
├── packages/                   # System apps
├── system/                     # System components
├── external/                   # Third-party libraries
├── prebuilts/                  # Prebuilt binaries
├── tools/                      # Build tools
│
└── out/                        # Build output (~100GB)
    ├── target/
    │   └── product/
    │       └── rpi5/
    │           ├── system.img
    │           ├── boot.img
    │           ├── vendor.img
    │           └── rpi5.img   # Flashable SD card image
    └── error.log              # Build errors (if any)
```

## Key Files

### Scripts

#### setup-aosp.sh
- Installs dependencies
- Configures git and repo tool
- Initializes AOSP repository
- Downloads Raspberry Pi manifests
- Optionally syncs source code

**Usage**: `./setup-aosp.sh`

#### build-helper.sh
- Simplifies building AOSP
- Provides common build operations
- Handles flashing to SD card
- Shows build information

**Usage**: 
```bash
./build-helper.sh build     # Build AOSP
./build-helper.sh flash /dev/sdX  # Flash to SD card
./build-helper.sh help      # Show all commands
```

### Documentation

#### README.md
- Repository overview
- Feature list
- Quick links to other docs
- Quick start instructions

#### QUICKSTART.md
- Streamlined build guide
- Minimal steps to get building
- For users who want to start fast

#### BUILD_INSTRUCTIONS.md
- Comprehensive build guide
- System requirements
- Detailed step-by-step instructions
- Customization options
- Manual setup alternative

#### TROUBLESHOOTING.md
- Common issues and solutions
- Organized by category
- Debug commands
- Hardware testing tips

#### FAQ.md
- Frequently asked questions
- Organized by topic
- Quick answers to common questions

#### MANIFEST_REFERENCE.md
- Explanation of manifests
- What gets downloaded
- Repository structure
- Customization options

### Device Tree

#### device-tree/hmi3010-touch-overlay.dts
- Device tree overlay for ED-HMI3010-101C
- Configures I2C touch controller
- Sets up GPIO pins
- Enables 10-point multi-touch

#### device-tree/README.md
- Overlay documentation
- Compilation instructions
- Customization parameters
- Troubleshooting touch issues

## File Purposes

### Configuration Files

| File | Purpose |
|------|---------|
| `manifest_brcm_rpi.xml` | Adds Raspberry Pi specific repositories |
| `remove_projects.xml` | Removes incompatible AOSP components |
| `hmi3010-touch-overlay.dts` | Touch controller configuration |

### Build Outputs

| File | Description | Size |
|------|-------------|------|
| `system.img` | Android system partition | ~2GB |
| `boot.img` | Kernel and ramdisk | ~50MB |
| `vendor.img` | Vendor partition | ~500MB |
| `rpi5.img` | Complete flashable image | ~4-6GB |

## Workflow

```
1. Clone Repository
   ↓
2. Run setup-aosp.sh
   ↓ (Downloads ~100GB)
3. Source code synced to ~/aosp-rpi5/
   ↓
4. Run build-helper.sh build
   ↓ (Builds 2-6 hours)
5. Build output in ~/aosp-rpi5/out/
   ↓
6. Run build-helper.sh flash
   ↓
7. Boot Raspberry Pi 5 with flashed SD card
```

## Directory Size Estimates

| Directory | Size | Description |
|-----------|------|-------------|
| `build/` | ~500MB | Build system |
| `device/` | ~100MB | Device configs |
| `kernel/` | ~2GB | Kernel source |
| `frameworks/` | ~15GB | Android frameworks |
| `packages/` | ~5GB | System apps |
| `external/` | ~30GB | Third-party code |
| `prebuilts/` | ~40GB | Prebuilt toolchains |
| `out/` | ~100GB | Build output |
| **Total** | **~250GB** | Complete AOSP tree |

## Important Locations

### On Host Machine

```
~/.gitconfig              # Git configuration
~/bin/repo                # Repo tool
~/aosp-rpi5/              # AOSP source directory
~/aosp-rpi5/out/error.log # Build error log
~/.ccache/                # Compiler cache (optional)
```

### On Raspberry Pi

```
/system/                  # Android system partition
/vendor/                  # Vendor partition
/data/                    # User data partition
/boot/                    # Boot partition
/boot/config.txt          # Boot configuration
/boot/overlays/           # Device tree overlays
```

## Build Artifacts

After a successful build, you'll find:

```
out/target/product/rpi5/
├── boot.img              # Boot image
├── system.img            # System partition
├── vendor.img            # Vendor partition
├── userdata.img          # User data
├── rpi5.img             # Complete SD card image
├── obj/                  # Object files
└── symbols/              # Debug symbols
```

## Cleaning Up

To free up space:

```bash
# Remove build output (keeps source)
./build-helper.sh clean          # ~50GB freed

# Remove everything except source
./build-helper.sh clobber        # ~100GB freed

# Remove entire AOSP (keep this repo)
rm -rf ~/aosp-rpi5              # ~250GB freed
```

## Updating

To update the repository:

```bash
git pull origin main             # Update this repo
./build-helper.sh sync          # Update AOSP sources
```

## Contributing

See CONTRIBUTING.md for:
- How to contribute
- Code standards
- Testing requirements
- Pull request process

## License

Individual components have their own licenses:
- AOSP: Various open-source licenses
- Raspberry Pi components: BSD/GPL
- This repository: MIT (see LICENSE)
