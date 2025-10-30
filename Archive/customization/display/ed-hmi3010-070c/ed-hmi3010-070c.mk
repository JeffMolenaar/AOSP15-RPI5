# Device make fragment to install the ED-HMI3010-070C DTBO and config into the image.
# Include this file into device/brcm/rpi5/device.mk to add the overlay to the built image.
#
# Usage (in device/brcm/rpi5/device.mk):
#   include device/brcm/rpi5/ed-hmi3010-070c.mk
#
# NOTE: Verify the destination path used by your build image creation script.
# The destination below assumes the final image places overlays under
# boot/firmware/overlays in the built SD image.

# Copy the compiled DTBO into the boot overlay folder of the image
PRODUCT_COPY_FILES += \
    device/brcm/rpi5/overlays/ed-hmi3010-070c.dtbo:boot/firmware/overlays/ed-hmi3010-070c.dtbo

# Optional: copy a device-specific config.txt fragment
PRODUCT_COPY_FILES += \
    device/brcm/rpi5/ed-hmi3010-070c/config.txt:boot/firmware/config.txt

# Add any product packages if necessary (e.g. a vendor touch driver)
# PRODUCT_PACKAGES += your-touch-driver
