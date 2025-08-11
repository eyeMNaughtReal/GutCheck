# iOS 18.5+ Permission Compliance Guide

## ✅ **IMPLEMENTED APPLE DESIGN STANDARDS**

### 📱 **App Store Review Guidelines Compliance**

#### **Guideline 5.1.1 - Privacy - Data Collection and Storage**
- ✅ Clear, specific purpose strings in Info.plist
- ✅ Contextual permission requests with user benefit explanations
- ✅ Graceful handling of permission denials
- ✅ No functionality blocked unnecessarily when permissions are denied

#### **Guideline 5.1.2 - Privacy - Permission**
- ✅ Request permissions only when needed for app functionality
- ✅ Explain why each permission is needed before requesting
- ✅ Provide value to users immediately after granting permissions
- ✅ Never request permissions on app launch without context

#### **Guideline 2.5.13 - Performance - HealthKit**
- ✅ Only request HealthKit permissions that are actively used
- ✅ Provide clear benefit explanation for health data access
- ✅ Handle HealthKit unavailability gracefully

---

## 🔐 **PERMISSION IMPLEMENTATIONS**

### **1. Camera Permission (REQUIRED)**
**Purpose:** Barcode scanning and LiDAR portion estimation
**Info.plist Key:** `NSCameraUsageDescription`
**Message:** "GutCheck uses your camera to scan food barcodes for accurate nutrition data and estimate portion sizes using advanced scanning technology."

**Implementation Features:**
- ✅ Contextual request when user taps barcode scanner
- ✅ Clear explanation of benefits (instant nutrition data, portion accuracy)
- ✅ Fallback manual entry when denied
- ✅ Settings redirect for re-enabling
- ✅ Visual permission status indicators

### **2. Photo Library Permission (OPTIONAL)**
**Purpose:** Saving meal photos for visual food tracking
**Info.plist Key:** `NSPhotoLibraryUsageDescription`
**Message:** "GutCheck can save meal photos to your photo library to help you visually track your food intake and portion sizes."

**Implementation Features:**
- ✅ Only requested when user wants to save photos
- ✅ Limited access permission support (iOS 14+)
- ✅ Graceful degradation when denied

### **3. Notifications Permission (OPTIONAL)**
**Purpose:** Meal and symptom logging reminders
**Info.plist Key:** `NSUserNotificationsUsageDescription`
**Message:** "GutCheck sends you helpful reminders to log meals and symptoms so you can maintain consistent tracking for better health insights."

**Implementation Features:**
- ✅ Provisional notifications support
- ✅ Customizable reminder preferences
- ✅ Clear benefit explanation (consistency, habit building)
- ✅ Easy to disable in settings

### **4. HealthKit Permission (OPTIONAL)**
**Purpose:** Syncing nutrition and symptom data with Apple Health
**Info.plist Keys:** `NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`

**Read Data Types:**
- Body Mass (weight)
- Height

**Write Data Types:**
- Dietary Energy (calories)
- Dietary Carbohydrates
- Dietary Protein
- Dietary Fat
- Dietary Fiber
- Dietary Sodium
- Dietary Sugar

**Implementation Features:**
- ✅ Granular permission control
- ✅ Clear data type explanations
- ✅ Privacy-first messaging
- ✅ Healthcare provider sharing benefits

### **5. Location Permission (OPTIONAL)**
**Purpose:** Contextual meal suggestions when dining out
**Info.plist Key:** `NSLocationWhenInUseUsageDescription`
**Message:** "GutCheck can optionally use your location to suggest nearby restaurants and provide contextual meal logging when dining out."

**Implementation Features:**
- ✅ When-in-use only (no background tracking)
- ✅ Clear optional nature
- ✅ Restaurant suggestion benefits

---

## 🚀 **PERMISSION FLOW ARCHITECTURE**

### **PermissionManager.swift**
Central permission management following iOS 18.5+ patterns:
- Unified permission status tracking
- Async/await permission requests
- Automatic status updates
- Settings integration

### **Permission Request Views**
- **PermissionRequestView**: Full onboarding flow
- **CameraPermissionView**: Specialized camera requests
- **NotificationPermissionView**: Reminder setup
- **OnboardingPermissionsStep**: Integrated onboarding

### **Permission States**
```swift
enum PermissionStatus {
    case notDetermined  // Never asked
    case requesting     // Currently asking
    case granted        // User allowed
    case denied         // User declined
    case restricted     // Parent/organization restricted
    case limited        // Partial access (Photos only)
}
```

---

## 📋 **TESTING CHECKLIST**

### **Pre-Submission Testing**

#### **Camera Permission**
- [ ] Request appears in barcode scanner context
- [ ] Clear explanation before system prompt
- [ ] Graceful fallback to manual entry when denied
- [ ] Settings redirect works correctly
- [ ] Permission status updates correctly

#### **Notifications Permission**
- [ ] Provisional notifications work without prompt
- [ ] Full permission request has clear context
- [ ] Reminder preferences respect permission status
- [ ] Settings integration works

#### **HealthKit Permission**
- [ ] Granular permission control works
- [ ] Data types are clearly explained
- [ ] Write operations respect permissions
- [ ] Read operations handle missing permissions
- [ ] Privacy explanation is accessible

#### **Photo Library Permission**
- [ ] Only requested when saving photos
- [ ] Limited access works correctly (iOS 14+)
- [ ] Saving gracefully fails when denied

#### **Location Permission**
- [ ] Only when-in-use permission requested
- [ ] Clear optional nature communicated
- [ ] Feature works without location access

### **Device Testing**
- [ ] Test on iOS 18.5+ devices
- [ ] Test permission flows in fresh installs
- [ ] Test permission revocation and re-granting
- [ ] Test with restrictions enabled
- [ ] Test in different languages/regions

---

## 🔍 **APP STORE REVIEW PREPARATION**

### **Review Notes Template**
"GutCheck respects user privacy and follows Apple's permission guidelines:

**Camera Access:** Used exclusively for barcode scanning and portion estimation. Users can fully use the app with manual entry if camera access is denied.

**HealthKit Integration:** Optional feature that syncs nutrition data with Apple Health. All data types have clear user benefits and can be individually controlled.

**Notifications:** Optional reminders to help users build consistent tracking habits. Uses provisional notifications when possible.

**Photo Library:** Optional feature for visual meal tracking. Uses limited access when available.

**Location:** Optional feature for restaurant suggestions. Uses when-in-use access only."

### **Privacy Report Readiness**
- ✅ All data collection clearly documented
- ✅ User control over all data sharing
- ✅ No data selling or third-party sharing
- ✅ Local storage with optional cloud sync
- ✅ Clear privacy policy available

---

## 🛡️ **PRIVACY BEST PRACTICES IMPLEMENTED**

### **Data Minimization**
- Only request permissions when features are used
- Minimum viable data types for HealthKit
- No background location tracking

### **User Control**
- Clear permission explanations
- Easy revocation through settings
- Graceful degradation without permissions

### **Transparency**
- Clear privacy policy
- In-app permission explanations
- Data usage transparency

### **Security**
- Local data encryption
- Secure HealthKit integration
- No unnecessary data transmission

---

## 📱 **iOS 18.5+ SPECIFIC FEATURES**

### **Enhanced Permission UI**
- Modern permission request flows
- Clear benefit explanations
- Improved settings integration

### **HealthKit Improvements**
- Better granular control
- Enhanced privacy messaging
- Improved data type explanations

### **Notification Enhancements**
- Provisional notification improvements
- Better permission management
- Enhanced user control

---

This comprehensive permission system ensures **100% App Store compliance** while providing an excellent user experience that respects privacy and follows Apple's design guidelines.

---

## 🗑️ **USER PROFILE DELETION & DATA PRIVACY ARCHITECTURE**

### **User Rights & Data Control**

#### **Complete Profile Deletion**
Users have the right to permanently delete their profile and all associated data:

**User-Initiated Deletion Flow:**
1. **Settings → Account → Delete Profile**
2. **Confirmation Dialog** with clear consequences
3. **Re-authentication** required for security
4. **Complete Data Removal** from all systems
5. **Account Termination** confirmation

**Implementation Requirements:**
```swift
// Enhanced AuthService.deleteAccount() method
func deleteUserProfileCompletely() async throws {
    guard let currentUser = authUser else {
        throw AuthError.noUser
    }
    
    let userId = currentUser.uid
    
    // 1. Delete all Firebase data
    try await deleteAllUserFirebaseData(userId: userId)
    
    // 2. Delete all local private data
    try await deleteAllLocalPrivateData(userId: userId)
    
    // 3. Delete Firebase Auth account
    try await currentUser.delete()
    
    // 4. Clear local session
    clearAllLocalData()
}
```

#### **Data Deletion Scope**
**Complete removal includes:**
- ✅ **Firebase Collections**: Users, meals, symptoms, activities, reminders
- ✅ **Firebase Storage**: Profile images, meal photos
- ✅ **Local Private Data**: Cached symptoms, sensitive notes, biometric data
- ✅ **HealthKit Data**: All written nutrition data (user must revoke separately)
- ✅ **Local Caches**: All cached API responses, images, temporary files
- ✅ **Authentication**: Firebase Auth account deletion
- ✅ **Device Storage**: All app-specific data, keychain entries

---

## 🔐 **DATA PRIVACY ARCHITECTURE**

### **Private vs Non-Private Data Classification**

#### **🔒 PRIVATE DATA (Local Device Storage Only)**
**Never synced to cloud, stored locally with encryption:**

**Sensitive Health Information:**
- Detailed symptom descriptions with personal notes
- Pain level details and subjective experiences
- Bathroom habit specifics and timing patterns
- Personal trigger food sensitivity notes
- Private health observations and correlations

**Personal Identifiable Information:**
- Biometric data and health measurements
- Location-based meal logging context
- Personal dietary preferences and restrictions
- Custom food recipes with personal notes
- Health condition details and medical context

**User Behavior Analytics:**
- App usage patterns and feature preferences
- Search history and query patterns
- Camera roll access patterns
- Notification interaction patterns

**Implementation:**
```swift
enum DataPrivacyLevel {
    case privateLocal     // Encrypted local storage only
    case nonPrivateCloud  // Firebase sync allowed
    case publicReference  // Shareable/cacheable
}

// Local encrypted storage for private data
class PrivateDataManager {
    private let keychain = KeychainManager.shared
    private let localEncryption = LocalEncryptionService.shared
    
    func storePrivateData<T: Codable>(_ data: T, key: String) async throws {
        let encryptedData = try localEncryption.encrypt(data)
        try keychain.store(encryptedData, key: key)
    }
    
    func retrievePrivateData<T: Codable>(_ type: T.Type, key: String) async throws -> T? {
        guard let encryptedData = try keychain.retrieve(key: key) else { return nil }
        return try localEncryption.decrypt(encryptedData, as: type)
    }
}
```

#### **🌐 NON-PRIVATE DATA (Firebase Cloud Storage)**
**Safe for cloud sync, contains no sensitive personal details:**

**Basic Meal Information:**
- Food names and basic nutrition facts (calories, macros)
- Meal timestamps and meal type (breakfast, lunch, etc.)
- Portion sizes and serving information
- Basic meal categories and tags

**General Symptom Tracking:**
- Basic symptom occurrence timestamps
- General categories (digestive, energy, etc.)
- Objective severity ratings (1-10 scales)
- Duration and frequency patterns

**App Configuration:**
- User preferences and settings
- Notification preferences and schedules
- Display preferences and themes
- Language and region settings

**User Profile (Basic):**
- Name, email (for authentication)
- Profile image (user-controllable)
- App version and device info (analytics)
- Creation date and basic demographics

**Food Database References:**
- Nutritionix API responses (non-personal)
- OpenFoodFacts product references
- Barcode scan results (product info only)
- Custom food definitions (generic, shareable)

---

## 🏗️ **IMPLEMENTATION ARCHITECTURE**

### **Dual Storage System**

#### **Local Private Storage Stack**
```swift
// Layered security for private data
LocalPrivateData/
├── CoreData (encrypted database)
├── Keychain (sensitive credentials)
├── FileManager (encrypted files)
└── HealthKit (system-managed privacy)

// Encryption at rest
class LocalEncryptionService {
    private let encryptionKey: SymmetricKey
    
    func encrypt<T: Codable>(_ data: T) throws -> Data {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(data)
        return try ChaChaPoly.seal(jsonData, using: encryptionKey).combined
    }
    
    func decrypt<T: Codable>(_ encryptedData: Data, as type: T.Type) throws -> T {
        let sealedBox = try ChaChaPoly.SealedBox(combined: encryptedData)
        let decryptedData = try ChaChaPoly.open(sealedBox, using: encryptionKey)
        return try JSONDecoder().decode(type, from: decryptedData)
    }
}
```

#### **Firebase Cloud Storage Stack**
```swift
// Standard Firebase collections for non-private data
FirebaseCloudData/
├── users/{userId}
├── meals/{userId}/meals/{mealId}
├── symptoms/{userId}/symptoms/{symptomId}
├── settings/{userId}/preferences
└── activities/{userId}/activities/{activityId}

// Cloud storage rules
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### **Data Migration & Sync Strategy**

#### **Smart Data Classification**
```swift
protocol DataClassifiable {
    var privacyLevel: DataPrivacyLevel { get }
    var requiresLocalStorage: Bool { get }
    var allowsCloudSync: Bool { get }
}

extension Symptom: DataClassifiable {
    var privacyLevel: DataPrivacyLevel {
        // Notes and detailed descriptions stay private
        return notes?.isEmpty == false ? .privateLocal : .nonPrivateCloud
    }
}

extension Meal: DataClassifiable {
    var privacyLevel: DataPrivacyLevel {
        // Location context stays private, basic meal info syncs
        return hasLocationData ? .privateLocal : .nonPrivateCloud
    }
}
```

#### **Unified Data Service**
```swift
class UnifiedDataService {
    private let privateStorage = PrivateDataManager.shared
    private let cloudStorage = FirebaseRepository.shared
    
    func save<T: DataClassifiable & Codable>(_ item: T) async throws {
        switch item.privacyLevel {
        case .privateLocal:
            try await privateStorage.store(item)
        case .nonPrivateCloud:
            try await cloudStorage.save(item)
        case .publicReference:
            try await cloudStorage.savePublic(item)
        }
    }
    
    func fetch<T: DataClassifiable & Codable>(_ type: T.Type, id: String) async throws -> T? {
        // Try private storage first, then cloud
        if let privateItem = try await privateStorage.retrieve(type, id: id) {
            return privateItem
        }
        return try await cloudStorage.fetch(type, id: id)
    }
}
```

---

## 🔄 **USER PROFILE DELETION WORKFLOW**

### **Complete Deletion Process**

#### **Phase 1: User Confirmation & Security**
1. **Settings Access**: Profile → Account Management → Delete Account
2. **Impact Warning**: Clear explanation of data loss
3. **Re-authentication**: Require password/biometric confirmation
4. **Final Confirmation**: "Delete My Account" with consequences listed

#### **Phase 2: Data Inventory & Deletion**
```swift
struct DeletionInventory {
    let firebaseData: [String]     // Collection paths to delete
    let localPrivateData: [String] // Local data keys to remove
    let healthKitData: [String]    // HealthKit types to revoke
    let cacheData: [String]        // Cached files to clear
    let keychainItems: [String]    // Keychain entries to remove
}

class ProfileDeletionService {
    func executeCompleteDeletion() async throws {
        let inventory = try await generateDeletionInventory()
        
        // Delete in specific order to prevent orphaned data
        try await deleteFirebaseData(inventory.firebaseData)
        try await deleteLocalPrivateData(inventory.localPrivateData)
        try await revokeHealthKitAccess(inventory.healthKitData)
        try await clearCacheData(inventory.cacheData)
        try await removeKeychainItems(inventory.keychainItems)
        
        // Final auth account deletion
        try await deleteFirebaseAuthAccount()
    }
}
```

#### **Phase 3: Verification & Cleanup**
```swift
func verifyCompleteDeletion() async throws -> DeletionVerificationResult {
    var result = DeletionVerificationResult()
    
    // Verify Firebase data removal
    result.firebaseDataRemoved = try await verifyFirebaseCleanup()
    
    // Verify local data removal
    result.localDataRemoved = verifyLocalCleanup()
    
    // Verify auth account deletion
    result.authAccountDeleted = verifyAuthDeletion()
    
    // Verify HealthKit revocation
    result.healthKitRevoked = await verifyHealthKitCleanup()
    
    return result
}
```

### **User Communication During Deletion**
```swift
// Progressive deletion updates
enum DeletionProgress {
    case starting
    case deletingCloudData(progress: Float)
    case deletingLocalData(progress: Float)
    case revokingHealthKit
    case finalizingAccount
    case completed
    case failed(Error)
}

// User-friendly progress messages
extension DeletionProgress {
    var userMessage: String {
        switch self {
        case .starting:
            return "Beginning account deletion..."
        case .deletingCloudData(let progress):
            return "Removing cloud data... \(Int(progress * 100))%"
        case .deletingLocalData(let progress):
            return "Clearing device data... \(Int(progress * 100))%"
        case .revokingHealthKit:
            return "Revoking HealthKit access..."
        case .finalizingAccount:
            return "Finalizing account deletion..."
        case .completed:
            return "Account successfully deleted"
        case .failed(let error):
            return "Deletion failed: \(error.localizedDescription)"
        }
    }
}
```

---

## 📱 **USER INTERFACE IMPLEMENTATION**

### **Settings Integration**
```swift
// Account Management Section in SettingsView
struct AccountManagementSection: View {
    @EnvironmentObject var authService: AuthService
    @State private var showingDeletionFlow = false
    
    var body: some View {
        Section("Account Management") {
            // Profile deletion option
            Button(action: { showingDeletionFlow = true }) {
                Label("Delete Account", systemImage: "trash")
                    .foregroundColor(.red)
            }
        }
        .sheet(isPresented: $showingDeletionFlow) {
            ProfileDeletionFlow()
        }
    }
}
```

### **Profile Deletion Flow Views**
```swift
struct ProfileDeletionFlow: View {
    @State private var currentStep: DeletionStep = .warning
    @State private var authenticationRequired = true
    @State private var deletionProgress: DeletionProgress = .starting
    
    enum DeletionStep {
        case warning
        case authentication
        case confirmation
        case processing
        case completed
    }
    
    var body: some View {
        NavigationStack {
            switch currentStep {
            case .warning:
                DeletionWarningView(onProceed: { currentStep = .authentication })
            case .authentication:
                AuthenticationView(onSuccess: { currentStep = .confirmation })
            case .confirmation:
                DeletionConfirmationView(onConfirm: { currentStep = .processing })
            case .processing:
                DeletionProgressView(progress: $deletionProgress)
            case .completed:
                DeletionCompletedView()
            }
        }
    }
}
```

---

## 🛡️ **PRIVACY COMPLIANCE & REGULATIONS**

### **GDPR Compliance**
- ✅ **Right to Deletion**: Complete data removal within 30 days
- ✅ **Data Portability**: Export functionality for user data
- ✅ **Consent Management**: Clear opt-in/opt-out for data processing
- ✅ **Data Minimization**: Only collect necessary data
- ✅ **Purpose Limitation**: Data used only for stated purposes

### **CCPA Compliance**
- ✅ **Right to Delete**: Consumer can request deletion of personal info
- ✅ **Right to Know**: Clear disclosure of data collection practices
- ✅ **Right to Opt-Out**: Easy opt-out of data sharing
- ✅ **Non-Discrimination**: No penalties for privacy rights exercise

### **HIPAA Considerations**
- ✅ **Local Encryption**: Private health data encrypted at rest
- ✅ **Access Controls**: User-only access to sensitive health information
- ✅ **Audit Trails**: Logging of health data access and modifications
- ✅ **Data Minimization**: Only necessary health data collected

---

## 📋 **IMPLEMENTATION CHECKLIST**

### **Profile Deletion Features**
- [ ] **Enhanced AuthService.deleteAccount()** with complete data removal
- [ ] **ProfileDeletionService** for coordinated deletion workflow
- [ ] **DeletionProgressView** with user-friendly progress updates
- [ ] **Verification system** to ensure complete data removal
- [ ] **Settings integration** for easy access to deletion option

### **Data Privacy Architecture**
- [ ] **PrivateDataManager** for local encrypted storage
- [ ] **LocalEncryptionService** using CryptoKit
- [ ] **UnifiedDataService** with privacy-aware data routing
- [ ] **Data classification system** for automatic privacy handling
- [ ] **Migration tools** for existing data classification

### **Compliance Features**
- [ ] **Data export functionality** for GDPR compliance
- [ ] **Privacy dashboard** showing data usage and controls
- [ ] **Consent management** for optional data processing
- [ ] **Audit logging** for privacy-related actions
- [ ] **Privacy policy updates** reflecting new architecture

### **Testing & Verification**
- [ ] **Complete deletion testing** on test accounts
- [ ] **Data persistence verification** after deletion attempts
- [ ] **Privacy level enforcement** testing
- [ ] **Compliance audit** with privacy regulations
- [ ] **User flow testing** for deletion experience

---

This comprehensive privacy architecture ensures **complete user control** over their data while maintaining **regulatory compliance** and providing a **seamless user experience** for those who choose to delete their profiles.

