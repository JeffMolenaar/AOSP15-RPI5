# Simple Logo Boot Animation Template

This template creates a basic boot animation with a single static image (your logo).

## How to Use

1. **Replace the placeholder image:**
   - Place your logo as `part0/0000.png`
   - Recommended size: 800x600 pixels (or 600x800 for portrait mode)
   - PNG format with transparency supported

2. **Adjust resolution (if needed):**
   - Edit `desc.txt` and change `800 600` to match your image size
   - For portrait mode: `600 800 30`

3. **Create the boot animation ZIP:**
   ```bash
   cd simple-logo/
   zip -0qry -i \*.txt \*.png @ ../bootanimation.zip desc.txt part0
   ```

4. **Copy to your build:**
   ```bash
   cp ../bootanimation.zip /home/runner/work/AOSP15-RPI5/AOSP15-RPI5/customization/boot-animation/
   ```

## File Requirements

- Image must be named exactly: `0000.png` (with four zeros)
- Image must be in PNG format
- All images in part0 should be the same size
- ZIP must be created with `-0` flag (no compression)

## desc.txt Format

```
WIDTH HEIGHT FPS
p COUNT PAUSE FOLDER
```

Current configuration:
```
800 600 30
p 1 0 part0
```

This means:
- Animation is 800x600 pixels at 30 FPS
- Play `part0` folder once (`p 1 0 part0`)
- No pause, no loop

## Customization

To make the logo display longer before the system UI loads, you can add more frames with the same image or reduce FPS:

**Option 1: Add duplicate frames**
```bash
cp part0/0000.png part0/0001.png
cp part0/0000.png part0/0002.png
# etc... more frames = longer display time
```

**Option 2: Reduce FPS**
Edit desc.txt:
```
800 600 15
p 1 0 part0
```
Lower FPS = slower animation = image displays longer
