# Auto-Start Application on Boot

This directory contains the configuration for installing and auto-launching an APK when the Raspberry Pi 5 boots.

## Overview

This setup allows you to:
1. Include a custom APK in your AOSP build
2. Automatically install it as a system app
3. Configure it to launch immediately when the device boots

## How It Works

The configuration:
1. Copies your APK into the system partition during build
2. Creates a boot receiver that launches your app on `BOOT_COMPLETED`
3. Grants necessary permissions for auto-start functionality

## Directory Structure

```
auto-start-app/
├── README.md              # This file
├── sample-app/           # Example template
│   └── YourApp.apk       # Place your APK here (rename as needed)
├── auto-start.mk         # Makefile to include APK in build
└── AutoStartHelper/      # Helper app that launches your app on boot
    ├── Android.bp        # Build configuration
    ├── AndroidManifest.xml
    └── src/
        └── ...           # Java source code
```

## Quick Start Guide

### Step 1: Prepare Your APK

1. Place your APK file in the `sample-app/` directory:
   ```bash
   cp /path/to/your/app.apk customization/auto-start-app/sample-app/YourApp.apk
   ```

2. Edit `auto-start.mk` and update the APK filename:
   ```makefile
   # Change YourApp.apk to match your APK filename
   LOCAL_SRC_FILES := sample-app/YourApp.apk
   ```

3. Update the package name in `auto-start.mk`:
   ```makefile
   # Change to your app's package name (e.g., com.yourcompany.app)
   PRODUCT_PROPERTY_OVERRIDES += \
       persist.autostart.package=com.example.yourapp
   ```

### Step 2: Configure Auto-Start Package Name

Edit `AutoStartHelper/src/com/rpi/autostarthelper/BootReceiver.java`:

```java
private static final String AUTO_START_PACKAGE = "com.example.yourapp";
```

Change `com.example.yourapp` to match your app's package name.

### Step 3: Apply to AOSP Build

#### Option A: Using Build Helper (Recommended)

```bash
./build-helper.sh apply-customization auto-start
```

#### Option B: Manual Installation

1. Copy files to AOSP directory:
   ```bash
   cd ~/aosp-rpi5
   
   # Copy the APK configuration
   cp ~/AOSP15-RPI5/customization/auto-start-app/auto-start.mk \
      device/brcm/rpi5/
   
   # Copy the AutoStartHelper app
   cp -r ~/AOSP15-RPI5/customization/auto-start-app/AutoStartHelper \
      packages/apps/
   ```

2. Edit `device/brcm/rpi5/device.mk` and add:
   ```makefile
   # Include auto-start app configuration
   include device/brcm/rpi5/auto-start.mk
   
   # Include AutoStartHelper system app
   PRODUCT_PACKAGES += AutoStartHelper
   ```

3. Build AOSP:
   ```bash
   cd ~/aosp-rpi5
   source build/envsetup.sh
   lunch aosp_rpi5-bp1a-userdebug
   make -j$(nproc)
   ```

### Step 4: Verify Installation

After flashing and booting:

1. Check if your app is installed:
   ```bash
   adb shell pm list packages | grep yourapp
   ```

2. Check if AutoStartHelper is installed:
   ```bash
   adb shell pm list packages | grep autostarthelper
   ```

3. Reboot and verify your app launches:
   ```bash
   adb reboot
   # Wait for boot to complete
   adb shell dumpsys window | grep mCurrentFocus
   ```

## Configuration Details

### Auto-Start Mechanism

The `AutoStartHelper` app:
1. Registers for the `BOOT_COMPLETED` broadcast
2. Waits for system to be fully ready
3. Launches your app's main activity
4. Runs as a system app with elevated privileges

### System App Installation

Your APK is installed as a privileged system app, which means:
- It's pre-installed in `/system/priv-app/`
- It survives factory resets
- It has access to system-level permissions
- It cannot be uninstalled by users

### Permissions

The AutoStartHelper requires:
- `RECEIVE_BOOT_COMPLETED`: To detect when device boots
- `SYSTEM_ALERT_WINDOW`: To launch apps over other apps
- System app privileges: To start other apps automatically

## Finding Your App's Package Name

If you don't know your APK's package name:

```bash
# Using aapt (Android Asset Packaging Tool)
aapt dump badging YourApp.apk | grep package:

# Or using apkanalyzer
apkanalyzer manifest application-id YourApp.apk
```

## Advanced Configuration

### Delay Before Launch

To add a delay before launching your app, edit `BootReceiver.java`:

```java
// Add delay in milliseconds (e.g., 5000 = 5 seconds)
handler.postDelayed(new Runnable() {
    @Override
    public void run() {
        launchApp(context);
    }
}, 5000);
```

### Launch with Specific Intent

To pass data to your app when launching, edit `BootReceiver.java`:

```java
Intent launchIntent = pm.getLaunchIntentForPackage(AUTO_START_PACKAGE);
if (launchIntent != null) {
    launchIntent.putExtra("autostart", true);
    launchIntent.putExtra("boot_time", System.currentTimeMillis());
    launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    context.startActivity(launchIntent);
}
```

### Multiple Auto-Start Apps

To launch multiple apps on boot:

1. Create an array of package names in `BootReceiver.java`:
   ```java
   private static final String[] AUTO_START_PACKAGES = {
       "com.example.app1",
       "com.example.app2",
       "com.example.app3"
   };
   ```

2. Modify the `launchApp()` method to iterate through all packages.

3. Include multiple APKs in your build by adding them to `auto-start.mk`.

## Troubleshooting

### App Doesn't Launch on Boot

1. **Check if AutoStartHelper received boot event:**
   ```bash
   adb logcat | grep AutoStartHelper
   ```

2. **Verify package name is correct:**
   ```bash
   adb shell pm list packages
   ```
   Find your app's exact package name.

3. **Check boot receiver registration:**
   ```bash
   adb shell dumpsys package com.rpi.autostarthelper | grep "Boot"
   ```

4. **Verify app has a launch activity:**
   ```bash
   adb shell pm dump com.example.yourapp | grep "android.intent.action.MAIN"
   ```

### App Crashes on Launch

1. Check logcat for errors:
   ```bash
   adb logcat | grep "AndroidRuntime"
   ```

2. Ensure your app is compatible with the Android version (AOSP 15).

3. Check if app requires specific permissions that aren't granted.

### App Launches But Closes Immediately

Your app might be:
- Checking for Google Play Services (not available on AOSP)
- Requiring specific hardware features
- Crashing due to missing dependencies

Check the app's logcat output for specific errors.

## Security Considerations

### Privileged System App

Installing your app as a system app means:
- ✅ It has more permissions
- ✅ It can auto-start
- ✅ It survives factory resets
- ⚠️ Make sure your app is trusted
- ⚠️ It will be harder to update (requires reflashing)

### Updating Your App

To update the auto-start app:
1. Replace the APK in `sample-app/`
2. Rebuild AOSP
3. Flash the new image

Alternatively, for testing:
```bash
adb install -r YourApp.apk
```

This will update the app but it will revert to the system version after a factory reset.

## Example Use Cases

- **Kiosk Mode**: Launch a single app for dedicated device usage
- **Digital Signage**: Auto-start a media player or slideshow app
- **Industrial Control**: Launch a custom control interface
- **POS System**: Start a point-of-sale application
- **Home Automation**: Launch a home control dashboard

## Alternative Methods

### Using Android's Launcher

If you want your app to be the default launcher (home screen):

Add to your app's AndroidManifest.xml:
```xml
<intent-filter>
    <action android:name="android.intent.action.MAIN" />
    <category android:name="android.intent.category.HOME" />
    <category android:name="android.intent.category.DEFAULT" />
</intent-filter>
```

Then rebuild and it will become the default launcher.

### Using Autostart Apps

Some kiosk apps have built-in autostart functionality. Check your app's documentation.

## Related Files

- `device/brcm/rpi5/device.mk` - Device configuration
- `frameworks/base/core/java/android/content/Intent.java` - Intent system
- `system/core/rootdir/init.rc` - System initialization

## References

- [Android Boot Sequence](https://source.android.com/docs/core/architecture/bootloader)
- [Broadcast Receivers](https://developer.android.com/guide/components/broadcasts)
- [System Apps](https://source.android.com/docs/core/permissions/perms-allowlist)
- [AOSP App Integration](https://source.android.com/docs/setup/create/new-device)
