# Firebase Setup Guide for GutCheck

## The Two Important Plist Files

### 1. Info.plist (iOS App Configuration)
- **Already in your project** ✅
- Tells iOS about your app
- Contains app name, permissions, bundle ID, etc.
- Edited through Xcode project settings

### 2. GoogleService-Info.plist (Firebase Configuration)
- **Must download from Firebase Console** 🔥
- Tells your app how to connect to Firebase
- Contains API keys, project IDs, database URLs
- Should rarely need editing

## Quick Setup Steps

### Step 1: Get Your Bundle Identifier
1. Open your project in Xcode
2. Select the **GutCheck** target
3. Go to **General** tab
4. Look at **Bundle Identifier** (e.g., `com.yourcompany.GutCheck`)
5. **Copy this** - you'll need it for Firebase

### Step 2: Firebase Console Setup
1. Go to https://console.firebase.google.com/
2. Create a new project or select existing **GutCheck** project
3. Click **Add app** → **iOS** (the Apple logo)
4. **Paste your Bundle Identifier** from Step 1
5. Enter app nickname: "GutCheck"
6. (Optional) Enter App Store ID if you have one
7. Click **Register app**
8. **Download GoogleService-Info.plist**

### Step 3: Add File to Xcode
1. In Xcode, **right-click** on your GutCheck folder (where other files are)
2. Select **Add Files to "GutCheck"...**
3. Find the downloaded `GoogleService-Info.plist`
4. **IMPORTANT**: Check these boxes:
   - ✅ **"Copy items if needed"**
   - ✅ **"Add to targets: GutCheck"**
5. Click **Add**

### Step 4: Verify Setup
1. In Xcode's file navigator, select `GoogleService-Info.plist`
2. Open **File Inspector** (right panel, first tab icon)
3. Verify:
   - ✅ **Target Membership** shows "GutCheck" checked
   - ✅ **Location** shows it's in your project folder

### Step 5: Verify in Build Phases
1. Select your project (top of navigator)
2. Select **GutCheck** target
3. Go to **Build Phases** tab
4. Expand **Copy Bundle Resources**
5. Verify `GoogleService-Info.plist` is listed
   - If NOT listed, click **+** and add it

### Step 6: Run Diagnostics
1. Clean build folder: `Shift+Cmd+K`
2. Build: `Cmd+B`
3. Run the app
4. Check the console for diagnostic output:

```
================================================================================
🔍 FIREBASE CONFIGURATION DIAGNOSTICS
================================================================================

📱 Checking Info.plist...
   ✅ Bundle Identifier: com.yourcompany.GutCheck
   ✅ App Name: GutCheck
   ✅ Version: 1.0

🔥 Checking GoogleService-Info.plist...
   ✅ File found at: /path/to/GoogleService-Info.plist
   ✅ File is readable
   ✅ API_KEY: AIzaSyD...
   ✅ GCM_SENDER_ID: 123456789
   ✅ PROJECT_ID: gutcheck-12345
   ✅ GOOGLE_APP_ID: 1:123:ios:abc
   ✅ BUNDLE_ID: com.yourcompany.GutCheck

🔗 Comparing Bundle IDs...
   ✅ Bundle IDs MATCH!
   📱 App: com.yourcompany.GutCheck
   🔥 Firebase: com.yourcompany.GutCheck

================================================================================
```

## Common Issues & Solutions

### ❌ "GoogleService-Info.plist not found"
**Solution:** Follow Steps 2-3 above to download and add the file

### ❌ "Bundle IDs do not match"
**Solution:** 
- **Option A (Recommended):** Download a new GoogleService-Info.plist with the correct Bundle ID
- **Option B:** Change your app's Bundle ID in Xcode to match Firebase

### ❌ File in project but still not found
**Solution:**
1. Remove the file from project (Delete → Remove Reference only)
2. Re-add it following Step 3, ensuring "Copy items" is checked
3. Verify it appears in Build Phases → Copy Bundle Resources

### ❌ Firebase authentication fails
**Solution:**
1. Check that API_KEY in GoogleService-Info.plist is not empty
2. Verify your Firebase project has Authentication enabled
3. Check Firebase Console → Authentication → Sign-in methods

## File Comparison

### What Info.plist Contains:
```xml
<key>CFBundleIdentifier</key>
<string>com.yourcompany.GutCheck</string>

<key>CFBundleDisplayName</key>
<string>GutCheck</string>

<key>NSCameraUsageDescription</key>
<string>To scan food barcodes</string>

<key>NSHealthShareUsageDescription</key>
<string>To track your health data</string>
```

### What GoogleService-Info.plist Contains:
```xml
<key>API_KEY</key>
<string>AIzaSyD...</string>

<key>PROJECT_ID</key>
<string>gutcheck-12345</string>

<key>BUNDLE_ID</key>
<string>com.yourcompany.GutCheck</string>

<key>GOOGLE_APP_ID</key>
<string>1:123:ios:abc</string>

<key>DATABASE_URL</key>
<string>https://gutcheck-12345.firebaseio.com</string>
```

## Security Notes

### Info.plist
- ✅ Safe to commit to version control
- Contains public app information

### GoogleService-Info.plist
- ⚠️ Contains API keys (but they're client-side keys)
- ✅ Generally safe to commit (Firebase uses security rules to protect data)
- ❓ Some teams add to `.gitignore` for extra security
- 🔒 Real security comes from Firebase Security Rules, not hiding this file

## Need Help?

If you see errors after following these steps:
1. Check the diagnostic output in the console
2. Verify Bundle IDs match exactly
3. Try cleaning build folder and rebuilding
4. Make sure GoogleService-Info.plist is in Copy Bundle Resources

## Additional Firebase Services

Once GoogleService-Info.plist is configured, you can use:
- ✅ Firebase Authentication (already integrated)
- ✅ Cloud Firestore (already integrated)
- ✅ Firebase Analytics (automatic)
- ⬜ Cloud Storage (add if needed)
- ⬜ Cloud Functions (add if needed)
- ⬜ Crashlytics (add if needed)

All Firebase services use the same GoogleService-Info.plist file!
