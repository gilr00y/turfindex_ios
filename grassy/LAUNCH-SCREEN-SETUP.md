# Launch Screen Setup Instructions

## What We've Implemented

### 1. LaunchScreenView.swift
A SwiftUI view that displays:
- Dark navy background (`TurfTheme.navyBackground`)
- `turf-index-no-bg` logo centered at 250x250 points

### 2. ContentView.swift Updates
Added launch screen logic that:
- Shows `LaunchScreenView` on app startup
- Displays for 1.5 seconds
- Fades out with a smooth animation
- Transitions to the main leaderboard view

## Xcode Configuration (Optional but Recommended)

For the best user experience, configure Xcode's native launch screen:

### Method 1: Launch Screen Storyboard (Traditional)

1. **Create Launch Screen Storyboard:**
   - File → New → File
   - Choose "Launch Screen" under User Interface
   - Name it `LaunchScreen.storyboard`

2. **Design the Launch Screen:**
   - Add a View (full screen)
   - Set background color to navy: `#172129` (RGB: 23, 33, 41)
   - Add an Image View
   - Set image to `turf-index-no-bg`
   - Set Content Mode to "Aspect Fit"
   - Center horizontally and vertically
   - Add constraints (width/height 250, centered)

3. **Configure in Project Settings:**
   - Select your project in navigator
   - Select your app target
   - Go to "Info" tab
   - Under "Launch Screen Interface File Base Name", ensure it says `LaunchScreen`

### Method 2: Info.plist Configuration (iOS 14+)

Add to your `Info.plist`:

```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIImageName</key>
    <string>turf-index-no-bg</string>
    <key>UIColorName</key>
    <string>NavyBackground</string>
    <key>UIImageRespectsSafeAreaInsets</key>
    <false/>
</dict>
```

### Method 3: Use Asset Catalog (Modern Approach)

1. **Add Launch Screen to Assets:**
   - Open Assets.xcassets
   - Right-click → New Launch Image
   - Add your logo at 1x, 2x, 3x sizes

2. **Configure Background Color:**
   - In Assets.xcassets, create a new Color Set named "NavyBackground"
   - Set color to `#172129`
   - Universal appearance

3. **Update Info.plist:**
```xml
<key>UILaunchScreen</key>
<dict>
    <key>UIColorName</key>
    <string>NavyBackground</string>
    <key>UIImageName</key>
    <string>turf-index-no-bg</string>
</dict>
```

## Asset Requirements

Make sure `turf-index-no-bg.png` is added to your Assets.xcassets:

1. Open `Assets.xcassets`
2. Right-click → New Image Set
3. Name it `turf-index-no-bg`
4. Drag your logo image files:
   - 1x: Base resolution
   - 2x: Retina (@2x)
   - 3x: iPhone Plus/Pro Max (@3x)

## Testing

1. **Clean Build Folder:**
   - Product → Clean Build Folder (⇧⌘K)

2. **Delete App from Simulator/Device:**
   - Long press app icon → Remove App

3. **Rebuild and Run:**
   - The launch screen should appear for ~1.5 seconds
   - Then fade to the leaderboard

## Notes

- The SwiftUI implementation works immediately without Xcode configuration
- Native launch screen (storyboard/Info.plist) shows before any Swift code runs
- SwiftUI version shows after app initialization but before main content
- For best UX, use both: native for immediate display, SwiftUI for smooth transition
