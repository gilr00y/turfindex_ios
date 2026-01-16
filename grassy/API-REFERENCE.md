# API Reference

## Services Architecture

### AuthService (Actor)
Handles all authentication operations with Supabase.

```swift
// Sign up new user
await AuthService.shared.signUp(
    email: "user@example.com",
    password: "password123",
    username: "cooluser"
) -> UserProfile

// Sign in existing user
await AuthService.shared.signIn(
    email: "user@example.com",
    password: "password123"
) -> UserProfile

// Sign out
await AuthService.shared.signOut()

// Get current session
await AuthService.shared.getCurrentSession() -> Session?

// Get current user profile
await AuthService.shared.getCurrentUserProfile() -> UserProfile?

// Check username availability
await AuthService.shared.isUsernameAvailable("newusername") -> Bool

// Update username
await AuthService.shared.updateUsername("newusername", userId: "user-id")
```

---

### PostService (Actor)
Manages posts in Supabase database.

```swift
// Create new post
await PostService.shared.createPost(
    userId: "user-id",
    username: "cooluser",
    caption: "Amazing sunset!",
    location: "San Francisco",
    tags: ["sunset", "nature"],
    photoUrl: "user-id/photo-key.jpg"
) -> Post

// Fetch all posts (paginated)
await PostService.shared.fetchAllPosts(
    limit: 50,
    offset: 0
) -> [Post]

// Fetch user's posts
await PostService.shared.fetchUserPosts(
    userId: "user-id",
    limit: 50
) -> [Post]

// Fetch posts by tag
await PostService.shared.fetchPostsByTag(
    "sunset",
    limit: 50
) -> [Post]

// Update post
await PostService.shared.updatePost(
    id: "post-id",
    caption: "Updated caption",
    location: "New location",
    tags: ["new", "tags"]
)

// Delete post
await PostService.shared.deletePost(
    id: "post-id",
    photoUrl: "user-id/photo-key.jpg"
)

// Subscribe to new posts (real-time)
for await post in PostService.shared.subscribeToNewPosts() {
    // Handle new post
}
```

---

### StorageService (Actor)
Handles photo uploads to Digital Ocean Spaces.

```swift
// Upload photo
await StorageService.shared.uploadPhoto(
    imageData,
    userId: "user-id"
) -> String // Returns photo key

// Delete photo
await StorageService.shared.deletePhoto(
    key: "user-id/photo-key.jpg"
)

// Get photo URL
SpacesConfig.photoURL(for: "user-id/photo-key.jpg") -> URL?
```

---

### AppState (@Observable)
Main app state manager - coordinates all services.

```swift
// Authentication
await appState.signUp(
    email: String,
    password: String,
    username: String
)

await appState.signIn(
    email: String,
    password: String
)

await appState.logout()

// Posts
await appState.createPost(
    caption: String,
    location: String,
    tags: [String],
    imageData: Data
)

await appState.fetchPosts()

await appState.deletePost(Post)

await appState.refreshPosts()

// Image caching
appState.cachedImage(for: String) -> UIImage?
appState.cacheImage(UIImage, for: String)

// State properties
appState.currentUser: UserProfile?
appState.posts: [Post]
appState.isLoading: Bool
appState.error: Error?
```

---

### ImageHelper (Enum)
Static utilities for image processing.

```swift
// Prepare image for upload (resize + compress)
ImageHelper.prepareForUpload(
    uiImage,
    maxDimension: 2048,
    compressionQuality: 0.8
) -> Data?

// Generate thumbnail
ImageHelper.generateThumbnail(
    uiImage,
    size: 200
) -> UIImage

// Get file size string
ImageHelper.fileSize(of: imageData) -> String
// e.g., "1.2 MB"
```

---

## Data Models

### UserProfile
```swift
struct UserProfile: Identifiable, Codable {
    let id: String              // Supabase user ID
    var username: String
    var createdAt: Date
    var updatedAt: Date?
}
```

### Post
```swift
struct Post: Identifiable, Codable {
    let id: String              // UUID
    let userId: String          // User's ID
    let username: String        // Cached username
    var caption: String
    var location: String
    var tags: [String]
    let photoUrl: String        // S3 key
    let createdAt: Date
    let updatedAt: Date?
}
```

---

## Database Schema

### profiles
```sql
id          UUID PRIMARY KEY (references auth.users)
username    TEXT UNIQUE NOT NULL
created_at  TIMESTAMPTZ DEFAULT NOW()
updated_at  TIMESTAMPTZ
```

### posts
```sql
id          UUID PRIMARY KEY
user_id     UUID REFERENCES profiles(id)
username    TEXT NOT NULL
caption     TEXT DEFAULT ''
location    TEXT DEFAULT ''
tags        TEXT[] DEFAULT '{}'
photo_url   TEXT NOT NULL
created_at  TIMESTAMPTZ DEFAULT NOW()
updated_at  TIMESTAMPTZ
```

---

## Error Handling

### AuthError
- `signUpFailed`
- `signInFailed`
- `invalidCredentials`
- `usernameTaken`
- `networkError`

### PostError
- `createFailed`
- `fetchFailed`
- `updateFailed`
- `deleteFailed`
- `unauthorized`

### StorageError
- `uploadFailed`
- `deleteFailed`
- `invalidImage`

---

## Environment Configuration

### Supabase
```swift
SupabaseConfig.url          // Project URL
SupabaseConfig.anonKey      // Public anon key
SupabaseConfig.client       // Supabase client instance
```

### Digital Ocean Spaces
```swift
SpacesConfig.endpoint       // Region endpoint
SpacesConfig.region         // Region code
SpacesConfig.bucket         // Space name
SpacesConfig.accessKey      // API access key
SpacesConfig.secretKey      // API secret key
```

---

## Usage Examples

### Complete User Flow
```swift
// 1. Sign up
await appState.signUp(
    email: "jane@example.com",
    password: "securepass123",
    username: "jane_photos"
)

// 2. Create post
let imageData = ImageHelper.prepareForUpload(selectedImage)
await appState.createPost(
    caption: "Beautiful day!",
    location: "Central Park",
    tags: ["nature", "sunny"],
    imageData: imageData
)

// 3. View feed
await appState.fetchPosts()
for post in appState.posts {
    print(post.username, post.caption)
}

// 4. Delete post
await appState.deletePost(myPost)

// 5. Logout
await appState.logout()
```

---

## Security Notes

1. **Row Level Security (RLS)** enabled on all tables
2. **Anon key** is safe to use in client apps
3. **Service role key** should NEVER be in client code
4. **Spaces** must be public for direct image URLs
5. **AWS Signature V4** used for authenticated S3 requests
