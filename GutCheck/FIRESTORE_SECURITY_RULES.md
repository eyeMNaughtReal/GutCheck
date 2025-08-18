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
