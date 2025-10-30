# Portrait Mode Configuration for AOSP Raspberry Pi 5
# This makefile fragment enables portrait mode as the default display orientation

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.rotation=90

# Set appropriate LCD density for portrait mode (800x1280)
# Adjust this value if UI elements are too large or small
PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=160

# Configure window manager for portrait orientation
PRODUCT_PROPERTY_OVERRIDES += \
    debug.sf.disable_backpressure=1 \
    debug.sf.enable_gl_backpressure=1

# Configure default orientation
PRODUCT_PROPERTY_OVERRIDES += \
    persist.demo.rotationlock=true
