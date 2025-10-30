This folder is used by helper scripts to store trace artifacts and generated files.

Tracked outputs saved here (examples):

- .aosp_setup_complete (marker created by `setup-aosp.sh`)
- setup-summary.txt (summary and timestamp)
- build-<timestamp>.log (build logs created by `build-helper.sh`)
- rpi5.img (build image copied after successful build)
- bootanimation-<timestamp>.zip (generated boot animation copy)
- YourApp-<timestamp>.apk (copied APK used for auto-start)
- device.mk.modified-<timestamp> (snapshot of modified device.mk)
- customizations-summary.txt (marker created by `apply-customizations-example.sh`)

If you want to change where artifacts are stored, update the `SCRIPT_BUILD_DIR` variable at the top of the scripts in the repository.
