# Build Complete! Next Steps

🎉 **Congratulations! Your AOSP build has completed successfully.**

## Quick Reference - What to Do Now

### 1️⃣ Create Flashable Image
```bash
cd ~/aosp-rpi5
./rpi5-mkimg.sh
```

### 2️⃣ Flash to SD Card
```bash
# Find SD card
lsblk

# Flash (⚠️ WARNING: Erases SD card!)
sudo dd if=~/aosp-rpi5/out/target/product/rpi5/rpi5.img of=/dev/sdX bs=4M status=progress
sync
```
Replace `/dev/sdX` with your SD card device.

### 3️⃣ Boot Raspberry Pi 5
1. Insert SD card into Raspberry Pi 5
2. Connect HDMI display
3. Connect power
4. Wait 2-3 minutes for first boot

## Alternative: Use Helper Script
```bash
cd /path/to/AOSP15-RPI5
./build-helper.sh flash /dev/sdX
```

## 📚 Detailed Documentation

- **[POST_BUILD.md](POST_BUILD.md)** - Complete flashing & booting guide
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - If something goes wrong
- **[FAQ.md](FAQ.md)** - Common questions

---

**Need help?** See [POST_BUILD.md](POST_BUILD.md) for detailed instructions.
