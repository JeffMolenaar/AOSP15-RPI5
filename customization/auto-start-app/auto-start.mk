# Auto-Start App Configuration for AOSP Raspberry Pi 5
# This makefile includes a custom APK and configures it to auto-start on boot

# Change this to your APK filename
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := YourApp
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_TAGS := optional
LOCAL_BUILT_MODULE_STEM := package.apk
LOCAL_MODULE_SUFFIX := .apk
LOCAL_PRIVILEGED_MODULE := true
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_SRC_FILES := sample-app/YourApp.apk
LOCAL_DEX_PREOPT := false
include $(BUILD_PREBUILT)

# Set the package name to auto-start
# Change com.example.yourapp to your actual package name
PRODUCT_PROPERTY_OVERRIDES += \
    persist.autostart.package=com.example.yourapp

# Grant necessary permissions for auto-start
PRODUCT_COPY_FILES += \
    device/brcm/rpi5/permissions/privapp-permissions-autostart.xml:$(TARGET_COPY_OUT_SYSTEM)/etc/permissions/privapp-permissions-autostart.xml
