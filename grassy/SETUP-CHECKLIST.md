# Grassy App - Complete Setup Checklist

## 📋 Prerequisites
- [ ] Xcode 15.0 or later
- [ ] iOS 17.0+ target
- [ ] Supabase account (free tier works)
- [ ] Digital Ocean account (for Spaces)

---

## 🗄️ Backend Setup

### Step 1: Supabase Database
1. **Create Project**
   - [ ] Go to https://supabase.com
   - [ ] Create a new project
   - [ ] Wait for project to be ready (~2 minutes)
   - [ ] Note your Project URL and anon key

2. **Run Database Migration**
   - [ ] Open Supabase Dashboard → SQL Editor
   - [ ] Copy SQL from `README.md`
   - [ ] Execute the migration
   - [ ] Verify tables created: `profiles` and `posts`

3. **Configure Authentication**
   - [ ] Go to Authentication → Settings
   - [ ] Enable Email provider
   - [ ] Disable email confirmation (for testing) OR configure SMTP
   - [ ] Set minimum password length (default: 6)

4. **Test Database Connection**
   - [ ] Go to Table Editor
   - [ ] Verify both tables exist
   - [ ] Check RLS policies are enabled

### Step 2: Digital Ocean Spaces
1. **Create Space**
   - [ ] Login to Digital Ocean
   - [ ] Go to Spaces → Create Space
   - [ ] Choose region (e.g., nyc3)
   - [ ] Name it: `grassy-photos`
   - [ ] Set to **Public** (important!)
   - [ ] Enable CDN (optional but recommended)

2. **Generate API Keys**
   - [ ] Go to API → Spaces Keys
   - [ ] Generate new Spaces access key
   - [ ] Save Access Key and Secret Key (shown only once!)

3. **Configure CORS (if needed)**
   - [ ] In Space settings → CORS Configurations
   - [ ] Add allowed origins (or use * for testing)

---

## 📱 iOS App Setup

### Step 3: Install Dependencies
1. **Add Supabase Swift Package**
   - [ ] Open Xcode project
   - [ ] File → Add Package Dependencies
   - [ ] Enter: `https://github.com/supabase/supabase-swift`
   - [ ] Select "Up to Next Major Version"
   - [ ] Add to target

2. **Configure Bridging Header (for CommonCrypto)**
   - [ ] Create bridging header if needed
   - [ ] Add: `#import <CommonCrypto/CommonCrypto.h>`

### Step 4: Configure App
1. **Setup Credentials**
   - [ ] Copy `SupabaseConfig-Template.swift` to `SupabaseConfig.swift`
   - [ ] Fill in Supabase URL
   - [ ] Fill in Supabase anon key
   - [ ] Fill in Digital Ocean endpoint
   - [ ] Fill in Digital Ocean region
   - [ ] Fill in Space name
   - [ ] Fill in Spaces access key
   - [ ] Fill in Spaces secret key

2. **Verify All Files Present**
   ```
   ✓ grassyApp.swift
   ✓ ContentView.swift
   ✓ Models.swift
   ✓ AppState.swift
   ✓ SupabaseConfig.swift (your custom file)
   ✓ AuthService.swift
   ✓ PostService.swift
   ✓ StorageService.swift
   ✓ ImageHelper.swift
   ✓ OnboardingView.swift
   ✓ FeedView.swift
   ✓ CreatePostView.swift
   ```

### Step 5: Build & Test
1. **First Build**
   - [ ] Clean build folder (Cmd+Shift+K)
   - [ ] Build project (Cmd+B)
   - [ ] Fix any compilation errors

2. **Run on Simulator/Device**
   - [ ] Select target device
   - [ ] Run app (Cmd+R)
   - [ ] App should open to onboarding screen

---

## ✅ Testing Checklist

### Test Authentication
- [ ] Sign up with new email/password/username
- [ ] Verify profile created in Supabase
- [ ] Close and reopen app (should stay logged in)
- [ ] Logout
- [ ] Sign in with same credentials

### Test Photo Upload
- [ ] Tap create post button
- [ ] Select photo from library
- [ ] Add caption
- [ ] Add location
- [ ] Add tags
- [ ] Post photo
- [ ] Verify image uploaded to Digital Ocean Spaces
- [ ] Verify post appears in feed

### Test Feed
- [ ] View posts in feed
- [ ] Pull to refresh
- [ ] Verify images load
- [ ] Tap on your post's menu
- [ ] Delete your own post
- [ ] Verify post removed from feed

### Test Persistence
- [ ] Create a post
- [ ] Force quit app
- [ ] Reopen app
- [ ] Verify still logged in
- [ ] Verify posts still visible

---

## 🐛 Troubleshooting

### "Failed to create account"
- Check Supabase project is running
- Verify email auth is enabled
- Check network connection
- Look at Xcode console for specific error

### "Failed to upload photo"
- Verify Digital Ocean Spaces is PUBLIC
- Check access key and secret key are correct
- Verify endpoint URL matches your region
- Check Space name is correct

### "No posts loading"
- Check Supabase tables have data
- Verify RLS policies allow SELECT
- Check network connection
- Look for errors in Xcode console

### Images not showing
- Verify Space is set to PUBLIC
- Check photo_url in database
- Try accessing image URL in browser
- Verify CDN is enabled if using custom domain

### Build errors
- Clean build folder
- Delete derived data
- Verify all Swift packages are resolved
- Check bridging header for CommonCrypto

---

## 🚀 Next Features to Build

Once basic functionality works:

- [ ] User profiles with avatars
- [ ] Follow/unfollow users
- [ ] Likes and comments
- [ ] Search functionality
- [ ] Tag filtering
- [ ] User feed (only posts from followed users)
- [ ] Push notifications
- [ ] Image filters
- [ ] Multiple photos per post
- [ ] Stories feature
- [ ] Direct messaging

---

## 📝 Important Notes

1. **Security**: Never commit `SupabaseConfig.swift` to git
2. **Costs**: Monitor Digital Ocean Spaces usage (bandwidth and storage)
3. **Rate Limits**: Supabase free tier has limits on API calls
4. **Image Size**: App compresses images to max 2048px and 80% quality
5. **RLS**: All database access is protected by Row Level Security

---

## 📚 Resources

- Supabase Docs: https://supabase.com/docs
- Digital Ocean Spaces: https://docs.digitalocean.com/products/spaces/
- Supabase Swift: https://github.com/supabase/supabase-swift
- AWS S3 Signature V4: https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html

---

**✨ Happy coding! You now have a fully functional photo-sharing social app!**
