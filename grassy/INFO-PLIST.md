# Required Info.plist Additions

Add these keys to your `Info.plist` file:

## Photo Library Access
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Grassy needs access to your photos so you can share them with the community.</string>
```

## Camera Access (if you add camera feature later)
```xml
<key>NSCameraUsageDescription</key>
<string>Grassy needs access to your camera to take photos.</string>
```

## Network Usage (for App Transport Security)
If you need to allow HTTP connections (not recommended), add:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>supabase.co</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
        <key>digitaloceanspaces.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## How to Add in Xcode:
1. Select your project in the Project Navigator
2. Select your app target
3. Go to the "Info" tab
4. Right-click in the list and select "Add Row"
5. Add each key and its value

## Alternative: Edit Info.plist directly
1. Right-click `Info.plist` in Project Navigator
2. Open As → Source Code
3. Add the XML entries above before the closing `</dict></plist>` tags
