# App Flow Diagram

## Visual Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         grassyApp                            │
│                      (@main entry)                           │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      ContentView                             │
│             (Routes based on auth state)                     │
│                                                              │
│  ┌──────────────────────┐      ┌──────────────────────┐    │
│  │  No User?            │      │  Has User?           │    │
│  │  → OnboardingView    │      │  → FeedView          │    │
│  └──────────────────────┘      └──────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                         │
          ┌──────────────┴──────────────┐
          ▼                             ▼
┌──────────────────────┐      ┌──────────────────────┐
│   OnboardingView     │      │      FeedView         │
│                      │      │                       │
│  • Email field       │      │  • Navigation bar     │
│  • Password field    │      │  • User menu          │
│  • Username field    │      │  • Create post button │
│  • Sign Up/Sign In   │      │  • Pull to refresh    │
│                      │      │  • Posts list         │
│  ┌────────────┐     │      │                       │
│  │ AppState   │─────┼──────┤  ┌────────────┐      │
│  │  .signUp() │     │      │  │ AppState   │      │
│  │  .signIn() │     │      │  │  .posts[]  │      │
│  └────────────┘     │      │  │  .logout() │      │
│         │           │      │  └────────────┘      │
└─────────┼───────────┘      └────────┬──────────────┘
          │                           │
          ▼                           ▼
┌─────────────────────┐      ┌──────────────────────┐
│   AuthService       │      │   CreatePostView     │
│                     │      │   (Sheet)            │
│  • signUp()         │      │                      │
│  • signIn()         │      │  • PhotosPicker      │
│  • signOut()        │      │  • Caption field     │
│  • getSession()     │      │  • Location field    │
│                     │      │  • Tags input        │
│  ┌───────────┐     │      │                      │
│  │ Supabase  │     │      │  ┌────────────┐     │
│  │   Auth    │     │      │  │ AppState   │     │
│  └───────────┘     │      │  │.createPost()│     │
└─────────────────────┘      │  └────────────┘     │
                             └────────┬─────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    ▼                                   ▼
        ┌──────────────────────┐          ┌──────────────────────┐
        │   StorageService     │          │    PostService       │
        │                      │          │                      │
        │  • uploadPhoto()     │          │  • createPost()      │
        │  • deletePhoto()     │          │  • fetchAllPosts()   │
        │  • AWS Sig V4        │          │  • deletePost()      │
        │                      │          │                      │
        │  ┌──────────────┐   │          │  ┌──────────────┐   │
        │  │Digital Ocean │   │          │  │  Supabase    │   │
        │  │   Spaces     │   │          │  │  Database    │   │
        │  └──────────────┘   │          │  └──────────────┘   │
        └──────────────────────┘          └──────────────────────┘
```

---

## User Journey Map

### First Time User
```
1. App Launch
   └─→ ContentView sees no user
       └─→ Shows OnboardingView

2. User Signs Up
   ├─→ Enter email
   ├─→ Enter password
   └─→ Choose username
       └─→ AppState.signUp()
           └─→ AuthService creates account
               └─→ Profile created in Supabase
                   └─→ currentUser updated
                       └─→ Navigate to FeedView

3. View Empty Feed
   └─→ See "No Posts Yet" message
       └─→ Tap "Create Post"

4. Create First Post
   ├─→ Select photo from library
   ├─→ Add caption
   ├─→ Add location
   ├─→ Add tags
   └─→ Tap "Post"
       └─→ ImageHelper compresses image
           └─→ StorageService uploads to S3
               └─→ PostService creates DB record
                   └─→ Post appears in feed

5. View Feed
   └─→ See own post
       └─→ Can delete via menu
```

### Returning User
```
1. App Launch
   └─→ ContentView checks session
       └─→ AuthService.getCurrentSession()
           └─→ Session exists
               └─→ Load UserProfile
                   └─→ Navigate to FeedView

2. View Feed
   └─→ AppState.fetchPosts()
       └─→ PostService.fetchAllPosts()
           └─→ Display posts
               └─→ Load images asynchronously

3. Pull to Refresh
   └─→ AppState.refreshPosts()
       └─→ Re-fetch from database
           └─→ Update UI
```

---

## Component Hierarchy

```
App
├── ContentView
│   ├── AppState (environment)
│   ├── OnboardingView (if not authenticated)
│   │   ├── Email TextField
│   │   ├── Password SecureField
│   │   ├── Username TextField (sign up only)
│   │   └── Sign Up/In Button
│   │
│   └── FeedView (if authenticated)
│       ├── NavigationStack
│       │   ├── Toolbar
│       │   │   ├── User Menu
│       │   │   └── Create Post Button
│       │   │
│       │   ├── Posts List (ScrollView)
│       │   │   └── PostCard (for each post)
│       │   │       ├── User Header
│       │   │       ├── Photo (AsyncImage)
│       │   │       ├── Caption
│       │   │       ├── Location
│       │   │       └── Tags (FlowLayout)
│       │   │
│       │   └── Empty State (if no posts)
│       │
│       └── CreatePostView (sheet)
│           ├── PhotosPicker
│           ├── Caption TextField
│           ├── Location TextField
│           ├── Tag Input
│           │   └── FlowLayout
│           │       └── TagView (for each tag)
│           └── Post Button
```

---

## State Flow

```
┌──────────────────────────────────────────────────────────────┐
│                         AppState                              │
│                      (@Observable)                            │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Properties:                                                  │
│  • currentUser: UserProfile?                                  │
│  • posts: [Post]                                              │
│  • isLoading: Bool                                            │
│  • error: Error?                                              │
│  • imageCache: [String: UIImage]                              │
│                                                               │
│  Methods:                                                     │
│  • signUp(email, password, username)                          │
│  • signIn(email, password)                                    │
│  • logout()                                                   │
│  • createPost(caption, location, tags, imageData)             │
│  • fetchPosts()                                               │
│  • deletePost(post)                                           │
│  • refreshPosts()                                             │
│                                                               │
└───────┬──────────────────────────────────────────────────────┘
        │
        │ Calls
        ▼
┌─────────────────────────────────────────────────────────────┐
│                    Service Layer (Actors)                    │
├──────────────────┬──────────────────┬───────────────────────┤
│  AuthService     │  PostService     │  StorageService       │
│  ──────────────  │  ──────────────  │  ─────────────────    │
│  • signUp()      │  • createPost()  │  • uploadPhoto()      │
│  • signIn()      │  • fetchPosts()  │  • deletePhoto()      │
│  • signOut()     │  • deletePost()  │  • signRequest()      │
└────────┬─────────┴────────┬─────────┴─────────┬─────────────┘
         │                  │                   │
         │ API Calls        │ API Calls         │ HTTP Requests
         ▼                  ▼                   ▼
┌────────────────┐  ┌────────────────┐  ┌──────────────────┐
│    Supabase    │  │    Supabase    │  │ Digital Ocean    │
│      Auth      │  │    Database    │  │     Spaces       │
│                │  │                │  │    (S3 API)      │
│  • Users       │  │  • profiles    │  │                  │
│  • Sessions    │  │  • posts       │  │  • Photos        │
└────────────────┘  └────────────────┘  └──────────────────┘
```

---

## Data Models Relationships

```
┌─────────────────────────────────────┐
│          Supabase Auth              │
│                                     │
│  auth.users                         │
│  ├─ id (UUID)                       │
│  ├─ email                           │
│  └─ encrypted_password              │
└──────────────┬──────────────────────┘
               │
               │ 1:1 relationship
               ▼
┌─────────────────────────────────────┐
│            UserProfile               │
│                                     │
│  profiles table                     │
│  ├─ id (references auth.users)      │
│  ├─ username (unique)               │
│  ├─ created_at                      │
│  └─ updated_at                      │
└──────────────┬──────────────────────┘
               │
               │ 1:many relationship
               ▼
┌─────────────────────────────────────┐
│              Post                    │
│                                     │
│  posts table                        │
│  ├─ id (UUID)                       │
│  ├─ user_id (references profiles)   │
│  ├─ username (cached)               │
│  ├─ caption                         │
│  ├─ location                        │
│  ├─ tags (array)                    │
│  ├─ photo_url (S3 key)             │
│  ├─ created_at                      │
│  └─ updated_at                      │
└──────────────┬──────────────────────┘
               │
               │ References S3 object
               ▼
┌─────────────────────────────────────┐
│       Digital Ocean Spaces          │
│                                     │
│  Stored as:                         │
│  {user_id}/{uuid}_{timestamp}.jpg   │
│                                     │
│  Accessible at:                     │
│  https://nyc3.digitaloceanspaces    │
│  .com/grassy-photos/{photo_url}     │
└─────────────────────────────────────┘
```

---

## Authentication Flow

```
Sign Up:
  User Input
    ↓
  AppState.signUp()
    ↓
  AuthService.signUp()
    ↓
  Supabase Auth API
    │
    ├─→ Create auth.users record
    │     ↓
    │   Return User object
    │     ↓
    └─→ Insert profiles record
          ↓
        Return UserProfile
          ↓
        Update AppState.currentUser
          ↓
        Navigate to FeedView

Sign In:
  User Input
    ↓
  AppState.signIn()
    ↓
  AuthService.signIn()
    ↓
  Supabase Auth API
    ↓
  Verify credentials
    ↓
  Create session
    ↓
  Fetch profile from database
    ↓
  Return UserProfile
    ↓
  Update AppState.currentUser
    ↓
  Navigate to FeedView

Session Restore:
  App Launch
    ↓
  ContentView init
    ↓
  AppState.loadCurrentUser()
    ↓
  AuthService.getCurrentSession()
    ↓
  Supabase checks stored session
    │
    ├─→ Valid session?
    │   ├─→ Yes: Fetch profile
    │   │         ↓
    │   │       Return UserProfile
    │   │         ↓
    │   │       Show FeedView
    │   │
    │   └─→ No: Show OnboardingView
    │
    └─→ Session exists?
        └─→ Auto-refresh if expired
```

---

## Post Creation Flow

```
User Action
  ↓
PhotosPicker
  ↓
Select photo
  ↓
Image data loaded
  ↓
ImageHelper.prepareForUpload()
  ├─→ Resize to max 2048px
  └─→ Compress to 80% JPEG
      ↓
    Compressed Data
      ↓
User fills metadata
  ├─ Caption
  ├─ Location
  └─ Tags
      ↓
Tap "Post"
  ↓
AppState.createPost()
  │
  ├─→ StorageService.uploadPhoto()
  │     ├─ Generate S3 key
  │     ├─ Sign request (AWS Sig V4)
  │     ├─ PUT request to Spaces
  │     └─ Return photo key
  │
  └─→ PostService.createPost()
        ├─ Create Post object
        ├─ INSERT into Supabase
        └─ Return saved Post
            ↓
          Add to AppState.posts
            ↓
          Cache image
            ↓
          Dismiss sheet
            ↓
          Show in feed
```

---

This visual guide shows how all the pieces fit together!
