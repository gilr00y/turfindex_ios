# Grassy - Photo Sharing App Setup

## Overview
Grassy is a photo-sharing social app with Supabase backend and Digital Ocean Spaces for image storage.

## Backend Setup

### 1. Supabase Setup

#### Create a Supabase Project
1. Go to [supabase.com](https://supabase.com) and create a new project
2. Note your project URL and anon key

#### Run SQL Migration
Execute this SQL in your Supabase SQL Editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create profiles table
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Create posts table
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    username TEXT NOT NULL,
    caption TEXT DEFAULT '',
    location TEXT DEFAULT '',
    tags TEXT[] DEFAULT '{}',
    photo_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    
    CONSTRAINT posts_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id)
);

-- Create indexes for better performance
CREATE INDEX posts_user_id_idx ON posts(user_id);
CREATE INDEX posts_created_at_idx ON posts(created_at DESC);
CREATE INDEX posts_tags_idx ON posts USING GIN(tags);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Public profiles are viewable by everyone"
    ON profiles FOR SELECT
    USING (true);

CREATE POLICY "Users can insert their own profile"
    ON profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- Posts policies
CREATE POLICY "Posts are viewable by everyone"
    ON posts FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can create posts"
    ON posts FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own posts"
    ON posts FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own posts"
    ON posts FOR DELETE
    USING (auth.uid() = user_id);

-- Function to handle updated_at timestamp
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON posts
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

-- Enable Realtime for posts (optional, for live feed updates)
ALTER PUBLICATION supabase_realtime ADD TABLE posts;
```

### 2. Digital Ocean Spaces Setup

#### Create a Space
1. Go to [DigitalOcean](https://cloud.digitalocean.com/spaces)
2. Create a new Space (e.g., `grassy-photos`)
3. Choose a region (e.g., `nyc3`)
4. Set permissions to **Public** (for photo URLs to work)

#### Generate API Keys
1. Go to API → Spaces Keys
2. Generate a new key pair
3. Save the Access Key and Secret Key

### 3. Configure the iOS App

Update `SupabaseConfig.swift` with your credentials:

```swift
enum SupabaseConfig {
    static let url = URL(string: "https://YOUR_PROJECT.supabase.co")!
    static let anonKey = "YOUR_ANON_KEY"
    
    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey
    )
}

enum SpacesConfig {
    static let endpoint = "https://nyc3.digitaloceanspaces.com"
    static let region = "nyc3"
    static let bucket = "grassy-photos"
    static let accessKey = "YOUR_ACCESS_KEY"
    static let secretKey = "YOUR_SECRET_KEY"
    
    static func photoURL(for key: String) -> URL? {
        URL(string: "\(endpoint)/\(bucket)/\(key)")
    }
}
```

## Swift Package Dependencies

Add these packages to your Xcode project:

1. **Supabase Swift**
   - URL: `https://github.com/supabase/supabase-swift`
   - Version: Latest

## Project Structure

```
grassy/
├── grassyApp.swift          # App entry point
├── ContentView.swift        # Main coordinator view
├── Models.swift             # Data models (UserProfile, Post)
├── AppState.swift           # Observable app state
├── SupabaseConfig.swift     # Configuration
├── Services/
│   ├── AuthService.swift    # Authentication logic
│   ├── PostService.swift    # Post CRUD operations
│   └── StorageService.swift # Photo upload/delete
└── Views/
    ├── OnboardingView.swift # Sign up/in screen
    ├── FeedView.swift       # Public feed
    └── CreatePostView.swift # Create new post
```

## Features

✅ **User Authentication**
- Email/password sign up and sign in
- Username selection
- Secure session management

✅ **Photo Sharing**
- Pick photos from library
- Upload to Digital Ocean Spaces
- Add captions, locations, and tags
- View public feed

✅ **Post Management**
- Create posts with metadata
- Delete own posts
- Real-time feed updates
- Pull to refresh

✅ **Performance**
- Image caching
- Async/await throughout
- Lazy loading of images

## Security Notes

1. **Never commit credentials** - Add `SupabaseConfig.swift` to `.gitignore` or use environment variables
2. **Row Level Security** is enabled on all Supabase tables
3. Digital Ocean Spaces must be public for image URLs to work
4. Consider adding image optimization before upload

## Next Steps

- [ ] Add image optimization/compression
- [ ] Implement profile pages
- [ ] Add likes/comments
- [ ] Search and tag filtering
- [ ] Push notifications for new posts
- [ ] CDN integration for faster image delivery
