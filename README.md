# GutCheck 🍽️💩📊

A comprehensive iOS application for tracking digestive health, meals, symptoms, and medication interactions. GutCheck uses AI-powered insights, HealthKit integration, and real-time data analysis to help users identify food triggers and improve their gut health.

## ✨ **Key Features**

### **🤖 Smart Health Insights**
- **Automated Health Scoring**: 1-10 rating system based on symptoms and meals
- **Daily Focus Recommendations**: AI-generated personalized health advice
- **Pattern-Based Warnings**: Smart food trigger avoidance tips
- **Historical Analysis**: Week-over-week health pattern tracking

### **📱 Comprehensive Tracking**
- **Meal Logging**: Photo recognition, barcode scanning, and manual entry
- **Symptom Monitoring**: Medical-grade scales (Bristol Stool Type, pain levels)
- **Medication Integration**: Real-time HealthKit medication tracking with dose logging
- **Calendar Views**: Unified calendar for meals, symptoms, and insights

### **🔔 Notifications & Reminders**
- **Meal Reminders**: Per-meal-type notifications (Breakfast, Lunch, Dinner) firing 15 minutes after scheduled meal time
- **Apple Reminders Integration**: EventKit integration to sync health reminders with Apple Reminders
- **iOS Notification Support**: Full UNUserNotificationCenter delegate for foreground and background notifications

### **🔒 Privacy-First Design**
- **Local Processing**: Sensitive data processed on-device
- **Encrypted Storage**: Local data encrypted with CryptoKit
- **HealthKit Integration**: Secure health data access
- **User Control**: Complete data ownership and deletion

### **🧠 AI-Powered Analysis**
- **Food Recognition**: Core ML integration for food identification
- **Nutrition Estimation**: AI fallback for missing nutrition data
- **Pattern Recognition**: Food-symptom correlation analysis
- **Smart Recommendations**: Personalized health insights

## 🏗️ **Architecture**

- **Platform**: iOS 15.0+ (SwiftUI)
- **Architecture**: MVVM with Repository Pattern
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **AI/ML**: Core ML, Google Vision API, Custom AI services
- **Health Integration**: HealthKit with real-time observers
- **Notifications**: UNUserNotificationCenter + EventKit (Apple Reminders)
- **Data Privacy**: Local encryption + cloud storage hybrid

## 🚀 **Getting Started**

### **Prerequisites**
- Xcode 15.0+
- iOS 15.0+ deployment target
- Firebase project setup
- Google Cloud Vision API key

### **Installation**
1. Clone the repository
2. Install dependencies via Swift Package Manager
3. Configure Firebase and Google Cloud services
4. Build and run on iOS device or simulator

## 📊 **Current Status**

**Project Status**: Production Ready with Active Development

**Completed Features**:
- ✅ Core app architecture and navigation
- ✅ Authentication and user management
- ✅ Unified meal tracking system
- ✅ Comprehensive symptom tracking
- ✅ Dashboard insights and health scoring
- ✅ Dashboard Today's Summary with logged medication doses
- ✅ Calendar and analytics views
- ✅ HealthKit medication integration with real-time sync
- ✅ Manual medication tracking and dose logging
- ✅ Medication calendar view (dedicated Meds tab)
- ✅ AI-powered food recognition and analysis
- ✅ Reusable meal templates
- ✅ Enhanced insights system
- ✅ App notifications with per-meal-type reminders
- ✅ Apple Reminders integration via EventKit
- ✅ Card-style Log buttons (Meal, Symptom, Dose)
- ✅ Edit meal workflow with MealBuilderView
- ✅ Service layer consolidation and dead code removal
- ✅ CI/CD pipeline with automated security scanning

**In Development**:
- 🚧 Advanced AI features
- 🚧 Medication interaction analysis
- 🚧 Healthcare provider portal

## 🤝 **Contributing**

We welcome contributions! Please see our [Contributing Guide](docs/contributing.md) for details on:
- Code style and standards
- Testing requirements
- Pull request process
- Development setup

## 📚 **Documentation**

All documentation lives in the **[`docs/`](docs/)** folder:

| Document | Description |
|---|---|
| [documentation.md](docs/documentation.md) | Complete project guide — architecture, workflows, API integration |
| [contributing.md](docs/contributing.md) | How to contribute, code style, PR process |
| [firebase-setup.md](docs/firebase-setup.md) | Firebase setup, Firestore rules, security testing |
| [compliance.md](docs/compliance.md) | GDPR/CCPA/HIPAA compliance, permissions guide |
| [accessibility.md](docs/accessibility.md) | Accessibility checklist and design standards |
| [accessibility-progress.md](docs/accessibility-progress.md) | Phase 0–2 implementation progress |
| [color-system.md](docs/color-system.md) | Color palette, assets, and installation guide |
| [insights-system.md](docs/insights-system.md) | Insights and pattern recognition system |
| [core-data.md](docs/core-data.md) | CoreData implementation details |
| [performance-profiling.md](docs/performance-profiling.md) | Performance monitoring system |
| [compliance.md](docs/compliance.md) | Privacy compliance and permissions |
| [navigation-plan.md](docs/navigation-plan.md) | Native navigation architecture |
| [repository-pattern.md](docs/repository-pattern.md) | Repository pattern implementation |

## 🔐 **Privacy & Compliance**

GutCheck is designed with privacy and compliance in mind:
- **GDPR Compliant**: European data protection standards
- **CCPA Compliant**: California privacy regulations
- **HIPAA Ready**: Healthcare data protection framework
- **Local Processing**: Sensitive data never leaves the device

## 📱 **Screenshots**

*Screenshots coming soon*

## 🏆 **Achievements**

- **Unified Architecture**: Single codebase for all meal operations
- **Real-time HealthKit**: Live medication tracking without polling
- **AI Integration**: Smart nutrition estimation and pattern recognition
- **Privacy Compliance**: Enterprise-grade data protection
- **Performance**: Sub-second data loading and insights generation
- **Notification System**: Smart meal and health reminders
- **Apple Reminders Sync**: Native iOS Reminders integration via EventKit
- **Enhanced Analytics**: Advanced pattern recognition and insights

## 📞 **Support**

For support, questions, or feature requests:
- Create an issue in this repository
- Check our [Complete Documentation](docs/documentation.md)
- Review our [Contributing Guide](docs/contributing.md)

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ for better gut health**

*Last Updated: March 2026*
