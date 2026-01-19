# Migration Guide: Supabase Storage → API Upload System

## Overview

This guide helps you migrate from direct Supabase/Digital Ocean storage to the new API-based upload system.

## What Changed

### Before (Old System)

```swift
// Direct upload to Digital Ocean Spaces via StorageService
let photoKey = try await StorageService.shared.uploadPhoto(imageData, userId: user.id)

let post = try await PostService.shared.createPost(
    userId: user.id,
    username: user.username,
    caption: caption,
    location: location,
    tags: tags,
    photoUrl: photoKey
)
```

### After (New System)

```swift
// Three-step upload via API server
let filename = "\(UUID().uuidString).jpg"
let recordId = try await ImageUploadService.shared.uploadImages(
    userId: user.id,
    images: [(key: "1", data: imageData, filename: filename)]
)
let photoUrl = "\(user.id)/\(recordId)/\(filename)"

let post = try await PostService.shared.createPost(
    userId: user.id,
    username: user.username,
    caption: caption,
    location: location,
    tags: tags,
    photoUrl: photoUrl
)
```

## Key Differences

| Aspect | Old System | New System |
|--------|-----------|------------|
| **Upload destination** | Direct to Digital Ocean | Via API → Digital Ocean |
| **URL generation** | Client generates key | Server generates recordId |
| **Security** | Client has storage credentials | Server manages credentials |
| **Tracking** | No upload tracking | Server tracks all uploads |
| **Validation** | Client-side only | Server + client validation |
| **Retries** | Manual implementation | Built-in with backoff |

## File Changes

### ✅ Already Migrated

**AppState.swift** - `createPost()` method updated

### 📝 May Need Updates

**StorageService.swift** - Can be removed if no longer used

**SupabaseConfig.swift** - Storage credentials may be removable

### ➕ New Files Added

- `ImageUploadService.swift`
- `ImageUploadModels.swift`
- `UploadConfig.swift`
- `ImageUploadExample.swift`
- `ImageUploadTests.swift`
- `UploadDebugView.swift`

## Code Changes Required

### 1. Update Direct Uploads

If you have other places using `StorageService`, update them:

**Find:**
```swift
let photoKey = try await StorageService.shared.uploadPhoto(imageData, userId: userId)
```

**Replace with:**
```swift
let filename = "\(UUID().uuidString).jpg"
let recordId = try await ImageUploadService.shared.uploadImages(
    userId: userId,
    images: [(key: "1", data: imageData, filename: filename)]
)
let photoUrl = "\(userId)/\(recordId)/\(filename)"
```

### 2. Update Photo URL Construction

**Find:**
```swift
// Old format: just the key
let photoUrl = photoKey
```

**Replace with:**
```swift
// New format: userId/recordId/filename
let photoUrl = "\(userId)/\(recordId)/\(filename)"
```

### 3. Update Image Loading

Photo URLs now have a different format but still work with Digital Ocean Spaces:

**Old URL:**
```
user_123abc_1234567890_photo.jpg
```

**New URL:**
```
user_123abc/696d27b8191ac75240be45fa/photo.jpg
```

Both resolve to the same Digital Ocean Spaces bucket, just different paths.

## Database Considerations

### Photo URL Format Change

Existing posts in database have URLs in old format. New posts will have URLs in new format.

**Options:**

1. **Keep both formats** (Recommended for migration)
   - Old URLs continue to work
   - New URLs use new format
   - No database migration needed

2. **Migrate all URLs** (More complex)
   - Update all existing photo URLs in database
   - Requires data migration script
   - Ensures consistency

### Example: Handle Both Formats

```swift
func fullPhotoURL(for photoPath: String) -> URL {
    let baseURL = "https://turf.turf.nyc3.digitaloceanspaces.com"
    
    // Check if it's the new format (contains /)
    if photoPath.contains("/") {
        // New format: user_id/record_id/filename
        return URL(string: "\(baseURL)/\(photoPath)")!
    } else {
        // Old format: just the key
        return URL(string: "\(baseURL)/\(photoPath)")!
    }
}
```

## Configuration Updates

### 1. Add API Base URL

Create or update `UploadConfig.swift`:

```swift
static let apiBaseURL: String = {
    #if DEBUG
    return "http://localhost:3000"
    #else
    return "https://api.turf.nyc"
    #endif
}()
```

### 2. Update Info.plist (if needed)

If using localhost on iOS 14+, ensure App Transport Security allows local connections:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>
```

## Testing Migration

### 1. Test New Upload

```swift
// In UploadDebugView or test
Task {
    guard let imageData = ImageUploadExample.generateTestImage() else { return }
    
    do {
        let photoUrl = try await ImageUploadExample.uploadSingleImage(
            userId: "test_user",
            imageData: imageData
        )
        print("✅ New upload works! URL: \(photoUrl)")
    } catch {
        print("❌ New upload failed: \(error)")
    }
}
```

### 2. Verify Old URLs Still Load

```swift
// Test that existing images still load
AsyncImage(url: oldPhotoURL) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
```

### 3. Test End-to-End Flow

1. Create a post with the new system
2. Verify it appears in feed
3. Verify image loads correctly
4. Verify photo URL format in database

## Rollback Plan

If you need to rollback to the old system:

### 1. Revert AppState Changes

```swift
// Revert to old implementation
let photoKey = try await StorageService.shared.uploadPhoto(imageData, userId: user.id)
```

### 2. Keep Old Files

Don't delete `StorageService.swift` until fully migrated and tested.

### 3. Database Compatibility

Since we're keeping both URL formats compatible, no database changes needed.

## Cleanup After Migration

Once fully migrated and tested:

### Optional Removals

1. **Remove StorageService.swift** (if no longer used)
2. **Remove storage credentials** from `SupabaseConfig.swift`
3. **Remove AWS signing code** (if not used elsewhere)

### Keep These Files

- ✅ `ImageUploadService.swift`
- ✅ `ImageUploadModels.swift`
- ✅ `UploadConfig.swift`
- ✅ All new upload-related files

## Troubleshooting Migration

### Issue: Old images don't load

**Cause:** URL format changed

**Fix:** Implement URL format detection (see "Handle Both Formats" above)

### Issue: New uploads fail

**Cause:** API server not configured

**Fix:** 
- Verify API server is running
- Check `UploadConfig.apiBaseURL`
- Test with UploadDebugView

### Issue: Mixed URL formats in database

**Cause:** Gradual migration

**Fix:** This is expected! Both formats should work simultaneously.

## Performance Comparison

### Old System

- Direct upload to storage ✅ Fast
- Client manages credentials ⚠️ Security risk
- No server tracking ❌ No analytics
- Manual retry logic ⚠️ Error-prone

### New System

- Upload via presigned URLs ✅ Fast
- Server manages credentials ✅ Secure
- Server tracks uploads ✅ Analytics enabled
- Built-in retry logic ✅ Robust
- Parallel uploads ✅ Even faster

## Security Improvements

### Before
- Client had storage access keys
- Direct write access to bucket
- No upload validation
- No audit trail

### After
- Server manages credentials ✅
- Time-limited presigned URLs ✅
- Server-side validation ✅
- Complete audit trail ✅

## Next Steps

1. ✅ Review this migration guide
2. ✅ Test new upload system with UploadDebugView
3. ✅ Deploy API server with upload endpoints
4. ✅ Update production API URL in UploadConfig
5. ✅ Monitor uploads in production
6. ✅ Consider migrating old photo URLs (optional)
7. ✅ Remove old StorageService (when safe)

## API Server Requirements

Your API server must implement:

### Required Endpoints

```javascript
// POST /images/upload
// - Generate presigned URLs
// - Store upload record
// - Return recordId and URLs

// POST /images/:recordId/confirm
// - Verify uploads completed
// - Update record status
// - Return success response
```

### Example (Node.js/Express)

```javascript
const AWS = require('aws-sdk');
const express = require('express');

const app = express();
const s3 = new AWS.S3({/* config */});

app.post('/images/upload', async (req, res) => {
    const { userId, metadata, images } = req.body;
    
    // Generate recordId
    const recordId = generateUniqueId();
    
    // Generate presigned URLs
    const uploads = images.map(img => ({
        filename: img.filename,
        presignedUrl: s3.getSignedUrl('putObject', {
            Bucket: 'turf',
            Key: `${userId}/${recordId}/${img.filename}`,
            ContentType: img.contentType,
            Expires: 3600 // 1 hour
        })
    }));
    
    // Store upload record
    await db.uploads.create({
        recordId,
        userId,
        metadata,
        images: images.map(img => img.filename),
        status: 'pending'
    });
    
    res.json({ recordId, uploads });
});

app.post('/images/:recordId/confirm', async (req, res) => {
    const { recordId } = req.params;
    
    // Update record
    await db.uploads.update(recordId, { status: 'confirmed' });
    
    res.json({
        success: true,
        recordId,
        message: 'Uploads confirmed'
    });
});
```

## Support

- 📖 Full docs: `IMAGE-UPLOAD-API.md`
- 🚀 Quick reference: `QUICK-REFERENCE.md`
- 📊 Implementation details: `IMPLEMENTATION-SUMMARY.md`
- 💻 Code examples: `ImageUploadExample.swift`

---

**Migration complete!** 🎉

Your app now uses a more secure, trackable, and robust upload system.
