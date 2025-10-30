package com.rpi.autostarthelper;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Handler;
import android.os.SystemProperties;
import android.util.Log;

/**
 * Boot receiver that automatically launches the configured app when device boots
 */
public class BootReceiver extends BroadcastReceiver {
    private static final String TAG = "AutoStartHelper";
    
    // Default package to auto-start - can be overridden via system property
    private static final String DEFAULT_PACKAGE = "com.example.yourapp";
    private static final String PROPERTY_AUTOSTART_PACKAGE = "persist.autostart.package";
    
    // Delay before launching app (milliseconds)
    private static final int LAUNCH_DELAY_MS = 3000;

    @Override
    public void onReceive(Context context, Intent intent) {
        if (Intent.ACTION_BOOT_COMPLETED.equals(intent.getAction()) ||
            "android.intent.action.LOCKED_BOOT_COMPLETED".equals(intent.getAction())) {
            
            Log.i(TAG, "Boot completed, preparing to launch auto-start app");
            
            // Delay launch to ensure system is fully ready
            new Handler(context.getMainLooper()).postDelayed(new Runnable() {
                @Override
                public void run() {
                    launchApp(context);
                }
            }, LAUNCH_DELAY_MS);
        }
    }

    private void launchApp(Context context) {
        try {
            // Get package name from system property, fall back to default
            String packageName = SystemProperties.get(PROPERTY_AUTOSTART_PACKAGE, DEFAULT_PACKAGE);
            
            Log.i(TAG, "Attempting to launch package: " + packageName);
            
            PackageManager pm = context.getPackageManager();
            Intent launchIntent = pm.getLaunchIntentForPackage(packageName);
            
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP);
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
                
                // Optional: Add extras to indicate this is an auto-start launch
                launchIntent.putExtra("autostart", true);
                launchIntent.putExtra("boot_timestamp", System.currentTimeMillis());
                
                context.startActivity(launchIntent);
                Log.i(TAG, "Successfully launched: " + packageName);
            } else {
                Log.e(TAG, "Could not find launch intent for package: " + packageName);
                Log.e(TAG, "Make sure the package is installed and has a main activity");
            }
        } catch (Exception e) {
            Log.e(TAG, "Error launching auto-start app", e);
        }
    }
}
