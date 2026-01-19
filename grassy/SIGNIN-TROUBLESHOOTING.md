# 🔧 Sign-In Troubleshooting Guide

## Problem: Account Confirmed But Can't Sign In

If you can sign up but not sign in, even with email confirmed, here are the steps to diagnose and fix:

---

## 🧪 Step 1: Use Auth Debug View

1. **Open AuthDebugView** in your app
2. **Fill in your credentials**:
   - Email: (the one you signed up with)
   - Password: (the one you used)
   - Username: (doesn't matter for sign-in test)
3. **Tap "Test Sign In"**
4. **Read the error message carefully**

---

## 🔍 Step 2: Check Supabase Dashboard

### A. Check Auth User Exists
1. Go to **Authentication → Users**
2. Find your email
3. Verify:
   - ✅ Email is confirmed (should say "Confirmed")
   - ✅ User status is active (not deleted)

### B. Check Profile Exists
1. Go to **Table Editor → profiles**
2. Look for a row with your user's ID
3. **If missing**: This is your problem! (Orphaned auth account)

---

## 🛠️ Common Scenarios & Fixes

### Scenario 1: Profile Missing (Orphaned Account)

**Symptom:** Auth user exists but no profile in `profiles` table

**Why it happens:**
- Sign-up succeeded in creating auth user
- But profile creation failed silently
- Sign-in tries to fetch profile and fails

**Fix Option A: Use Debug View**
1. Open AuthDebugView
2. Fill in email, password, AND username
3. Tap **"Fix Orphaned Account"**
4. This will create the missing profile

**Fix Option B: Manual SQL**
```sql
-- In Supabase SQL Editor
INSERT INTO profiles (id, username, created_at)
VALUES (
  'YOUR_USER_ID_HERE',  -- Get from auth.users table
  'your_username',
  NOW()
);
```

---

### Scenario 2: RLS Policy Blocking

**Symptom:** Sign-in fails with "Row Level Security" error

**Why it happens:**
- RLS policies are too restrictive
- Profile can't be fetched during sign-in

**Fix:**
```sql
-- In Supabase SQL Editor
-- Check existing policies
SELECT * FROM pg_policies WHERE tablename = 'profiles';

-- Make sure you have this policy:
CREATE POLICY "Public profiles are viewable by everyone"
    ON profiles FOR SELECT
    USING (true);
```

---

### Scenario 3: Wrong Password

**Symptom:** "Invalid credentials" or "Authentication failed"

**Simple fix:** Make sure you're typing the password correctly!

**Reset password:**
1. Supabase Dashboard → Authentication → Users
2. Click user → "Send password recovery email"
3. Or manually set new password in dashboard

---

### Scenario 4: Multiple Accounts

**Symptom:** Signed up multiple times with same email

**Check:**
```sql
-- In Supabase SQL Editor
SELECT * FROM auth.users WHERE email = 'your@email.com';
```

**Fix:**
- Delete duplicate accounts in Supabase Dashboard
- Use only one account

---

## 📊 Debug Checklist

Run through these in **AuthDebugView**:

- [ ] "Check Current Session" → Should show no session initially
- [ ] "Test Sign In" → Read error message
- [ ] Check console in Xcode for detailed logs
- [ ] If profile missing → "Fix Orphaned Account"
- [ ] "Test Sign In" again → Should work now!

---

## 🔬 Console Log Analysis

After trying to sign in, check Xcode console for:

### ✅ Success Logs
```
✅ Sign in successful. User ID: abc-123
📧 Email confirmed: true
✅ Profile fetched: @username
```

### ❌ Error Patterns

**Pattern 1: Profile Not Found**
```
❌ Sign in error: JSON object couldn't be parsed
```
→ **Fix:** Use "Fix Orphaned Account" button

**Pattern 2: Wrong Password**
```
❌ Sign in error: Invalid login credentials
```
→ **Fix:** Check password or reset it

**Pattern 3: Email Not Confirmed**
```
❌ Sign in error: Email not confirmed
```
→ **Fix:** Go to Supabase → Users → Confirm email

**Pattern 4: Network Error**
```
❌ Sign in error: The Internet connection appears to be offline
```
→ **Fix:** Check network connection

---

## 🎯 Quick Fix Summary

| Problem | Solution |
|---------|----------|
| Profile missing | AuthDebugView → "Fix Orphaned Account" |
| Email not confirmed | Supabase Dashboard → Confirm email |
| Wrong password | Type carefully or reset password |
| RLS blocking | Check/fix RLS policies in SQL |
| Network error | Check internet connection |

---

## 🚀 Prevent Future Issues

### Update Sign-Up Flow

The enhanced `AuthService.signUp()` now has better error handling:
- ✅ Logs when auth user is created
- ✅ Logs when profile is created
- ✅ Shows specific error if profile creation fails

### Monitor Console Logs

During sign-up, watch for:
```
✅ Auth user created: abc-123
✅ Profile created: @username
```

If you see the first but not the second, profile creation failed!

---

## 📞 Still Having Issues?

1. **Run all tests in AuthDebugView** and note the results
2. **Check Xcode console** for detailed error logs
3. **Verify in Supabase Dashboard**:
   - Authentication → Users (user exists and confirmed?)
   - Table Editor → profiles (profile exists?)
4. **Check RLS policies** in SQL Editor

---

**Most Common Fix:** Use the "Fix Orphaned Account" button in AuthDebugView! 🎯
