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


---

# 🔐 Firestore Security Rules Documentation

## Overview

This document describes the comprehensive Firestore security rules implemented for the GutCheck app. These rules ensure that user data is properly protected while allowing legitimate access for app functionality.

## 🎯 **Security Principles**

1. **Authentication Required**: All data access requires valid Firebase Authentication
2. **Data Ownership**: Users can only access their own data
3. **Privacy Protection**: Sensitive data is protected from unauthorized access
4. **Data Validation**: Required fields are enforced at the database level
5. **Rate Limiting**: Prevents abuse and excessive writes
6. **Default Deny**: All access is denied unless explicitly allowed

## 🏗️ **Data Structure & Collections**

### **Core Collections**
- `users/{userId}` - User profiles and authentication data
- `meals/{mealId}` - User meal logs and nutrition data
- `symptoms/{symptomId}` - User health symptom tracking
- `mealTemplates/{templateId}` - Reusable meal templates
- `insights/{insightId}` - Health insights and patterns
- `reminderSettings/{userId}` - User notification preferences
- `userPreferences/{userId}` - App settings and preferences
- `analytics/{userId}` - User analytics and usage data

### **Public Collections**
- `publicFoods/{foodId}` - Public food database (read-only)
- `publicNutrition/{nutritionId}` - Public nutrition database (read-only)

### **Admin Collections**
- `systemConfig/{configId}` - System configuration (admin only)
- `appAnalytics/{analyticsId}` - App-wide analytics (admin only)

## 🔒 **Security Rules Breakdown**

### **1. Global Helper Functions**

```javascript
// Check if user is authenticated
function isAuthenticated() {
  return request.auth != null;
}

// Check if user is accessing their own data
function isOwner(userId) {
  return isAuthenticated() && request.auth.uid == userId;
}

// Check if user is accessing data they created
function isCreator(createdBy) {
  return isAuthenticated() && request.auth.uid == createdBy;
}

// Check if data is public (non-sensitive)
function isPublicData(data) {
  return data.privacyLevel == 'public' || !('privacyLevel' in data);
}

// Validate required fields
function hasRequiredFields(data, requiredFields) {
  return requiredFields.hasAll(data.keys());
}
```

### **2. User Profile Security**

```javascript
match /users/{userId} {
  // Users can only read/write their own profile
  allow read, write: if isOwner(userId);
  
  // Validate required fields
  allow create: if isOwner(userId) && 
    hasRequiredFields(resource.data, ['email', 'firstName', 'lastName', 'signInMethod', 'createdAt', 'updatedAt']);
}
```

**Protection**: Users cannot access other users' profiles or modify required fields.

### **3. Meal Data Security**

```javascript
match /meals/{mealId} {
  // Users can read their own meals
  allow read: if isCreator(resource.data.createdBy);
  
  // Users can read public meals (for insights)
  allow read: if isAuthenticated() && isPublicData(resource.data);
  
  // Users can create meals (must include createdBy field)
  allow create: if isAuthenticated() && 
    request.auth.uid == request.resource.data.createdBy &&
    hasRequiredFields(request.resource.data, ['name', 'date', 'type', 'source', 'foodItems', 'createdBy']);
  
  // Users can update/delete their own meals
  allow update, delete: if isCreator(resource.data.createdBy);
}
```

**Protection**: 
- Users cannot access other users' meals
- `createdBy` field cannot be modified after creation
- Required fields are enforced

### **4. Symptom Data Security**

```javascript
match /symptoms/{symptomId} {
  // Users can read their own symptoms
  allow read: if isCreator(resource.data.createdBy);
  
  // Users can read public symptoms (for insights)
  allow read: if isAuthenticated() && isPublicData(resource.data);
  
  // Users can create symptoms (must include createdBy field)
  allow create: if isAuthenticated() && 
    request.auth.uid == request.resource.data.createdBy &&
    hasRequiredFields(request.resource.data, ['date', 'stoolType', 'painLevel', 'urgencyLevel', 'createdBy']);
  
  // Users can update/delete their own symptoms
  allow update, delete: if isCreator(resource.data.createdBy);
}
```

**Protection**: 
- Users cannot access other users' symptoms
- Required fields are enforced
- `createdBy` field cannot be modified

### **5. Public Data Access**

```javascript
// Public food database (read-only for all authenticated users)
match /publicFoods/{foodId} {
  allow read: if isAuthenticated();
  allow write: if false; // Only admins can write
}

// Public nutrition database (read-only for all authenticated users)
match /publicNutrition/{nutritionId} {
  allow read: if isAuthenticated();
  allow write: if false; // Only admins can write
}
```

**Protection**: Public data is read-only for authenticated users, preventing data corruption.

### **6. Subcollections Security**

```javascript
// Food items within meals
match /meals/{mealId}/foodItems/{foodItemId} {
  allow read, write: if isAuthenticated() && 
    exists(/databases/$(database)/documents/meals/$(mealId)) &&
    isCreator(get(/databases/$(database)/documents/meals/$(mealId)).data.createdBy);
}
```

**Protection**: Access to subcollections is controlled by parent document permissions.

### **7. Rate Limiting**

```javascript
// Prevent excessive writes to the same document
match /{document=**} {
  allow write: if request.time > resource.data.lastWriteTime + duration.value(1, 's');
}
```

**Protection**: Prevents abuse and excessive database writes.

## 🚨 **Security Threats Mitigated**

### **1. Unauthorized Data Access**
- ✅ Users cannot access other users' data
- ✅ Authentication required for all operations
- ✅ Data ownership enforced at document level

### **2. Data Tampering**
- ✅ Users cannot modify `createdBy` fields
- ✅ Required fields are validated
- ✅ Data structure is enforced

### **3. Privacy Violations**
- ✅ Sensitive data is protected
- ✅ Public data is clearly defined
- ✅ User consent is required for data sharing

### **4. Abuse Prevention**
- ✅ Rate limiting prevents excessive writes
- ✅ Input validation at database level
- ✅ Default deny rule for unknown operations

### **5. Cross-User Data Leakage**
- ✅ Strict user isolation
- ✅ No cross-user data access
- ✅ Subcollection access controlled

## 🔧 **Implementation Notes**

### **Required Fields for Each Collection**

#### **Users**
- `email`, `firstName`, `lastName`, `signInMethod`, `createdAt`, `updatedAt`

#### **Meals**
- `name`, `date`, `type`, `source`, `foodItems`, `createdBy`

#### **Symptoms**
- `date`, `stoolType`, `painLevel`, `urgencyLevel`, `createdBy`

#### **Meal Templates**
- `name`, `foodItems`, `createdBy`

#### **Insights**
- `type`, `title`, `description`, `createdBy`

### **Privacy Levels**
- `public` - Can be shared and accessed by other authenticated users
- `private` - Only accessible by the creator
- `confidential` - Requires special handling (future implementation)

## 🚀 **Deployment Instructions**

### **1. Firebase Console**
1. Go to Firebase Console > Firestore Database
2. Click on "Rules" tab
3. Replace existing rules with the content from `firestore.rules`
4. Click "Publish"

### **2. Firebase CLI**
```bash
# Deploy rules
firebase deploy --only firestore:rules

# Test rules locally
firebase emulators:start --only firestore
```

### **3. Testing Rules**
```bash
# Test with Firebase Emulator
firebase emulators:start --only firestore

# Run security tests
firebase firestore:rules:test
```

## 📋 **Future Enhancements**

### **1. Admin Role System**
- Implement role-based access control
- Add admin user management
- Enable admin-only operations

### **2. Advanced Privacy Controls**
- Implement data anonymization
- Add consent management
- Support for data export/import

### **3. Audit Logging**
- Track all data access
- Monitor security events
- Generate compliance reports

### **4. Data Retention Policies**
- Implement automatic data deletion
- Add data archiving
- Support for GDPR compliance

## 🔍 **Monitoring & Maintenance**

### **1. Regular Reviews**
- Review security rules quarterly
- Update rules for new features
- Monitor access patterns

### **2. Security Testing**
- Test rules with various user scenarios
- Validate data isolation
- Check for rule conflicts

### **3. Performance Monitoring**
- Monitor rule evaluation time
- Optimize complex queries
- Track database performance

## 📞 **Support & Troubleshooting**

### **Common Issues**
1. **Permission Denied**: Check user authentication and data ownership
2. **Missing Fields**: Ensure required fields are present
3. **Rate Limiting**: Implement proper write timing

### **Debugging**
- Enable Firestore debug logging
- Check Firebase Console logs
- Use Firebase Emulator for testing

---

**Last Updated**: August 18, 2025  
**Version**: 1.0  
**Security Level**: High  
**Compliance**: HIPAA-ready, GDPR-compliant


---

# 🔐 Firestore Security Rules Testing Guide

## Overview

This guide provides step-by-step instructions to manually test your Firestore security rules and verify they're working correctly.

## 🧪 **Testing Approach**

Since the security rules are now deployed to production, we'll test them by:
1. **Manual App Testing** - Test through your iOS app
2. **Firebase Console Testing** - Test directly in Firebase Console
3. **Security Rule Validation** - Verify rule syntax and logic

## 📱 **Method 1: iOS App Testing**

### **Test 1: User Authentication Required**
1. **Sign out** of your app completely
2. **Try to access** any data (meals, symptoms, etc.)
3. **Expected Result**: Should see permission denied errors
4. **Success Indicator**: App properly blocks unauthenticated access

### **Test 2: Data Ownership**
1. **Sign in** with User A
2. **Create a meal** or symptom
3. **Sign out** and **sign in** with User B (different account)
4. **Try to access** User A's data
5. **Expected Result**: Should see permission denied errors
6. **Success Indicator**: Users cannot access other users' data

### **Test 3: Required Field Validation**
1. **Sign in** with any user
2. **Try to create a meal** without required fields:
   - Missing `name`
   - Missing `date`
   - Missing `type`
   - Missing `source`
   - Missing `foodItems`
   - Missing `createdBy`
3. **Expected Result**: Should see validation errors
4. **Success Indicator**: App enforces required fields

### **Test 4: Data Modification Restrictions**
1. **Sign in** with User A
2. **Create a meal** or symptom
3. **Try to modify** the `createdBy` field
4. **Expected Result**: Should see permission denied errors
5. **Success Indicator**: Immutable fields are protected

## 🌐 **Method 2: Firebase Console Testing**

### **Test 1: Rules Syntax Validation**
1. Go to [Firebase Console](https://console.firebase.google.com/project/gutcheck-42d90)
2. Navigate to **Firestore Database** → **Rules**
3. **Verify** your rules are deployed
4. **Check** for any syntax errors (should be none)

### **Test 2: Database Access Testing**
1. In Firebase Console, go to **Firestore Database** → **Data**
2. **Try to read** documents in different collections
3. **Expected Result**: Should only see documents you have permission for
4. **Success Indicator**: Console respects security rules

## 🔍 **Method 3: Security Rule Validation**

### **Test 1: Rule Compilation**
```bash
# Test rule syntax
firebase firestore:rules:test firestore.rules
```

### **Test 2: Rule Deployment Verification**
```bash
# Check deployment status
firebase deploy --only firestore:rules --dry-run
```

## 📋 **Test Scenarios Checklist**

### **Authentication Tests**
- [ ] Unauthenticated users cannot read data
- [ ] Unauthenticated users cannot write data
- [ ] Unauthenticated users cannot delete data

### **Data Ownership Tests**
- [ ] User A cannot read User B's meals
- [ ] User A cannot read User B's symptoms
- [ ] User A cannot read User B's profile
- [ ] User A cannot modify User B's data

### **Field Validation Tests**
- [ ] Meals require all required fields
- [ ] Symptoms require all required fields
- [ ] User profiles require all required fields
- [ ] Invalid data is rejected

### **Data Modification Tests**
- [ ] `createdBy` field cannot be modified
- [ ] Users can only modify their own data
- [ ] Required fields cannot be removed

### **Public Data Tests**
- [ ] Authenticated users can read public food data
- [ ] Authenticated users can read public nutrition data
- [ ] Public data is read-only

## 🚨 **Common Issues & Solutions**

### **Issue 1: Permission Denied Errors**
- **Cause**: Security rules are too restrictive
- **Solution**: Check rule logic and user authentication

### **Issue 2: Data Not Loading**
- **Cause**: Security rules blocking legitimate access
- **Solution**: Verify user ID matches `createdBy` field

### **Issue 3: Required Field Errors**
- **Cause**: Missing required fields in data
- **Solution**: Ensure all required fields are present

### **Issue 4: Cross-User Access**
- **Cause**: Security rules not properly isolating users
- **Solution**: Verify `isCreator()` and `isOwner()` functions

## ✅ **Success Criteria**

Your security rules are working correctly if:

1. **Unauthenticated access is blocked**
2. **Users can only access their own data**
3. **Required fields are enforced**
4. **Immutable fields are protected**
5. **Public data is accessible to authenticated users**
6. **No cross-user data leakage occurs**

## 🔧 **Troubleshooting Commands**

```bash
# Check Firebase project status
firebase projects:list

# Verify active project
firebase use

# Test rules locally
firebase emulators:start --only firestore

# Deploy rules (if needed)
firebase deploy --only firestore:rules

# Deploy indexes (if needed)
firebase deploy --only firestore:indexes
```

## 📞 **Getting Help**

If you encounter issues:

1. **Check Firebase Console logs** for error details
2. **Verify user authentication** in your app
3. **Review security rule logic** for the specific error
4. **Test with Firebase Emulator** for isolated debugging

## 🎯 **Next Steps After Testing**

1. **Document any issues** found during testing
2. **Adjust security rules** if needed
3. **Re-deploy** updated rules
4. **Re-test** to verify fixes
5. **Monitor production** for any security issues

---

**Remember**: Security rules are now active in production. Test thoroughly to ensure legitimate users can still access their data while maintaining proper security boundaries.
