# 🚀 Image Upload Quick Reference

## TL;DR

Upload images in 3 simple steps:

```swift
let recordId = try await ImageUploadService.shared.uploadImages(
    userId: "user_123",
    images: [(key: "1", data: imageData, filename: "photo.jpg")]
)
```

That's it! The service handles all three API calls automatically.

---

## 📋 Quick Commands

### Upload Single Image

```swift
let filename = "\(UUID().uuidString).jpg"
let recordId = try await ImageUploadService.shared.uploadImages(
    userId: user.id,
    images: [(key: "1", data: imageData, filename: filename)]
)
let photoUrl = "\(user.id)/\(recordId)/\(filename)"
```

### Upload Multiple Images

```swift
let images = [
    (key: "1", data: data1, filename: "photo1.jpg"),
    (key: "2", data: data2, filename: "photo2.jpg"),
    (key: "3", data: data3, filename: "photo3.jpg")
]
let recordId = try await ImageUploadService.shared.uploadImages(
    userId: user.id,
    images: images
)
```

### With Retry

```swift
let photoUrl = try await ImageUploadExample.uploadWithRetry(
    userId: user.id,
    imageData: imageData,
    maxRetries: 3
)
```

---

## 🌐 API Endpoints

### Development
```
http://localhost:3000/images/upload
http://localhost:3000/images/:id/confirm
```

### Production
```
https://api.turf.nyc/images/upload
https://api.turf.nyc/images/:id/confirm
```

---

## ⚙️ Key Configuration

```swift
// UploadConfig.swift

// API URLs (auto-switches based on DEBUG/RELEASE)
UploadConfig.apiBaseURL

// Timeouts
UploadConfig.requestTimeout = 30      // seconds
UploadConfig.uploadTimeout = 120      // seconds

// Image settings
UploadConfig.maxImageDimension = 2048
UploadConfig.compressionQuality = 0.8
UploadConfig.maxFileSize = 10MB

// Retry
UploadConfig.maxRetryAttempts = 3
```

---

## 🧪 Testing

### Debug View (Visual Testing)

```swift
#if DEBUG
NavigationLink("Debug Uploads") {
    UploadDebugView()
}
#endif
```

### Swift Testing

```swift
@Test func testImageUpload() async throws {
    let data = ImageUploadExample.generateTestImage()!
    let url = try await ImageUploadExample.uploadSingleImage(
        userId: "test",
        imageData: data
    )
    #expect(!url.isEmpty)
}
```

---

## 🎯 Files Reference

| File | Purpose |
|------|---------|
| `ImageUploadService.swift` | Main upload service (actor) |
| `ImageUploadModels.swift` | Request/response models |
| `UploadConfig.swift` | Configuration settings |
| `ImageUploadExample.swift` | Usage examples |
| `ImageUploadTests.swift` | Test suite |
| `UploadDebugView.swift` | Debug interface |
| `AppState.swift` | Integration point |

---

## 🔍 Photo URL Format

```
{userId}/{recordId}/{filename}

Example:
user_123abc/696d27b8191ac75240be45fa/photo.jpg

Full URL:
https://turf.turf.nyc3.digitaloceanspaces.com/user_123abc/696d27b8191ac75240be45fa/photo.jpg
```

---

## ⚠️ Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| Connection refused | API server not running | Start server: `npm start` |
| Invalid response | Wrong JSON format | Check API response matches models |
| Upload failed (403) | Bad presigned URL | Verify URL generation on server |
| Confirmation failed | Upload incomplete | Check network, verify all uploads |

---

## 🚦 Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success ✅ |
| 400 | Bad request (check your data) |
| 403 | Forbidden (check presigned URL) |
| 404 | Not found (check endpoint URL) |
| 500 | Server error (check API logs) |

---

## 📱 Integration in Views

### In CreatePostView (Already Integrated!)

```swift
// Just call this:
await appState.createPost(
    caption: caption,
    location: location,
    tags: tags,
    imageData: imageData
)

// AppState handles the upload automatically
```

---

## 🎨 Supported Formats

- ✅ JPEG (`.jpg`, `.jpeg`)
- ✅ PNG (`.png`)
- ✅ GIF (`.gif`)
- ✅ WebP (`.webp`)
- ✅ TIFF (`.tiff`, `.tif`)
- ✅ HEIC (Apple format)

Auto-detected via file headers!

---

## 💡 Pro Tips

1. **Always compress images** before upload:
   ```swift
   let compressed = ImageHelper.prepareForUpload(image)
   ```

2. **Use unique filenames**:
   ```swift
   let filename = "\(UUID().uuidString).jpg"
   ```

3. **Handle errors gracefully**:
   ```swift
   do {
       let recordId = try await upload(...)
   } catch {
       print("Upload failed: \(error.localizedDescription)")
       // Show user-friendly message
   }
   ```

4. **Test with debug view** before integrating

5. **Monitor upload times** in debug view

---

## 🔗 Documentation

- **Full API Docs**: `IMAGE-UPLOAD-API.md`
- **Implementation Details**: `IMPLEMENTATION-SUMMARY.md`
- **Code Examples**: `ImageUploadExample.swift`
- **Tests**: `ImageUploadTests.swift`

---

## 🚀 Quick Start Checklist

- [ ] Start API server (`npm start`)
- [ ] Open app in simulator
- [ ] Navigate to Upload Debug view
- [ ] Tap "Test Single Image Upload"
- [ ] Verify ✅ success
- [ ] Check Digital Ocean Spaces for file
- [ ] Integrate into your views
- [ ] Test in production environment

---

**Ready to upload! 📸**
