#!/usr/bin/env bash
# Prep script to install ED-HMI3010-070C-DSI overlay and device fragments
# Run this before building AOSP so overlays/config are included in the built image.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AOSP_DIR="${AOSP_DIR:-${HOME}/aosp-rpi5}"
SCRIPT_BUILD_DIR="${REPO_DIR}/script-folder/build"
mkdir -p "${SCRIPT_BUILD_DIR}"

LOGFILE="${SCRIPT_BUILD_DIR}/prep-device-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "${LOGFILE}") 2>&1

echo "Prep device for build - $(date)"
echo "Repo: ${REPO_DIR}"
echo "AOSP dir: ${AOSP_DIR}"

# Paths
DT_SRC="${REPO_DIR}/customization/display/ed-hmi3010-070c/ed-hmi3010-070c.dts"
DTBO_SRC="${REPO_DIR}/customization/display/ed-hmi3010-070c/ed-hmi3010-070c.dtbo"
MK_SRC="${REPO_DIR}/customization/display/ed-hmi3010-070c/ed-hmi3010-070c.mk"
CFG_SRC="${REPO_DIR}/customization/display/ed-hmi3010-070c/config.txt"

DEVICE_OVERLAYS_DIR="${AOSP_DIR}/device/brcm/rpi5/overlays"
DEVICE_DIR="${AOSP_DIR}/device/brcm/rpi5"

# Ensure target directories exist
mkdir -p "${DEVICE_OVERLAYS_DIR}"
mkdir -p "${DEVICE_DIR}"

# 1) Compile DTS -> DTBO if possible
if command -v dtc >/dev/null 2>&1 && [ -f "${DT_SRC}" ]; then
    echo "Compiling ${DT_SRC} -> ${DTBO_SRC}"
    dtc -@ -I dts -O dtb -o "${DTBO_SRC}" "${DT_SRC}" || {
        echo "Warning: dtc returned non-zero but continuing";
    }
else
    echo "dtc not available or DTS not present; skipping compile"
fi

# 2) Copy DTBO into AOSP device overlays (if exists)
if [ -f "${DTBO_SRC}" ]; then
    echo "Copying DTBO to ${DEVICE_OVERLAYS_DIR}/ed-hmi3010-070c.dtbo"
    cp -f "${DTBO_SRC}" "${DEVICE_OVERLAYS_DIR}/ed-hmi3010-070c.dtbo"
    cp -f "${DTBO_SRC}" "${SCRIPT_BUILD_DIR}/ed-hmi3010-070c-$(date +%Y%m%d-%H%M%S).dtbo" || true
else
    echo "No DTBO found at ${DTBO_SRC}; ensure DTS is correct or compile manually"
fi

# 3) Copy mk fragment into device folder
if [ -f "${MK_SRC}" ]; then
    echo "Installing mk fragment to ${DEVICE_DIR}/ed-hmi3010-070c.mk"
    cp -f "${MK_SRC}" "${DEVICE_DIR}/ed-hmi3010-070c.mk"
else
    echo "Missing mk fragment: ${MK_SRC}"
fi

# 4) Copy config fragment (do not overwrite existing config.txt, instead write a fragment)
if [ -f "${CFG_SRC}" ]; then
    echo "Installing config fragment to ${DEVICE_DIR}/ed-hmi3010-070c-config.txt"
    cp -f "${CFG_SRC}" "${DEVICE_DIR}/ed-hmi3010-070c-config.txt"
    # Note: the ed-hmi3010-070c.mk attempts to copy this into the image; verify image builder respects it
else
    echo "Missing config fragment: ${CFG_SRC}"
fi

# 5) Ensure device.mk includes the fragment
DEVICE_MK="${DEVICE_DIR}/device.mk"
INCLUDE_LINE="include device/brcm/rpi5/ed-hmi3010-070c.mk"
if [ -f "${DEVICE_MK}" ]; then
    if grep -qF "ed-hmi3010-070c.mk" "${DEVICE_MK}"; then
        echo "device.mk already includes ed-hmi3010-070c.mk"
    else
        echo "Adding include to ${DEVICE_MK}"
        echo "\n# Include ED-HMI3010-070C panel overlay" >> "${DEVICE_MK}"
        echo "${INCLUDE_LINE}" >> "${DEVICE_MK}"
    fi
else
    echo "Warning: ${DEVICE_MK} not found. You may need to add the following line to your device.mk manually:"
    echo "  ${INCLUDE_LINE}"
fi

# 6) Final checks
echo "Files in AOSP device overlays:"
ls -la "${DEVICE_OVERLAYS_DIR}" || true

echo "Prep complete. Log saved to ${LOGFILE}"

echo "Done."
