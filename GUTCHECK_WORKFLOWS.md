# GutCheck App Workflows 🍽️💩📊

This document defines the complete user workflows for the GutCheck iOS application. These workflows represent the intended user experience and serve as a reference for development and testing.

---

## 🏗️ **App Structure Overview**

### **Navigation Architecture**
- **TabView** with 5 tabs: Dashboard, Meals, Symptoms, Insights, Add (+)
- **NavigationStack** for hierarchical navigation within tabs
- **Sheet presentations** for modal workflows (forms, profile, etc.)
- **Quick action buttons** within views for logging
- **AppRouter** manages programmatic navigation
- **RefreshManager** coordinates data updates across views

### **Core Components**
- **AppRoot.swift** - Main container with TabView
- **AppRouter.swift** - Navigation management  
- **RefreshManager.swift** - Data refresh coordination
- Various **ViewModels** following MVVM pattern

---

## 🌊 **Primary User Workflows**

### **1. App Launch & Authentication**

#### **1.1 First Time User**
1. **Launch app** → See welcome/onboarding screen
2. **Authentication options:**
   - **Email/Password registration** (primary method)
   - (Apple Sign In - planned for future implementation)
3. **HealthKit permission** prompt (optional)
4. **Notification permissions** for reminders
5. **Navigate to Tutorial/Onboarding flow** (see section 1.3)
6. **Navigate to Dashboard** after tutorial completion

#### **1.2 Returning User**
1. **Launch app** → Auto-authenticate if session valid
2. **Navigate to Dashboard** directly
3. **Background data sync** if needed

#### **1.3 First-Time User Tutorial & Onboarding**
*Note: This tutorial system will be implemented after core app functionality is complete*

##### **1.3.1 Welcome & App Purpose**
1. **Welcome Screen:**
   - App logo and tagline
   - Brief explanation: "Track your meals and symptoms to identify food triggers"
   - "Get Started" button
2. **App Purpose Overview:**
   - "Why use GutCheck?" explanation
   - Key benefits: identify triggers, track patterns, improve health
   - Privacy assurance message

##### **1.3.2 Core Features Introduction**
1. **Feature Carousel (swipeable cards):**
   - **Card 1:** "Log Your Meals" 
     - Visual: meal logging screenshot
     - Text: "Track what you eat with photos, barcodes, or manual entry"
   - **Card 2:** "Track Symptoms"
     - Visual: symptom logging screenshot  
     - Text: "Record digestive symptoms using medical-grade scales"
   - **Card 3:** "AI-Powered Insights"
     - Visual: insights dashboard screenshot
     - Text: "Discover patterns and identify potential food triggers"
   - **Card 4:** "Smart Technology"
     - Visual: LiDAR/camera features
     - Text: "Use your phone's camera and LiDAR for precise portion tracking"

##### **1.3.3 Interactive Tutorial Walkthrough**
1. **Dashboard Tour:**
   - Highlight key areas with overlay tooltips
   - Show where recent meals/symptoms appear
   - Point out quick action buttons
   - Demonstrate navigation tabs

2. **Log Your First Meal Tutorial:**
   - Guided overlay on MealBuilderView
   - Step-by-step prompts:
     - "Tap here to add a meal name"
     - "Select your meal type"
     - "Add some food items"
     - "Save your meal"
   - Use sample data that gets cleared after tutorial

3. **Log Your First Symptom Tutorial:**
   - Guided overlay on LogSymptomView
   - Step-by-step prompts:
     - "Select the Bristol Stool Type"
     - "Rate any pain or discomfort"
     - "Add notes if desired"
     - "Save your symptom record"
   - Use sample data that gets cleared after tutorial

4. **Navigation Tutorial:**
   - Highlight each tab with explanatory tooltips
   - Show how to access calendar views
   - Demonstrate the quick action buttons on Dashboard and Calendar views

##### **1.3.4 Dashboard Insights (Currently Implemented)**
1. **Today's Health Score:**
   - Visual 1-10 rating with color-coded bar
   - Automatically calculated based on symptoms and meals
   - Color coding: Red (1-3), Orange (4-6), Yellow (7-8), Green (9-10)

2. **Today's Focus:**
   - Actionable health tip based on current symptoms
   - Examples: "Focus on gentle foods and stress management"
   - "Try anti-inflammatory foods like ginger and turmeric"

3. **Avoidance Tip:**
   - Smart recommendation about what to avoid today
   - Based on recent symptom patterns and food triggers
   - Examples: "Consider avoiding dairy and spicy foods today"

4. **Week Selector:**
   - Browse different days without leaving dashboard
   - All insights update for selected date
   - Real-time data loading for historical analysis

##### **1.3.5 Optional Feature Setup**
1. **HealthKit Integration:**
   - Explanation of benefits
   - Permission request flow
   - Data sync options
   - Privacy controls

2. **Medication Tracking (Currently Implemented):**
   - **Real-time HealthKit Integration:**
     - Automatic medication detection via HealthKit observers
     - Immediate updates when medications are taken
     - Background delivery for continuous monitoring
     - No daily polling required
   
   - **Privacy-First Design:**
     - All medication data processed locally
     - Encrypted local storage for sensitive information
     - HealthKit UUID linking for data integrity
     - User-controlled data sharing
   
   - **Smart Analysis:**
     - Medication-symptom correlation tracking
     - Food-medication interaction warnings
     - Dosage timing optimization
     - Side effect pattern recognition

3. **Notification Preferences:**
   - Explain reminder benefits
   - Meal logging reminders setup
   - Symptom check-in frequency
   - "Enable Reminders" vs "Skip for Now"

4. **Smart Features Preview:**
   - Demo of barcode scanning (if camera permission granted)
   - LiDAR capabilities explanation
   - AI food recognition preview
   - "Try Smart Features" vs "Use Later"

##### **1.3.5 Tutorial Completion**
1. **Congratulations Screen:**
   - "You're all set up!" message
   - Summary of features enabled
   - "Start Tracking" button
2. **Tutorial Data Cleanup:**
   - Remove any sample meal/symptom data created during tutorial
   - Reset tutorial flags in user preferences
3. **Navigate to Dashboard** to begin normal app usage

##### **1.3.6 Help & Tutorial Access (Post-Onboarding)**
1. **Settings → Help & Tutorials:**
   - "Replay Tutorial" option for returning users
   - Individual feature tutorials:
     - "How to Log Meals"
     - "How to Track Symptoms" 
     - "Understanding Your Insights"
     - "Using Smart Features"
2. **Contextual Help:**
   - "?" icons on complex screens
   - Tooltips for first-time feature usage
   - "Need Help?" option in error states

##### **1.3.7 Tutorial Implementation Notes**
- **Tutorial State Management:** Track completion status, skip options
- **Sample Data:** Use clearly marked sample entries that auto-delete
- **Overlay System:** Non-intrusive tooltips and highlights
- **Skip Options:** Allow users to skip any part of tutorial
- **Replay Capability:** Users can re-run tutorials from Settings
- **Progressive Disclosure:** Show advanced features after basic usage
- **Analytics:** Track tutorial completion rates and drop-off points

---

### **2. Dashboard Workflows**

#### **2.1 Dashboard Landing & Week Navigation**
- **Dashboard loads** showing:
  - **Week selector** at top (swipeable week view)
  - **Today's summary** (meals and symptoms for selected date)
  - **Quick action buttons:** "Log Meal" and "Log Symptom"
  - **Profile avatar button** in top-left corner (accesses profile via sheet)

#### **2.2 Date Selection & Summary Updates**
1. **Week selector interaction:**
   - Swipe left/right to navigate weeks
   - Tap specific date → Updates summary for that date
   - Selected date is visually highlighted
2. **Summary updates dynamically:**
   - Shows meals and symptoms for selected date
   - Empty state if no data for selected date
   - Loading state during data fetch

#### **2.3 Data Summary Expansion**
1. **When data is present:**
   - Summary shows condensed view of entries
   - **Tap to expand** → Shows all day's entries in detail
   - Expanded view shows:
     - All meals with timestamps
     - All symptoms with severity indicators
     - Chronological timeline layout

#### **2.4 Meal Entry Navigation**
1. **Tap on specific meal** → Navigate to **MealBuilderView** (view/edit mode)
2. **MealBuilderView functionality (unified interface with integrated details):**
   - **Comprehensive meal display:** All nutrition details, food items, metadata
   - **View mode:** Full meal details in read-only format
   - **Edit mode:** All elements become editable
   - **Detailed nutrition breakdown:** Complete macro/micro nutrients
   - **Food item management:** Add, edit, remove with full details
   - **Meal operations:** Modify, delete, export, share
   - **Real-time updates:** Nutrition recalculates as changes are made
3. **After operations:**
   - **Swipe down gesture** → **Return directly to Dashboard**
   - Dashboard refreshes with updated data

#### **2.5 Symptom Entry Navigation**
1. **Tap on specific symptom** → Navigate to **SymptomDetailView**
2. **SymptomDetailView functionality:**
   - View symptom details
   - **Edit mode** for modifications
   - **Save changes** if edited
3. **After viewing/editing:**
   - **Swipe down gesture** → **Return directly to Dashboard**
   - Dashboard refreshes with updated data

#### **2.6 Quick Action Flow**
1. **Dashboard quick action buttons:**
   - **Tap "Log Meal"** → Navigate directly to **MealBuilderView**
   - **Tap "Log Symptom"** → Navigate directly to **LogSymptomView**
2. **Complete logging flow** → Navigate back to Dashboard
3. **Dashboard auto-refreshes** with new data

#### **2.7 Dashboard Navigation Patterns**
- **Week navigation:** Horizontal swipe/tap for date selection
- **Vertical expansion:** Tap summary to expand/collapse daily entries
- **Deep navigation:** Tap individual entries → Edit views
- **Return pattern:** Swipe down from detail views → Dashboard
- **Auto-refresh:** Dashboard updates after any data changes

---

### **3. Meal Logging Workflows**

#### **3.1 Meal Operations (via MealBuilderView)**
**MealBuilderView serves as the unified interface for ALL meal operations: add, edit, view, and delete**
**MealDetailView is fully integrated within MealBuilderView, providing comprehensive meal information**

1. **Entry points:**
   - **New meal:** Dashboard → "Log Meal" quick action
   - **Existing meal:** Dashboard/Calendar → Tap meal entry
   
2. **MealBuilderView modes:**
   - **Add mode:** Creating new meal (all fields editable)
   - **View mode:** Displaying existing meal (read-only initially)
   - **Edit mode:** Modifying existing meal (toggle to edit)
   
3. **Interface elements (MealDetailView integrated):**
   - **Meal header:** Name, type, date/time
   - **Comprehensive nutrition summary:** 
     - Total calories, macros (carbs, protein, fat)
     - Vitamins, minerals, fiber
     - Allergen information
     - Additive warnings
   - **Food items detailed list:**
     - Individual food items with portions
     - Per-item nutrition breakdown
     - Source indicators (manual, barcode, AI, etc.)
     - Expandable details for each item
   - **Meal metadata:**
     - Creation/modification timestamps
     - Data sources used
     - Confidence scores (for AI-detected items)
   - **Notes section** (expandable)
   - **Action buttons:** Edit/Save/Cancel (context-dependent)
   - **Menu options:** Delete meal, export, share

4. **Food item operations:**
   - **Add food items:** Tap "Add Item" → **MealLoggingOptionsView** (selection screen)
   - **Edit food items:** Tap item to modify quantity/details
   - **Remove food items:** Swipe to delete
   - **Real-time nutrition updates** as items change

5. **Comprehensive meal details displayed (integrated MealDetailView):**
   - **Nutrition overview panel:**
     - Total calories (large, prominent display)
     - Macronutrient breakdown (carbs, protein, fat) with percentages
     - Visual charts/rings showing macro distribution
   - **Detailed nutrition facts:**
     - Vitamins (A, C, D, E, K, B-complex)
     - Minerals (iron, calcium, magnesium, zinc, etc.)
     - Fiber, sugar, sodium content
     - Cholesterol and saturated fat
   - **Health indicators:**
     - Allergen warnings (gluten, dairy, nuts, etc.)
     - Food additive alerts
     - Processed food warnings
     - Nutritional quality score
   - **Food item details:**
     - Individual nutrition per item
     - Serving sizes and portions
     - Data source indicators (manual, barcode, AI)
     - Confidence scores for AI-detected items
   - **Meal metadata:**
     - Timing and meal type
     - Creation and modification dates
     - Photo attachments (if any)
     - Location data (optional)
   
6. **Completion:**
   - **Save meal** (new or edited)
   - **Swipe down gesture** → Return to Dashboard
   - **RefreshManager triggers** dashboard update

#### **3.2 Smart Scan Flow (SmartFoodScannerView)**
1. **Start:** MealBuilderView → "Add Item" → "Smart Scan"
2. **SmartFoodScannerView opens** (enhanced barcode + LiDAR):
   - **Step 1:** Barcode scanning for product identification
   - **Step 2:** LiDAR enhancement for precise portion measurement
   - **Step 3:** Combined data processing and validation
   - **Step 4:** Results presentation with nutrition breakdown
3. **Multi-step process:**
   - Scan barcode → Identify product
   - Use LiDAR → Measure actual portion
   - AI processing → Calculate precise nutrition
   - User confirmation → Finalize food item
4. **Return to MealBuilderView** with enhanced food item data
5. **Continue editing** or save meal → Swipe down to Dashboard

#### **3.3 Individual Tool Flows**
**Accessible via MealLoggingOptionsView selection screen:**

**3.3a Standalone Barcode Scanning:**
- Quick barcode-only scanning
- OpenFoodFacts API lookup
- Manual portion entry

**3.3b Standalone LiDAR Scanning:**
- LiDAR-only portion measurement
- Manual food identification
- Volume-based nutrition estimation

**3.3c Food Search:**
- Text-based food search
- Nutritionix API integration
- Manual food database lookup

**3.3d Recent Items:**
- Previously logged food items
- Quick re-addition with portion adjustment
- History-based suggestions

#### **3.4 Food Item Addition (MealLoggingOptionsView)**
1. **Start:** MealBuilderView → "Add Item" button
2. **MealLoggingOptionsView opens** with selection options:
   
   **Primary Options (Large Cards):**
   - **🔍 Search:** Manual food search and selection
   - **📱 Smart Scan:** Enhanced barcode + LiDAR combination (SmartFoodScannerView)
   
   **Additional Options (Secondary Cards):**
   - **📊 Barcode:** Standalone barcode scanning
   - **📏 LiDAR:** Standalone LiDAR portion scanning  
   - **🕒 Recent:** Previously used food items
   - **💧 Log Water:** Quick water intake logging
   
3. **User selects option** → Navigate to appropriate tool/view
4. **Complete food item addition** → Return to MealBuilderView
5. **Item appears in meal** with nutrition data
6. **Continue editing** or save meal → Swipe down to Dashboard

#### **3.5 Meal Deletion (within MealBuilderView)**
1. **Start:** Open existing meal in MealBuilderView (view mode)
2. **Access delete option:**
   - Menu button in toolbar
   - "Delete Meal" option
3. **Confirmation dialog:**
   - "Are you sure you want to delete this meal?"
   - "Delete" / "Cancel" options
4. **After deletion:**
   - **Swipe down** or automatic return to Dashboard
   - **RefreshManager triggers** update to remove meal from display

---

### **4. Symptom Logging Workflows**

#### **4.1 Symptom Entry**
1. **Start:** Dashboard → "Log Symptom" quick action OR Symptoms tab → "Log Symptom" button
2. **LogSymptomView opens:**
   - Date/time picker
   - Bristol Stool Chart selector (1-7)
   - Pain level (none/mild/moderate/severe)
   - Urgency level (none/mild/moderate/severe)
   - Blood presence (yes/no)
   - Completeness feeling (complete/incomplete)
   - Additional symptoms checklist
   - Notes (optional)
3. **Review & save** → Return to Dashboard
4. **RefreshManager triggers** update

#### **4.2 Symptom History & Editing**
1. **Start:** Symptoms tab or Dashboard symptom card
2. **SymptomHistoryView:**
   - Chronological list
   - Filter options (date range, severity)
   - Search functionality
3. **Tap symptom** → SymptomDetailView
4. **Edit if needed** → Save → Return

---

### **5. Calendar & History Workflows**

#### **5.1 Meals Calendar**
1. **Start:** Tap "Meals" tab
2. **CalendarView (meals mode):**
   - Calendar widget showing dates
   - Dots/indicators for days with meals
   - Today highlighted
   - **"Log Meal" quick action button** at bottom/top
3. **Select date:**
   - Shows meals for that day
   - **Tap meal** → MealBuilderView (view/edit mode for existing meal)
   - **Tap "Log Meal" button** → MealBuilderView (add mode for new meal on selected date)

#### **5.2 Symptoms Calendar**
1. **Start:** Tap "Symptoms" tab  
2. **CalendarView (symptoms mode):**
   - Calendar with symptom indicators
   - Color coding by severity
   - Pattern visualization
   - **"Log Symptom" quick action button** at bottom/top
3. **Select date:**
   - Shows symptoms for that day
   - Tap symptom → SymptomDetailView
   - **Tap "Log Symptom" button** → LogSymptomView (new symptom for selected date)

#### **5.3 Combined Day View**
1. **Start:** Dashboard → "View Day" or Calendar → select date
2. **CalendarDetailView:**
   - Both meals and symptoms for selected date
   - Timeline view
   - **Quick action buttons:** "Log Meal" and "Log Symptom" for selected date
   - Summary stats

---

### **6. Insights & Analytics Workflows**

#### **6.1 Insights Dashboard**
1. **Start:** Tap "Insights" tab
2. **InsightsView:**
   - AI-generated insights cards
   - Trend charts (weekly/monthly)
   - Trigger analysis
   - Pattern recognition
3. **Tap insight card** → InsightDetailView with deep dive

#### **6.2 Trigger Analysis**
1. **Start:** Insights → "Trigger Analysis"
2. **View correlations:**
   - Food items vs symptom severity
   - Timing patterns
   - Confidence scores
   - Recommendations
3. **Export/share insights** option

---

### **7. Profile & Settings Workflows**

#### **7.1 Profile Access Points**
**Profile Avatar Button** appears in multiple locations:
- **Dashboard View:** Top-left corner as ProfileAvatarButton
- **Calendar View:** Top-left corner as ProfileAvatarButton
- **Meals Tab:** Top-left corner as ProfileAvatarButton
- **Symptoms Tab:** Top-left corner as ProfileAvatarButton

#### **7.2 Profile Navigation Flow**
1. **Start:** Any view → Tap **ProfileAvatarButton** in top-left corner
2. **Navigation:** `router.showProfile()` → **UserProfileView** presented as **sheet**
3. **UserProfileView contains:**
   - **Profile Header:** Photo, name, email, join date
   - **Profile Info Section:** Basic user information display
   - **Profile Actions:**
     - **"Settings"** → Opens SettingsView as sheet
     - **"Health Data Integration"** → Opens HealthDataIntegrationView as sheet  
     - **"Reminders"** → Opens UserRemindersView as sheet
     - **"Sign Out"** → Signs out and dismisses profile
4. **Return:** Tap **"Close"** button in navigation bar → Returns to previous screen

#### **7.3 Profile Sub-Workflows**

##### **7.3.1 Settings Access**
1. **From Profile:** Tap "Settings" button
2. **SettingsView opens** as sheet over profile sheet
3. **Settings contains:**
   - Notification preferences
   - Data export options
   - Privacy settings
   - **Help & Tutorials section:**
     - "Replay Onboarding Tutorial"
     - "How to Log Meals"
     - "How to Track Symptoms"
     - "Understanding Insights"
     - "Smart Features Guide"
     - "FAQ & Tips"
   - Debug tools (dev mode)
   - About/help sections
4. **Return:** Dismiss settings → Back to UserProfileView

##### **7.3.2 Health Data Integration**
1. **From Profile:** Tap "Health Data Integration" button
2. **HealthDataIntegrationView opens** as sheet
3. **Health integration options:**
   - HealthKit permission setup
   - Data sync preferences
   - Import/export controls
4. **Return:** Dismiss health data view → Back to UserProfileView

##### **7.3.3 Reminders Setup**
1. **From Profile:** Tap "Reminders" button
2. **UserRemindersView opens** as sheet
3. **Reminder configuration:**
   - Meal logging reminders
   - Symptom check-ins
   - Weekly review prompts
   - Notification timing
4. **Return:** Dismiss reminders view → Back to UserProfileView

#### **7.4 Profile Return Navigation**
**Sheet-based navigation ensures proper return flow:**
- **Single Profile Access:** Sheet presentation maintains navigation context
- **Nested Sheets:** Settings/Health/Reminders open over profile, proper dismissal returns to profile
- **Close Profile:** "Close" button always returns to the exact previous screen
- **Sign Out:** Special case - signs out user and dismisses all sheets

#### **7.5 Profile Navigation Architecture**
```
Any Screen → ProfileAvatarButton
     ↓
UserProfileView (Sheet)
     ├── Settings (Sheet over Profile)
     ├── Health Integration (Sheet over Profile)  
     ├── Reminders (Sheet over Profile)
     ├── Sign Out (Dismisses all + Auth)
     └── Close (Returns to original screen)
```

#### **7.6 Data Export**
1. **Start:** Settings → "Export Data"
2. **Export options:**
   - Date range selection
   - CSV format
   - HealthKit sync
   - Email/share options

---

### **8. Smart Features Workflows**

#### **8.1 AI Food Recognition**
1. **Start:** LogMealView → "Photo Recognition"
2. **Camera capture** food photo
3. **AI processing:**
   - Identifies food items
   - Estimates portions
   - Suggests nutrition values
4. **User confirmation/editing**
5. **Add to meal**

#### **8.2 Reminder System**
1. **Setup:** Settings → Notification preferences
2. **Configure reminders:**
   - Meal logging reminders
   - Symptom check-ins
   - Weekly review prompts
3. **Receive notifications** → Tap to open relevant log

---

## 🔄 **Cross-Feature Workflows**

### **Data Sync & Offline**
- **Offline mode:** App functions without internet
- **Background sync:** Data uploads when connected
- **Conflict resolution:** User chooses in case of conflicts

### **HealthKit Integration**
- **Permission flow:** One-time setup
- **Data writing:** Nutrition and symptoms to Health app
- **Data reading:** Weight, activity for context

### **Search & Filtering**
- **Global search:** Find meals/symptoms across all data
- **Date filtering:** All views support date ranges
- **Tag system:** Custom tags for organization

---

## 🚀 **Navigation Patterns**

### **Tab Navigation**
- **Dashboard:** Main hub with quick action buttons
- **Meals:** Calendar view of meal history with "Log Meal" button
- **Symptoms:** Calendar view of symptom history with "Log Symptom" button
- **Insights:** Analytics and AI insights

### **Stack Navigation**
- **Push/Pop:** Standard drill-down navigation
- **Back buttons:** Always available
- **Breadcrumbs:** Clear navigation path

### **Modal Presentation**
- **Sheets:** Forms, profile, settings
- **Full screen:** Camera, scanner views
- **Alerts:** Confirmations, errors

---

## 🎯 **Success Criteria**

### **Performance**
- Launch time < 2 seconds
- Smooth 60fps scrolling
- Camera features responsive

### **User Experience**
- Intuitive navigation (< 3 taps to any feature)
- Clear feedback for all actions
- Graceful error handling

### **Data Integrity**
- No data loss during offline/online transitions
- Accurate nutrition calculations
- Reliable sync across devices

---

**Last Updated:** [Current Date]  
**Created by:** Mark Conley  
**Version:** 1.0

---

## 📝 **Notes for Development**

This workflow document should be used to:
1. **Verify current implementation** against intended design
2. **Identify missing features** or broken flows
3. **Guide development priorities** for fixes/enhancements
4. **Test user journeys** systematically
5. **Document API requirements** for external services

Each workflow should be testable as a complete user journey from start to finish.

---

## 🤖 **AI vs API Architecture Decision: Food Information Services**

### **Current Architecture Analysis**

GutCheck currently uses a **hybrid multi-source approach** for food data:

🔄 **Multi-Source Data Pipeline:**
- **Nutritionix API**: Comprehensive nutrition database with detailed macros
- **OpenFoodFacts**: Open-source product database with barcode support  
- **Google Vision AI**: Food recognition from photos
- **Core ML**: On-device food classification (Inception v3 model)
- **Custom merging logic**: Combines results from multiple sources

### **AI vs API Comparison**

#### **✅ Pros of AI-Based Nutrition Data**

1. **Flexibility & Customization**
   - Can handle unusual/custom foods better
   - Adaptable to specific dietary needs (keto, paleo, etc.)
   - Can provide contextual nutrition advice

2. **Cost Efficiency**
   - No per-request API costs (after initial setup)
   - No rate limits or quotas
   - Scalable without increasing costs

3. **Privacy & Offline Capability**
   - On-device processing possible
   - No data sent to third parties
   - Works without internet connection

4. **Integration with Existing AI**
   - Synergizes with current Google Vision + Core ML setup
   - Can provide holistic food + health analysis
   - Better integration with symptom tracking insights

#### **❌ Cons of AI-Based Nutrition Data**

1. **Accuracy Concerns**
   - **Nutritionix**: Professional-grade database with USDA backing
   - **AI**: Still developing, can hallucinate nutrition facts
   - **Liability**: Medical/health apps need high accuracy

2. **Data Completeness**
   - **APIs**: Millions of verified products with barcodes
   - **AI**: Limited by training data, may miss niche products
   - **Micronutrients**: APIs have detailed vitamin/mineral data

3. **Maintenance Overhead**
   - **APIs**: Continuously updated by professional teams
   - **AI**: Requires model updates, training data management
   - **Verification**: Need systems to validate AI-generated data

4. **Regulatory Compliance**
   - Health apps often require verified nutrition databases
   - FDA/USDA standards favor established databases
   - Insurance/medical integration may require API-sourced data

### **Recommendation: Hybrid Enhancement Strategy**

**Keep current API foundation** but enhance strategically with AI:

#### **🎯 Phase 1: Smart AI Integration**
```swift
// Enhance existing service with AI fallback
class EnhancedFoodService {
    func getFoodInfo(query: String) async -> FoodInfo {
        // 1. Try APIs first (high accuracy)
        if let apiResult = await tryAPIs(query) {
            return apiResult
        }
        
        // 2. AI fallback for unknown foods
        return await aiNutritionEstimate(query)
    }
}
```

#### **🎯 Phase 2: AI-Powered Features**
- **Smart portion estimation** from photos
- **Personalized nutrition recommendations** 
- **Ingredient substitution suggestions**
- **Meal pattern analysis** with symptom correlation

#### **🎯 Phase 3: Custom Food AI**
- Train models on user data (anonymized)
- Specialized GI-focused nutrition insights
- Custom food combinations and recipes

### **Specific Use Cases for AI**

**✅ Where AI Excels:**
- Custom/homemade meals without barcodes
- Portion size estimation from photos
- Personalized recommendations based on symptoms
- Cultural/regional foods missing from databases

**❌ Keep APIs for:**
- Packaged foods with barcodes
- Restaurant chain items
- Standardized nutrition facts
- Regulatory compliance requirements

### **Implementation Strategy**

```swift
enum FoodDataSource {
    case nutritionix    // High accuracy, comprehensive
    case openFoodFacts  // Barcode products
    case aiEstimate     // Fallback for unknown items
    case userInput      // Custom entries
}

// Prioritized waterfall approach
class SmartFoodDataService {
    func getNutritionInfo(for food: String) async -> (NutritionInfo, DataSource) {
        // 1. Try barcode scan → OpenFoodFacts
        // 2. Try text search → Nutritionix  
        // 3. AI estimation as fallback
        // 4. Allow manual override
    }
}
```

### **Conclusion**

**Don't replace APIs entirely.** Instead, use AI to **fill gaps and enhance the experience** where APIs fall short. The current multi-source approach is sophisticated—add AI as another layer for edge cases and personalization.

The health/medical nature of gut health tracking makes accuracy paramount, so keeping verified nutrition databases as the primary source while leveraging AI for enhanced features is the safest and most effective approach.

## Data Sources

### 1. **User Input**
- Manual food logging
- Symptom tracking
- Meal notes and observations
- Custom health indicators

### 2. **External APIs**
- **Nutritionix**: Comprehensive nutrition database
- **OpenFoodFacts**: Barcode product information
- **Google Vision**: AI-powered food recognition
- **AI Enhancement**: Fallback for missing nutrition data

### 3. **Device Sensors**
- **Camera**: Food photo capture
- **LiDAR**: 3D food scanning (future)
- **GPS**: Location-based insights (optional)

### 4. **HealthKit Integration**
- **User Characteristics**: Age, weight, height, activity level
- **Health Data**: Heart rate, steps, sleep patterns
- **Medication Data**: **Real-time medication tracking** via HealthKit observers
  - Immediate updates when medications are taken
  - Automatic background delivery
  - Privacy-compliant local processing
  - No daily polling required

### 5. **AI Analysis**
- Pattern recognition in food-symptom correlations
- Nutritional impact predictions
- Personalized recommendations
- Medication interaction analysis

### 6. **Dashboard Insights (New)**
- **Health Score Calculation**: Automated 1-10 rating based on symptoms and meals
- **Smart Focus Generation**: AI-powered daily health recommendations
- **Pattern-Based Avoidance Tips**: Data-driven food trigger warnings
- **Historical Trend Analysis**: Week-over-week health pattern tracking
