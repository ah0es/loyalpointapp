# Apple Wallet Image Assets

This directory contains the required image assets for Apple Wallet passes.

## Required Images:

### Icons
- `icon.png` - 29x29 pixels (standard resolution)
- `icon@2x.png` - 58x58 pixels (retina resolution)

### Logos  
- `logo.png` - 160x50 pixels (standard resolution)
- `logo@2x.png` - 320x100 pixels (retina resolution)

## Image Requirements:

1. **Format:** PNG with transparency
2. **Background:** Transparent or white
3. **Content:** Your company logo or app icon
4. **Quality:** High resolution, crisp edges
5. **Colors:** Should work on both light and dark backgrounds

## Creating Images:

### Option 1: Design Tools
- Use Figma, Sketch, or Adobe Illustrator
- Create at the required pixel dimensions
- Export as PNG with transparency

### Option 2: Online Tools
- Use online image resizers
- Start with a high-resolution logo
- Resize to exact dimensions

### Option 3: Placeholder Images
For testing, you can use placeholder images:
- Visit https://via.placeholder.com/29x29/4285F4/FFFFFF?text=L
- Replace dimensions and colors as needed
- Download and save with correct filenames

## File Structure:
```
assets/images/apple_wallet/
├── icon.png          (29x29)
├── icon@2x.png       (58x58)
├── logo.png          (160x50)
└── logo@2x.png       (320x100)
```

## Next Steps:
1. Create or obtain your company logo
2. Resize to required dimensions
3. Save as PNG files with exact names
4. Place in this directory
5. Update pubspec.yaml to include assets
