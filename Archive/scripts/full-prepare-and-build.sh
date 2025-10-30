#!/usr/bin/env bash
# Full prepare-and-build script for RPi5 + ED-HMI3010-070C DSI panel
#
# This script orchestrates all prep steps to make the AOSP tree include the
# panel overlay, config and any driver sources you provide under
# customization/drivers/. It then optionally triggers the AOSP build.
#
# Important: This script cannot fabricate closed-source/kernel drivers.
# If your panel requires vendor drivers, place their source under
# customization/drivers/<driver-name>/ and the script will copy them into
# AOSP at device/brcm/rpi5/kernel-drivers/<driver-name>/ for you to integrate
# into the kernel build. You must still ensure they are built against the
# kernel used by your AOSP build (headers/configs must match).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AOSP_DIR="${AOSP_DIR:-${HOME}/aosp-rpi5}"
SCRIPT_BUILD_DIR="${REPO_DIR}/script-folder/build"
mkdir -p "${SCRIPT_BUILD_DIR}"

LOGFILE="${SCRIPT_BUILD_DIR}/full-prep-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "${LOGFILE}") 2>&1

echo "Full prepare-and-build - $(date)"
echo "Repo: ${REPO_DIR}"
echo "AOSP dir: ${AOSP_DIR}"

# 0) Quick sanity checks
echo "Checking prerequisites..."
command -v bash >/dev/null 2>&1 || { echo "bash required"; exit 1; }
command -v dtc >/dev/null 2>&1 || echo "Note: 'dtc' not found; DTBO compilation may be skipped"

# 1) Run the pre-build device prep (overlays, mk, config)
PREP_SCRIPT="${REPO_DIR}/scripts/prep-device-for-build.sh"
if [ -f "${PREP_SCRIPT}" ]; then
    echo "Running pre-build prep script: ${PREP_SCRIPT}"
    bash "${PREP_SCRIPT}"
else
    echo "Error: prep script not found: ${PREP_SCRIPT}"
    exit 1
fi

# 2) Copy any provided drivers into the AOSP tree for integration
DRIVERS_DIR="${REPO_DIR}/customization/drivers"
TARGET_DRIVERS_DIR="${AOSP_DIR}/device/brcm/rpi5/kernel-drivers"
if [ -d "${DRIVERS_DIR}" ]; then
    echo "Found drivers directory: ${DRIVERS_DIR}"
    mkdir -p "${TARGET_DRIVERS_DIR}"
    for d in "${DRIVERS_DIR}"/*; do
        [ -e "$d" ] || continue
        name=$(basename "$d")
        echo "Installing driver source: $name -> ${TARGET_DRIVERS_DIR}/$name"
        rm -rf "${TARGET_DRIVERS_DIR}/$name"
        cp -r "$d" "${TARGET_DRIVERS_DIR}/"
    done
    echo "Driver sources copied to ${TARGET_DRIVERS_DIR}." 
    echo "NOTE: You still need to integrate these into the kernel build (Kconfig/Makefile)" 
else
    echo "No customization/drivers folder found; skipping driver copy"
fi

# 3) Provide guidance / attempt simple integration for common open drivers
# (This is minimal: enabling kernel drivers requires kernel source and Kconfig edits.)
cat > "${SCRIPT_BUILD_DIR}/driver-integration-instructions.txt" <<EOF
Driver integration instructions
--------------------------------
1) If the drivers you provided are out-of-tree kernel modules, you'll need to
   build them against the kernel used by your AOSP build. Typical steps:
   - Ensure kernel headers/config for the AOSP kernel are available
   - Build the modules with the same CROSS_COMPILE / ARCH settings
   - Install .ko into the image's /lib/modules/<kernel-version>/

2) If you want the drivers built as part of the kernel, add the driver sources
   under the kernel tree and update the kernel Makefile/Kconfig to expose
   a CONFIG_ option. This is more involved and must match the kernel used by AOSP.

3) The script copied drivers to: ${TARGET_DRIVERS_DIR}
   Edit your kernel build or image creation scripts to include them as needed.

EOF

echo "Driver integration instructions written to ${SCRIPT_BUILD_DIR}/driver-integration-instructions.txt"

# 4) Optionally run the build
if [ "${1:-}" = "build" ]; then
    echo "Starting build (via build-helper.sh)"
    (cd "${REPO_DIR}" && ./build-helper.sh build)
else
    echo "Prep complete. To kick off a build now run: ./scripts/full-prepare-and-build.sh build"
fi

echo "Full prep finished. Log: ${LOGFILE}"
