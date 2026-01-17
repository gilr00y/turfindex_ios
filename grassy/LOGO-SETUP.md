# Logo Setup Instructions

## Adding the Turf Index Logo to Your Project

### Step 1: Add Logo to Assets Catalog

1. In Xcode, open the Asset Catalog (usually `Assets.xcassets`)
2. Right-click in the assets list and select **"New Image Set"**
3. Name it `turf-index-logo`
4. Drag and drop your logo file (`turf-index-logo.png`) from `~/Downloads` into the **1x**, **2x**, or **3x** slot
   - For best results, use the **2x** slot if you have a standard resolution image
   - Xcode will automatically scale it for other resolutions
5. In the Attributes Inspector (right sidebar), set:
   - **Render As**: Original Image
   - **Resizing**: Preserve Vector Data (if available)

### Step 2: Create Additional Logo Variants (Optional)

For better flexibility, you might want to create these additional variants:

#### Transparent Background Version
If your logo has the dark navy background, create a transparent version:
1. Create a new image set called `turf-index-logo-transparent`
2. Use an image editing tool to remove the background
3. Add to assets

#### Icon-Only Version
Create a simplified version with just the circular icon (without text):
1. Create a new image set called `turf-icon`
2. Crop the logo to just the circular golf/chart scene
3. Add to assets

#### App Icon
To use the logo as your app icon:
1. In Assets, select **AppIcon**
2. Add appropriately sized versions of your logo
3. Required sizes:
   - 1024x1024 (App Store)
   - 60x60 @2x and @3x (iPhone)
   - 76x76 @2x (iPad)
   - Other sizes as prompted by Xcode

### Step 3: Verify Integration

The logo is already integrated in these views:
- ✅ **OnboardingView.swift** - Shows logo on login/signup screen
- ✅ **FeedView.swift** - "Turf Index" title in navigation bar
- ✅ Theme colors extracted from logo

### Troubleshooting

If the logo doesn't appear:
1. Check that the image set name matches exactly: `turf-index-logo`
2. Ensure the image is in the correct target (check Target Membership in File Inspector)
3. Clean build folder: **Product > Clean Build Folder** (Cmd+Shift+K)
4. Rebuild the project

If you need to use a fallback while setting up:
```swift
// Replace in OnboardingView.swift
Image("turf-index-logo")
```
with:
```swift
// Temporary fallback
if let image = UIImage(named: "turf-index-logo") {
    Image(uiImage: image)
} else {
    // Fallback icon while you set up assets
    VStack {
        Image(systemName: "chart.line.uptrend.xyaxis")
            .font(.system(size: 60))
        Image(systemName: "figure.golf")
            .font(.system(size: 60))
    }
    .foregroundStyle(TurfTheme.greenGradient)
}
```

## Color Palette Reference

The following colors have been extracted from your logo and are available in `Theme.swift`:

- **Lime Green** (#9ED12E) - Primary accent, from "TURF" text
- **Forest Green** (#228B22) - Secondary accent, from grass
- **Sky Blue** (#4AB5F5) - From sky background
- **Sun Orange** (#FFA500) - From sun
- **Sun Yellow** (#FFD700) - From sun rays and chart
- **Navy Background** (#172129) - From logo background
- **White** - From "INDEX" text

These are all available via `TurfTheme.limeGreen`, `TurfTheme.forestGreen`, etc.
