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
