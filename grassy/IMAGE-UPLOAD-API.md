# Image Upload System Documentation

## Overview

The app now uses a standalone API server for image uploads instead of Supabase storage. This system implements a three-step upload process with presigned URLs to Digital Ocean Spaces.

## Architecture

### Flow Diagram

```
iOS App → API Server → Digital Ocean Spaces
   ↓           ↓              ↓
Request     Generate       Store
URLs        Presigned      Images
   ↓         URLs             ↓
Upload         ↓          Complete
Images    ←────┘             ↓
   ↓                         ↓
Confirm   →  Verify  →   Success
```

### Three-Step Process

1. **Request Presigned URLs**
   - POST to `/images/upload`
   - Send user ID, metadata, and image info
   - Receive `recordId` and presigned URLs

2. **Upload to Presigned URLs**
   - PUT each image to its presigned URL
   - Upload happens directly to Digital Ocean Spaces
   - Parallel uploads for better performance

3. **Confirm Uploads**
   - POST to `/images/:recordId/confirm`
   - Verify all uploads completed successfully

## Files

### Core Implementation

- **ImageUploadModels.swift** - Request/response data models
- **ImageUploadService.swift** - Three-step upload orchestration
- **ImageUploadExample.swift** - Usage examples and utilities

### Updated Files

- **AppState.swift** - Updated `createPost()` to use new service

## API Specification

### 1. Request Presigned URLs

**Endpoint:** `POST /images/upload`

**Request:**
```json
{
  "userId": "user_123abc",
  "metadata": {
    "uploadSource": "mobile_app",
    "sessionId": "sess_xyz789",
    "timestamp": "2026-01-18T10:30:00Z"
  },
  "images": [
    {
      "key": "1",
      "filename": "profile_photo.jpg",
      "contentType": "image/jpeg"
    }
  ]
}
```

**Response:**
```json
{
  "recordId": "696d27b8191ac75240be45fa",
  "uploads": [
    {
      "filename": "profile_photo.jpg",
      "presignedUrl": "https://turf.turf.nyc3.digitaloceanspaces.com/..."
    }
  ]
}
```

### 2. Upload Images

**Endpoint:** Presigned URL from step 1

**Request:**
- Method: `PUT`
- Headers: `Content-Type: image/jpeg` (or appropriate type)
- Body: Raw image data

**Response:**
- Status: `200 OK` (no body)

### 3. Confirm Uploads

**Endpoint:** `POST /images/:recordId/confirm`

**Request:**
```json
{}
```

**Response:**
```json
{
  "success": true,
  "recordId": "696d27b8191ac75240be45fa",
  "message": "Uploads confirmed"
}
```

## Usage

### Basic Upload (Single Image)

```swift
import Foundation

let imageData = // ... your image data
let userId = "user_123abc"

let recordId = try await ImageUploadService.shared.uploadImages(
    userId: userId,
    images: [
        (key: "1", data: imageData, filename: "photo.jpg")
    ]
)

print("Uploaded! Record ID: \(recordId)")
```

### Multiple Images

```swift
let images = [
    (key: "1", data: imageData1, filename: "photo1.jpg"),
    (key: "2", data: imageData2, filename: "photo2.jpg"),
    (key: "3", data: imageData3, filename: "photo3.jpg")
]

let recordId = try await ImageUploadService.shared.uploadImages(
    userId: userId,
    images: images
)

// All images uploaded in parallel
```

### Creating a Post with Upload

```swift
@MainActor
func createPost(caption: String, location: String, tags: [String], imageData: Data) async {
    guard let user = currentUser else { return }
    
    do {
        let filename = "\(UUID().uuidString).jpg"
        
        // Upload image
        let recordId = try await ImageUploadService.shared.uploadImages(
            userId: user.id,
            images: [(key: "1", data: imageData, filename: filename)]
        )
        
        // Construct photo URL
        let photoUrl = "\(user.id)/\(recordId)/\(filename)"
        
        // Create post in database
        let post = try await PostService.shared.createPost(
            userId: user.id,
            username: user.username,
            caption: caption,
            location: location,
            tags: tags,
            photoUrl: photoUrl
        )
        
        posts.insert(post, at: 0)
    } catch {
        print("Error: \(error)")
    }
}
```

### With Retry Logic

```swift
let photoUrl = try await ImageUploadExample.uploadWithRetry(
    userId: userId,
    imageData: imageData,
    maxRetries: 3
)
```

## Configuration

### API Base URL

Default: `http://localhost:3000`

To change the API endpoint:

```swift
let uploadService = ImageUploadService(baseURL: "https://api.yourserver.com")
```

For production, update the default in `ImageUploadService.swift`:

```swift
init(baseURL: String = "https://api.production.com") {
    self.baseURL = baseURL
}
```

## Error Handling

### Error Types

```swift
enum ImageUploadError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int)
    case missingPresignedURLs
    case missingPresignedURL(filename: String)
    case invalidPresignedURL
    case uploadFailed(statusCode: Int)
    case confirmationFailed(statusCode: Int, message: String?)
}
```

### Example Error Handling

```swift
do {
    let recordId = try await ImageUploadService.shared.uploadImages(...)
} catch ImageUploadError.serverError(let statusCode) {
    print("Server error: \(statusCode)")
} catch ImageUploadError.uploadFailed(let statusCode) {
    print("Upload failed: \(statusCode)")
} catch {
    print("Unknown error: \(error.localizedDescription)")
}
```

## Content Type Detection

The system automatically detects image content types:

- **JPEG** - `image/jpeg`
- **PNG** - `image/png`
- **GIF** - `image/gif`
- **WebP** - `image/webp`
- **TIFF** - `image/tiff`

Detection happens via the `Data.mimeType` extension in `ImageUploadModels.swift`.

## Photo URL Format

Uploaded photos are stored with this path structure:

```
{userId}/{recordId}/{filename}
```

Example:
```
user_123abc/696d27b8191ac75240be45fa/profile_photo.jpg
```

Full URL (on Digital Ocean Spaces):
```
https://turf.turf.nyc3.digitaloceanspaces.com/user_123abc/696d27b8191ac75240be45fa/profile_photo.jpg
```

## Performance Considerations

### Parallel Uploads

Multiple images are uploaded in parallel using `withThrowingTaskGroup`:

```swift
try await withThrowingTaskGroup(of: Void.self) { group in
    for image in images {
        group.addTask {
            try await self.uploadSingleImage(...)
        }
    }
    try await group.waitForAll()
}
```

### Image Compression

Always compress images before uploading:

```swift
// From ImageHelper
let compressedData = ImageHelper.prepareForUpload(
    uiImage,
    maxDimension: 2048,
    compressionQuality: 0.8
)
```

### Caching

Uploaded images are cached in `AppState`:

```swift
if let image = UIImage(data: imageData) {
    imageCache[photoUrl] = image
}
```

## Testing

### Unit Tests

```swift
import Testing

@Test("Upload single image")
func testSingleImageUpload() async throws {
    guard let testData = ImageUploadExample.generateTestImage() else {
        Issue.record("Failed to generate test image")
        return
    }
    
    let photoUrl = try await ImageUploadExample.uploadSingleImage(
        userId: "test_user",
        imageData: testData
    )
    
    #expect(!photoUrl.isEmpty)
    #expect(photoUrl.contains("test_user"))
}

@Test("Upload multiple images")
func testMultipleImageUpload() async throws {
    let images = [
        ImageUploadExample.generateTestImage()!,
        ImageUploadExample.generateTestImage()!
    ]
    
    let result = try await ImageUploadExample.uploadMultipleImages(
        userId: "test_user",
        imageDatas: images
    )
    
    #expect(result.photoUrls.count == 2)
    #expect(!result.recordId.isEmpty)
}
```

### Manual Testing

```swift
// In your view or playground
Task {
    await ImageUploadExample.testUploadFlow()
}
```

## Migration from Old System

### Before (Supabase Storage)

```swift
let photoKey = try await StorageService.shared.uploadPhoto(imageData, userId: user.id)
```

### After (New API System)

```swift
let filename = "\(UUID().uuidString).jpg"
let recordId = try await ImageUploadService.shared.uploadImages(
    userId: user.id,
    images: [(key: "1", data: imageData, filename: filename)]
)
let photoUrl = "\(user.id)/\(recordId)/\(filename)"
```

## Troubleshooting

### Common Issues

**1. Connection Refused**
- Ensure API server is running on `localhost:3000`
- Check firewall settings

**2. Invalid Response**
- Verify API server response format matches models
- Check JSON encoding/decoding

**3. Upload Failed**
- Presigned URLs expire after 1 hour
- Ensure Content-Type header is set correctly
- Check image data is valid

**4. Confirmation Failed**
- Verify all images uploaded successfully
- Check recordId is correct
- Ensure API server received uploads

### Debug Logging

Add logging to track upload progress:

```swift
print("Step 1: Requesting presigned URLs...")
let recordId = try await requestPresignedURLs(...)
print("Step 1 complete: \(recordId)")

print("Step 2: Uploading images...")
try await uploadToPresignedURLs(...)
print("Step 2 complete")

print("Step 3: Confirming uploads...")
try await confirmUploads(recordId)
print("Step 3 complete")
```

## Security Considerations

- ✅ Presigned URLs are time-limited (default 1 hour)
- ✅ Upload happens directly to storage (no server proxy)
- ✅ Server validates user permissions before generating URLs
- ✅ HTTPS for all API communication (in production)
- ⚠️ Implement rate limiting on API server
- ⚠️ Add file size validation
- ⚠️ Validate image content types on server

## Future Enhancements

- [ ] Progress tracking for uploads
- [ ] Resume interrupted uploads
- [ ] Background upload queue
- [ ] Thumbnail generation
- [ ] Image optimization on server
- [ ] Bulk delete API
- [ ] CDN integration
- [ ] Client-side encryption

---

**Ready to use!** The system is fully integrated and ready for testing with your API server.
