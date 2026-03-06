# GutCheck Complete Documentation 📚

This document consolidates all project documentation, workflows, and technical information for the GutCheck iOS application.

---

## 📖 **Table of Contents**

1. [Project Overview](#project-overview)
2. [Architecture & Technical Design](#architecture--technical-design)
3. [User Workflows](#user-workflows)
4. [Development Guide](#development-guide)
5. [Project Status](#project-status)
6. [Privacy & Compliance](#privacy--compliance)
7. [API Integration](#api-integration)
8. [Bug Fixes & Enhancements](#bug-fixes--enhancements)
9. [Folder Structure](#folder-structure)
10. [Contributing Guidelines](#contributing-guidelines)

---

## 🎯 **Project Overview**

### **What is GutCheck?**
GutCheck is a comprehensive iOS application for tracking digestive health, meals, symptoms, and medication interactions. The app uses AI-powered insights, HealthKit integration, and real-time data analysis to help users identify food triggers and improve their gut health.

### **Key Features**
- **🤖 Smart Health Insights**: Automated health scoring, AI-generated recommendations
- **📱 Comprehensive Tracking**: Meal logging, symptom monitoring, medication integration
- **🔒 Privacy-First Design**: Local processing, encrypted storage, user control
- **🧠 AI-Powered Analysis**: Food recognition, nutrition estimation, pattern recognition

### **Target Platform**
- **Platform**: iOS 15.0+ (SwiftUI)
- **Architecture**: MVVM with Repository Pattern
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **AI/ML**: Core ML, Google Vision API, Custom AI services
- **Health Integration**: HealthKit with real-time observers

---

## 🏗️ **Architecture & Technical Design**

### **Core Architecture**
- **MVVM Pattern**: Clear separation of concerns between Views, ViewModels, and Models
- **Repository Pattern**: Standardized data access layer with Firebase integration
- **Navigation System**: AppRouter with centralized navigation management
- **State Management**: RefreshManager for coordinated data updates
- **Error Handling**: Centralized error handling service

### **Data Flow**
```
User Input → View → ViewModel → Service → Repository → Firebase/Local Storage
                ↓
            UI Updates ← State Management ← Data Processing
```

### **Key Components**
- **AppRoot.swift**: Main container with TabView
- **AppRouter.swift**: Navigation management
- **RefreshManager.swift**: Data refresh coordination
- **BaseFirebaseRepository**: Standardized data access
- **UnifiedDataService**: Local encrypted storage

### **Privacy Architecture**
- **Local Processing**: Sensitive data processed on-device
- **Encrypted Storage**: Local data encrypted with CryptoKit
- **Hybrid Storage**: Private data local, shared data in cloud
- **User Control**: Complete data ownership and deletion

---

## 🌊 **User Workflows**

### **App Launch & Authentication**
1. **First Time User**
   - Launch app → Welcome/onboarding screen
   - Email/password registration
   - HealthKit permission prompt (optional)
   - Notification permissions
   - Tutorial/onboarding flow
   - Navigate to Dashboard

2. **Returning User**
   - Launch app → Auto-authenticate
   - Navigate to Dashboard directly
   - Background data sync if needed

### **Core User Journeys**

#### **Meal Logging Workflow**
1. **Access**: Dashboard → Quick Action → "Log Meal"
2. **Meal Setup**: Select meal type, set date/time
3. **Food Addition**: 
   - Photo recognition (Google Vision API)
   - Barcode scanning
   - Manual search (Nutritionix/OpenFoodFacts)
   - Manual entry
4. **Review & Save**: Confirm details, save meal
5. **Template Option**: Save as reusable template if named

#### **Symptom Tracking Workflow**
1. **Access**: Dashboard → Quick Action → "Log Symptom"
2. **Symptom Details**: 
   - Bristol Stool Type (1-7 scale)
   - Pain level (0-10 scale)
   - Urgency level
   - Additional notes
3. **Save**: Store symptom with timestamp
4. **Pattern Analysis**: Correlate with recent meals

#### **Insights & Analytics Workflow**
1. **Dashboard**: View daily health score and recommendations
2. **Calendar**: Browse historical data and patterns
3. **Insights**: AI-generated health pattern discovery
4. **Export**: Share data with healthcare providers

### **Navigation Structure**
- **TabView**: Dashboard, Meals, Symptoms, Insights, Add (+)
- **NavigationStack**: Hierarchical navigation within tabs
- **Sheet Presentations**: Modal workflows for forms
- **Quick Actions**: Fast access to common tasks

---

## 👨‍💻 **Development Guide**

### **Setup Requirements**
- **Xcode**: 15.0+
- **iOS Deployment Target**: 15.0+
- **Firebase Project**: Configured with Firestore, Auth, Storage
- **Google Cloud Vision API**: Key configured
- **HealthKit**: Enabled in project capabilities

### **Project Structure**
```
GutCheck/
├── Models/           # Data models and structures
├── Views/            # SwiftUI views and UI components
├── ViewModels/       # MVVM view models
├── Services/         # Business logic and external integrations
├── Extensions/       # Swift extensions and utilities
├── Resources/        # Assets, ML models, configuration
└── Documentation/    # Project documentation
```

### **Key Development Patterns**
- **MVVM**: Views observe ViewModels, ViewModels update Models
- **Repository Pattern**: Abstract data access behind interfaces
- **Async/Await**: Modern Swift concurrency for data operations
- **Combine**: Reactive programming for UI updates
- **Dependency Injection**: Services injected into ViewModels

### **Testing Strategy**
- **Unit Tests**: Core services and business logic
- **UI Tests**: Critical user workflows
- **Integration Tests**: Repository and service interactions
- **Code Coverage**: Target 80%+ for critical paths

---

## 📊 **Project Status**

### **Current Status**: Production Ready with Active Development

### **Completed Features** ✅
- **Core App Architecture**: MVVM, Repository Pattern, Navigation
- **Authentication & User Management**: Firebase Auth, user profiles
- **Meal Tracking System**: Unified architecture, food search, barcode scanning
- **Symptom Tracking**: Medical-grade scales, comprehensive logging
- **Dashboard & Insights**: Health scoring, recommendations, pattern analysis
- **Calendar & Analytics**: Unified calendar, data visualization
- **HealthKit Integration**: Medication tracking, user characteristics
- **AI & Machine Learning**: Food recognition, nutrition estimation
- **Reusable Meal Templates**: Save and reuse meal combinations
- **Enhanced Insights System**: Pattern recognition, predictive analytics

### **In Development** 🚧
- **Advanced AI Features**: Custom food recognition, portion estimation
- **Medication Interaction Analysis**: Food-drug interactions, timing optimization
- **Healthcare Provider Portal**: Secure data sharing system

### **Planned Features** 📋
- **Social Features**: Anonymous data sharing, family accounts
- **Enhanced HealthKit**: Exercise correlation, sleep analysis, stress monitoring
- **Internationalization**: Multi-language support
- **Research Integration**: Clinical trial participation features

---

## 🔐 **Privacy & Compliance**

### **Privacy Framework**
- **GDPR Compliant**: European data protection standards
- **CCPA Compliant**: California privacy regulations
- **HIPAA Ready**: Healthcare data protection framework
- **Local Processing**: Sensitive data never leaves the device

### **Data Classification**
- **Private Data**: Symptoms, personal notes, health scores
- **Shared Data**: Meal templates, anonymous insights
- **HealthKit Data**: Managed by iOS privacy controls
- **Analytics Data**: Aggregated, non-identifiable

### **Security Measures**
- **Data Encryption**: Local data encrypted with CryptoKit
- **Secure Storage**: Keychain for sensitive credentials
- **Network Security**: HTTPS for all API communications
- **Access Control**: User authentication and authorization

---

## 🔌 **API Integration**

### **External Services**
- **Firebase**: Authentication, Firestore database, Storage
- **Google Vision API**: Food recognition from photos
- **Nutritionix**: Food database and nutrition information
- **OpenFoodFacts**: Open-source food database
- **HealthKit**: iOS health data integration

### **Data Flow**
1. **User Input**: Photos, barcodes, manual entry
2. **API Processing**: External service analysis
3. **Local Storage**: Encrypted local storage
4. **Cloud Sync**: Firebase synchronization
5. **HealthKit**: iOS health app integration

### **Error Handling**
- **Graceful Degradation**: App continues working with limited functionality
- **User Feedback**: Clear error messages and recovery options
- **Retry Logic**: Automatic retry for transient failures
- **Offline Support**: Core functionality without internet

---

## 🐛 **Bug Fixes & Enhancements**

### **Recent Fixes**
- **HealthKit Integration**: Removed invalid medication data types
- **UI Consistency**: Unified date/time display across screens
- **Layout Improvements**: Better text wrapping and vertical stacking
- **Compilation Errors**: Resolved various Swift compilation issues
- **Template System**: Fixed meal template creation and management

### **Performance Improvements**
- **Data Loading**: Sub-second dashboard loading
- **Memory Management**: Optimized for iOS devices
- **Background Processing**: Minimal battery impact
- **Caching**: Smart data caching and refresh

### **User Experience Enhancements**
- **Intuitive Interface**: Clean, modern UI following iOS guidelines
- **Smart Insights**: Automated health scoring and recommendations
- **Seamless Navigation**: Consistent navigation patterns
- **Accessibility**: Full VoiceOver and accessibility support

---

## 📁 **Folder Structure**

### **Root Level**
```
GutCheck/
├── .github/          # GitHub workflows and configurations
├── .claude/          # AI assistant configurations
├── GutCheck/         # Main iOS project
├── GutCheckTests/    # Unit tests
├── GutCheckUITests/  # UI tests
└── Documentation/    # Project documentation
```

### **Main Project Structure**
```
GutCheck/GutCheck/
├── Assets.xcassets/  # App icons and colors
├── Models/           # Data models and structures
├── Views/            # SwiftUI views organized by feature
├── ViewModels/       # MVVM view models
├── Services/         # Business logic and external integrations
├── Extensions/       # Swift extensions
├── Resources/        # ML models and configuration
└── Documentation/    # Feature-specific documentation
```

### **Key Directories**
- **Models/**: Core data structures, HealthKit models, nutrition models
- **Views/**: Organized by feature (Dashboard, Meal, Symptom, etc.)
- **Services/**: Business logic, API integration, data management
- **ViewModels/**: MVVM pattern implementation
- **Extensions/**: Swift language extensions and utilities

---

## 🤝 **Contributing Guidelines**

### **Code Standards**
- **Swift Style**: Follow Swift API Design Guidelines
- **Documentation**: Comprehensive inline documentation
- **Error Handling**: Graceful error handling with user feedback
- **Testing**: Unit tests for new features
- **Accessibility**: VoiceOver and accessibility support

### **Development Process**
1. **Feature Branch**: Create feature branch from main
2. **Development**: Implement feature with tests
3. **Code Review**: Submit pull request for review
4. **Testing**: Ensure all tests pass
5. **Merge**: Merge to main after approval

### **Pull Request Requirements**
- **Description**: Clear description of changes
- **Testing**: Evidence of testing completed
- **Documentation**: Updated documentation if needed
- **Code Coverage**: Maintain or improve test coverage

### **Getting Started**
1. **Fork Repository**: Create your fork
2. **Clone**: Clone your fork locally
3. **Setup**: Install dependencies and configure environment
4. **Development**: Make changes and test thoroughly
5. **Submit**: Create pull request with detailed description

---

## 📈 **Performance Metrics**

### **Current Performance**
- **App Launch**: <2 seconds
- **Data Loading**: <1 second for dashboard
- **Memory Usage**: Optimized for iOS devices
- **Battery Impact**: Minimal background processing

### **Quality Metrics**
- **Code Coverage**: Core services covered
- **Documentation**: 90%+ documented
- **Error Handling**: Comprehensive error management
- **Accessibility**: Full VoiceOver support

---

## 🚀 **Deployment & CI/CD**

### **GitHub Actions Workflow**
- **Build & Test**: Automated build and testing on macOS
- **iOS Simulator**: Testing on latest iOS simulator
- **Code Coverage**: Automated coverage reporting
- **Artifact Storage**: Build artifacts for debugging

### **Deployment Process**
1. **Code Review**: All changes reviewed
2. **Automated Testing**: CI/CD pipeline validation
3. **Manual Testing**: Final validation on devices
4. **App Store**: Submission and review process

---

## 📞 **Support & Resources**

### **Getting Help**
- **Issues**: Create GitHub issues for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions
- **Documentation**: Refer to this consolidated guide
- **Code Examples**: Check existing implementations

### **Useful Resources**
- **SwiftUI Documentation**: Apple's official SwiftUI guide
- **Firebase Documentation**: Google Firebase guides
- **HealthKit Documentation**: Apple HealthKit reference
- **iOS Human Interface Guidelines**: Apple's design guidelines

---

## 📝 **Changelog**

### **Latest Updates**
- **Reusable Meal Templates**: Save and reuse meal combinations
- **Enhanced Insights System**: Advanced pattern recognition
- **UI Improvements**: Better layout and consistency
- **Bug Fixes**: Various compilation and runtime fixes
- **Documentation**: Consolidated all project documentation

### **Version History**
- **v1.0**: Core app functionality
- **v1.1**: HealthKit integration
- **v1.2**: AI-powered insights
- **v1.3**: Reusable meal templates
- **v1.4**: Enhanced analytics and UI improvements

---

*Last Updated: December 2025*
*Documentation Status: Consolidated and Updated*
*Project Status: Production Ready with Active Development*

---

**Built with ❤️ for better gut health**
