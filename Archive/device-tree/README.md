# Device Tree Overlay for ED-HMI3010-101C

This directory contains the device tree overlay configuration for the ED-HMI3010-101C display's touch controller.

## File: hmi3010-touch-overlay.dts

This device tree overlay enables the capacitive touch controller for the ED-HMI3010-101C display.

### Features Configured:
- **I2C Interface**: Touch controller on I2C bus 1 at address 0x38
- **Multi-touch**: 10-point capacitive touch support
- **Resolution**: 1280x800 pixels
- **GPIO Pins**:
  - GPIO22: Touch interrupt (falling edge)
  - GPIO26: Touch reset (active low)
  - GPIO27: Touch wake (active high)

### Touch Controller Compatibility:
The overlay uses the `edt-ft5x06` driver which supports:
- FT5406
- FT5x06 series
- Other FocalTech capacitive touch controllers

### Compilation:

To compile this overlay into a device tree blob:

```bash
dtc -@ -I dts -O dtb -o hmi3010-touch.dtbo hmi3010-touch-overlay.dts
```

### Installation:

For AOSP builds, this overlay should be included in the device tree configuration during the kernel build process. The overlay will be automatically compiled and included in the boot partition.

For manual installation on a running system:
1. Copy the compiled `.dtbo` file to `/boot/overlays/`
2. Add to `/boot/config.txt`:
   ```
   dtoverlay=hmi3010-touch
   ```

### Customization:

You can override parameters in `/boot/config.txt`:

```
# Example: Change interrupt GPIO
dtoverlay=hmi3010-touch,interrupt=23

# Example: Swap X/Y axes
dtoverlay=hmi3010-touch,swapxy=1

# Example: Invert Y axis
dtoverlay=hmi3010-touch,invy=1
```

Available parameters:
- `interrupt`: GPIO pin for touch interrupt (default: 22)
- `reset`: GPIO pin for reset (default: 26)
- `wake`: GPIO pin for wake (default: 27)
- `sizex`: Touch area width in pixels (default: 1280)
- `sizey`: Touch area height in pixels (default: 800)
- `invx`: Invert X axis (0/1)
- `invy`: Invert Y axis (0/1)
- `swapxy`: Swap X and Y axes (0/1)

### Troubleshooting:

If touch doesn't work:

1. **Check I2C detection:**
   ```bash
   i2cdetect -y 1
   ```
   You should see device at address 0x38.

2. **Check kernel messages:**
   ```bash
   dmesg | grep -i ft5
   dmesg | grep -i edt
   ```

3. **Test touch input:**
   ```bash
   evtest
   # Select the touch device and test by touching the screen
   ```

4. **Verify GPIO configuration:**
   ```bash
   cat /sys/kernel/debug/gpio
   ```

### Notes:

- The display's HDMI output is handled separately and doesn't require this overlay
- Touch orientation may need adjustment via the override parameters depending on display mounting
- The I2C bus speed is set to 100kHz for compatibility
- First boot after applying the overlay may take slightly longer as the driver initializes

### References:

- ED-HMI3010-101C Datasheet: https://edatec.cn/docs/assets/hmi3010-101c/
- FT5x06 Driver Documentation: Linux kernel docs
- Raspberry Pi Device Tree Guide: https://www.raspberrypi.com/documentation/computers/configuration.html
