# Assets Checklist for Turf Index

## Required Assets

### 1. Main Logo (`turf-index-logo`)

**Location**: `~/Downloads/turf-index-logo.png`

**Setup in Xcode**:
1. Open `Assets.xcassets`
2. Right-click → New Image Set
3. Name: `turf-index-logo`
4. Drag and drop the logo file into the **2x** slot
5. In Attributes Inspector:
   - Render As: **Original Image**
   - Resizing: **Preserve Vector Data**

**Used in**:
- OnboardingView (200x200pt)
- TurfLogoView (fallback to generated icon if missing)

**Status**: ⚠️ Needs to be added

---

### 2. Icon-Only Logo (`turf-icon`) - Optional

**Description**: Just the circular golf/chart scene without text

**Setup**:
1. Crop the logo to just the circular icon portion
2. Create new Image Set: `turf-icon`
3. Add the cropped image

**Used in**:
- TurfLogoView icon-only style
- Small decorative elements
- Loading states

**Status**: ⬜️ Optional

---

### 3. Transparent Background Logo (`turf-index-logo-transparent`) - Optional

**Description**: Logo without the dark navy background

**Setup**:
1. Edit logo to remove background
2. Export as PNG with transparency
3. Create new Image Set: `turf-index-logo-transparent`
4. Add the transparent version

**Used in**:
- Light mode compatibility
- Overlays on various backgrounds
- Widget backgrounds

**Status**: ⬜️ Optional

---

## App Icon Setup

### Required Sizes

**Location**: `Assets.xcassets/AppIcon`

Add your logo in these sizes (or use Xcode auto-generator from 1024x1024):

- [ ] **1024x1024** - App Store (required)
- [ ] **180x180** - iPhone App @3x
- [ ] **120x120** - iPhone App @2x, iPhone Spotlight @3x
- [ ] **87x87** - iPhone Notifications @3x
- [ ] **80x80** - iPhone Spotlight @2x, iPad Notifications @2x
- [ ] **60x60** - iPhone Notifications @2x
- [ ] **58x58** - iPhone Spotlight, Settings @2x
- [ ] **40x40** - iPhone Spotlight, Settings
- [ ] **152x152** - iPad App @2x
- [ ] **76x76** - iPad App
- [ ] **29x29** - Settings

**Quick Setup**:
1. Create a 1024x1024 version of the logo
2. In Xcode, Assets → AppIcon → Right-click → App Icon & Launch Image → New iOS App Icon
3. Drag the 1024x1024 image → Xcode will auto-generate all sizes

---

## Color Assets (Future Enhancement)

You can optionally add color assets for better theme management:

### Setup Color Set:
1. In Assets, click + → New Color Set
2. Name: `TurfPrimary`, `TurfSecondary`, etc.
3. Set light/dark mode variants

### Example Colors to Add:
- `TurfPrimary` → #9ED12E (Lime Green)
- `TurfSecondary` → #228B22 (Forest Green)
- `TurfSkyBlue` → #4AB5F5
- `TurfOrange` → #FFA500
- `TurfYellow` → #FFD700
- `TurfNavy` → #172129

### Usage:
```swift
// Instead of TurfTheme.limeGreen
Color("TurfPrimary")

// Benefits: Supports light/dark mode variants in Assets
```

**Status**: ⬜️ Optional (Theme.swift works great as-is)

---

## Alternative Image Assets (Optional)

### Golf Course Photo
**Name**: `default-course-photo`
**Usage**: Placeholder for missing post images
**Size**: Any aspect ratio, 1200x800 recommended

### Background Patterns
**Name**: `turf-pattern`
**Usage**: Subtle background texture
**Description**: Grass or golf course pattern

### Achievement Icons
Custom achievement/badge graphics if you want to go beyond SF Symbols

---

## Asset Organization Tips

### Folder Structure in Assets:
```
Assets.xcassets/
├── AppIcon.appiconset/
├── Logos/
│   ├── turf-index-logo.imageset/
│   ├── turf-icon.imageset/
│   └── turf-index-logo-transparent.imageset/
├── Colors/
│   ├── TurfPrimary.colorset/
│   └── TurfSecondary.colorset/
└── Images/
    └── default-course-photo.imageset/
```

To create folders:
1. Right-click in Assets
2. Select "New Folder"
3. Name it (e.g., "Logos")
4. Drag image sets into the folder

---

## Verification Checklist

After adding assets, verify:

- [ ] Logo appears in OnboardingView
- [ ] App icon shows in simulator/device
- [ ] No console warnings about missing assets
- [ ] Logo renders correctly in light mode
- [ ] Logo renders correctly in dark mode
- [ ] Logo is sharp (not blurry) at all sizes
- [ ] App icon passes App Store validation

---

## Quick Test

Add this to any view to test asset loading:

```swift
VStack(spacing: 20) {
    // Test main logo
    if UIImage(named: "turf-index-logo") != nil {
        Text("✅ Main logo loaded")
            .foregroundStyle(.green)
    } else {
        Text("⚠️ Main logo missing")
            .foregroundStyle(.orange)
    }
    
    // Test icon
    if UIImage(named: "turf-icon") != nil {
        Text("✅ Icon loaded")
            .foregroundStyle(.green)
    } else {
        Text("ℹ️ Icon optional")
            .foregroundStyle(.blue)
    }
    
    // Show actual images
    Image("turf-index-logo")
        .resizable()
        .scaledToFit()
        .frame(width: 200)
    
    TurfLogoView(size: .medium, style: .full)
}
```

---

## Troubleshooting

### Logo doesn't appear
1. Check asset name is exactly `turf-index-logo` (no spaces, hyphens matter)
2. Verify Target Membership includes your app target
3. Clean Build Folder (Cmd+Shift+K) and rebuild
4. Check file is actually in the .imageset folder

### Logo appears blurry
1. Ensure you're using @2x or @3x resolution
2. Check "Preserve Vector Data" if using PDF
3. Use higher resolution source image

### Wrong colors in app icon
1. Check color profile of source image (use sRGB)
2. Ensure no transparency in app icon images
3. Use PNG format for app icons

---

## File Locations Reference

```
Your Mac:
~/Downloads/turf-index-logo.png

Xcode Project:
YourProject/
└── Assets.xcassets/
    └── turf-index-logo.imageset/
        ├── turf-index-logo@2x.png
        └── Contents.json
```

---

**Ready to add your assets?** Follow the **LOGO-SETUP.md** guide for detailed step-by-step instructions!
