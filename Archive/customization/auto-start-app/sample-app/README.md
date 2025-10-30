# Sample App Placeholder

Place your APK file in this directory.

## Instructions

1. Copy your APK file here:
   ```bash
   cp /path/to/your/app.apk sample-app/YourApp.apk
   ```

2. Update `auto-start.mk` with your APK filename and package name

3. The APK will be included in your AOSP build as a privileged system app

## Requirements

Your APK should:
- Have a valid AndroidManifest.xml
- Have at least one Activity with ACTION_MAIN intent filter
- Be compatible with Android 15 (API level 35)

## Finding Package Name

To find your app's package name:

```bash
# Using aapt
aapt dump badging YourApp.apk | grep package:

# Using aapt2
aapt2 dump packagename YourApp.apk
```

The package name will look like: `com.example.yourapp`
