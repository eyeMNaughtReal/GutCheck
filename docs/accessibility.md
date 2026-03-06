# 🎯 Accessibility Implementation Checklist - GutCheck App
**Created:** February 23, 2026  
**Goal:** Make GutCheck fully accessible and compliant with WCAG 2.1 Level AA  
**Target Completion:** 3-5 days

---

## 📋 Pre-Implementation Audit

### Phase 0: Discovery & Assessment
- [ ] Run Accessibility Inspector on all main views
- [ ] Document current accessibility state
- [ ] Identify all interactive elements without labels
- [ ] List all custom controls needing accessibility support
- [ ] Test current app with VoiceOver enabled
- [ ] Document color contrast issues
- [ ] Check Dynamic Type behavior
- [ ] List keyboard navigation issues

**Status:** ⏳ Not Started  
**Assigned To:** Pending  
**Estimated Time:** 2-3 hours

---

## 🎨 Phase 1: Foundation - Core Accessibility Infrastructure

### 1.1 Create Accessibility Helper Files
- [ ] Create `AccessibilityIdentifiers.swift` - Centralized IDs
- [ ] Create `AccessibilityHelpers.swift` - Reusable modifiers
- [ ] Create `HapticManager.swift` - Haptic feedback system
- [ ] Create `AccessibilityAnnouncement.swift` - Screen reader announcements

**Status:** ⏳ Not Started  
**Files to Create:** 4 new files  
**Estimated Time:** 1-2 hours

---

### 1.2 Set Up Testing Infrastructure
- [ ] Add accessibility test helpers to preview environment
- [ ] Create accessibility-focused SwiftUI previews
- [ ] Document testing procedure for each view
- [ ] Set up VoiceOver testing checklist

**Status:** ⏳ Not Started  
**Estimated Time:** 1 hour

---

## 🏗️ Phase 2: VoiceOver Support - Critical Views

### 2.1 Authentication Views
**Priority:** HIGH - First user interaction

#### LoginView / SignUpView
- [ ] Add labels to email text field
- [ ] Add labels to password text field
- [ ] Add labels to sign-in button
- [ ] Add labels to social sign-in buttons
- [ ] Add hints for complex actions
- [ ] Group related form elements
- [ ] Test complete login flow with VoiceOver

**Status:** ⏳ Not Started  
**Estimated Time:** 1 hour

---

### 2.2 Dashboard View
**Priority:** HIGH - Main entry point

#### DashboardView.swift
- [ ] Add label to greeting header
- [ ] Add labels to week selector buttons
- [ ] Add labels to quick action buttons (Log Meal, Log Symptom)
- [ ] Add labels to activity cards
- [ ] Add labels to health score indicators
- [ ] Group dashboard insights section
- [ ] Add hints for interactive cards
- [ ] Test navigation with VoiceOver

**Status:** ⏳ Not Started  
**Estimated Time:** 2 hours

---

### 2.3 Meal Builder View
**Priority:** CRITICAL - Core functionality

#### MealBuilderView.swift
- [ ] Add label to meal name text field
- [ ] Add label to meal type picker
- [ ] Add label to date/time picker button
- [ ] Add labels to "Add Food Item" button
- [ ] Add labels to food item rows
- [ ] Add labels to delete buttons
- [ ] Add labels to nutrition summary cards
- [ ] Add label to notes text editor
- [ ] Add label to save button
- [ ] Add label to cancel button
- [ ] Group related food items
- [ ] Add hints for swipe actions
- [ ] Test complete meal creation with VoiceOver

**Status:** ⏳ Not Started  
**Estimated Time:** 2-3 hours

---

### 2.4 Food Search View
**Priority:** CRITICAL - Core functionality

#### FoodSearchView.swift / FoodSearchViewModel.swift
- [ ] Add label to search text field
- [ ] Add label to search button
- [ ] Add labels to category buttons
- [ ] Add labels to recent searches
- [ ] Add labels to search result rows
- [ ] Add labels to food detail buttons
- [ ] Add hints for selecting food items
- [ ] Group search results logically
- [ ] Test search flow with VoiceOver

**Status:** ⏳ Not Started  
**Estimated Time:** 2 hours

---

### 2.5 Symptom Logging View
**Priority:** CRITICAL - Core functionality

#### LogSymptomView.swift
- [ ] Add labels to Bristol Scale type buttons
- [ ] Add hints for Bristol Scale types
- [ ] Add label to pain level slider
- [ ] Add value announcements for slider
- [ ] Add label to urgency level picker
- [ ] Add label to bloating toggle/slider
- [ ] Add label to notes field
- [ ] Add label to date/time picker
- [ ] Add label to save button
- [ ] Group Bristol Scale as single control (if appropriate)
- [ ] Test symptom logging with VoiceOver

**Status:** ⏳ Not Started  
**Estimated Time:** 2-3 hours

---

### 2.6 Calendar View
**Priority:** HIGH

#### CalendarView.swift
- [ ] Add labels to week selector
- [ ] Add labels to date navigation buttons
- [ ] Add labels to meal/symptom toggle
- [ ] Add labels to list items
- [ ] Add labels to floating action button
- [ ] Add labels to filter buttons
- [ ] Group calendar entries by date
- [ ] Test navigation with VoiceOver

**Status:** ⏳ Not Started  
**Estimated Time:** 2 hours

---

### 2.7 Settings View
**Priority:** MEDIUM

#### SettingsView.swift
- [ ] Add labels to all NavigationLinks
- [ ] Add hints for navigation destinations
- [ ] Add labels to toggle switches
- [ ] Add labels to pickers
- [ ] Group related settings
- [ ] Test settings navigation with VoiceOver

**Status:** ⏳ Not Started  
**Estimated Time:** 1 hour

---

### 2.8 Insights View
**Priority:** MEDIUM

#### InsightsView.swift
- [ ] Add labels to chart elements
- [ ] Add labels to insight cards
- [ ] Add labels to filter buttons
- [ ] Add labels to time range selector
- [ ] Make charts accessible with summaries
- [ ] Test insights with VoiceOver

**Status:** ⏳ Not Started  
**Estimated Time:** 2 hours

---

### 2.9 Tab Bar Navigation
**Priority:** HIGH

#### CustomTabBar.swift / AppRoot.swift
- [ ] Add labels to all tab items
- [ ] Add hints describing tab content
- [ ] Test tab switching with VoiceOver
- [ ] Ensure selected state is announced

**Status:** ⏳ Not Started  
**Estimated Time:** 30 minutes

---

## 🎯 Phase 3: Dynamic Type Support

### 3.1 Create Typography System
- [ ] Create `Typography.swift` with @ScaledMetric support
- [ ] Define standard text styles with scaling
- [ ] Document font size guidelines

**Status:** ⏳ Not Started  
**Estimated Time:** 1 hour

---

### 3.2 Update Critical Views for Dynamic Type
**Priority:** HIGH - Update views that users interact with most

#### Views to Update:
- [ ] DashboardView
- [ ] MealBuilderView
- [ ] LogSymptomView
- [ ] FoodSearchView
- [ ] CalendarView (list items)

#### For Each View:
- [ ] Replace fixed `.font()` with `@ScaledMetric`
- [ ] Test with largest accessibility size
- [ ] Fix any layout issues
- [ ] Ensure buttons don't overlap
- [ ] Ensure text doesn't truncate inappropriately

**Status:** ⏳ Not Started  
**Estimated Time:** 4-6 hours

---

### 3.3 Set Dynamic Type Limits (if needed)
- [ ] Test app at XXXL size
- [ ] Identify any breaking layouts
- [ ] Apply `.dynamicTypeSize()` limits where necessary
- [ ] Document why limits are needed

**Status:** ⏳ Not Started  
**Estimated Time:** 1-2 hours

---

## 🎨 Phase 4: Color Contrast Audit

### 4.1 Run Contrast Analysis
- [ ] Use Accessibility Inspector to check all text
- [ ] Document contrast ratios below 4.5:1
- [ ] Check Bristol Scale colors
- [ ] Check pain level colors
- [ ] Check health score colors
- [ ] Check button states (normal, disabled, pressed)
- [ ] Check error messages

**Status:** ⏳ Not Started  
**Tools:** Xcode Accessibility Inspector  
**Estimated Time:** 2 hours

---

### 4.2 Fix Contrast Issues
- [ ] Update ColorTheme for better contrast
- [ ] Adjust Bristol Scale colors if needed
- [ ] Adjust pain level colors if needed
- [ ] Ensure all text meets 4.5:1 minimum
- [ ] Re-test with Accessibility Inspector

**Status:** ⏳ Not Started  
**Estimated Time:** 2-4 hours (depends on findings)

---

## 📱 Phase 5: Haptic Feedback

### 5.1 Create Haptic System
- [ ] Create `HapticManager.swift`
- [ ] Implement impact feedback methods
- [ ] Implement notification feedback methods
- [ ] Implement selection feedback methods
- [ ] Add accessibility setting check (respect Reduce Motion)

**Status:** ⏳ Not Started  
**Estimated Time:** 1 hour

---

### 5.2 Add Haptics to Critical Actions
- [ ] Tab bar selections → `.selection()`
- [ ] Bristol Scale selection → `.selection()`
- [ ] Pain level slider → `.selection()` on value change
- [ ] Food item added → `.notification(.success)`
- [ ] Meal saved → `.notification(.success)`
- [ ] Symptom saved → `.notification(.success)`
- [ ] Item deleted → `.notification(.warning)`
- [ ] Error occurred → `.notification(.error)`
- [ ] Button presses → `.impact(.light)`
- [ ] Toggle switches → `.impact(.light)`

**Status:** ⏳ Not Started  
**Estimated Time:** 2-3 hours

---

## ⌨️ Phase 6: Keyboard Navigation

### 6.1 Add Keyboard Toolbars
- [ ] Add Done button to number pads
- [ ] Add Done button to text fields
- [ ] Add Next/Previous navigation where appropriate
- [ ] Test tab order in forms

**Status:** ⏳ Not Started  
**Estimated Time:** 2 hours

---

### 6.2 Test Keyboard Navigation
- [ ] Test meal creation with external keyboard
- [ ] Test symptom logging with external keyboard
- [ ] Test search with external keyboard
- [ ] Verify all actions accessible via keyboard

**Status:** ⏳ Not Started  
**Estimated Time:** 1 hour

---

## ♿ Phase 7: Additional Accessibility Features

### 7.1 Reduce Motion Support
- [ ] Check for `UIAccessibility.isReduceMotionEnabled`
- [ ] Disable/simplify animations when enabled
- [ ] Test all transitions with Reduce Motion on

**Status:** ⏳ Not Started  
**Estimated Time:** 2 hours

---

### 7.2 Accessibility Traits
- [ ] Add `.accessibilityAddTraits(.isButton)` to custom buttons
- [ ] Add `.accessibilityAddTraits(.isHeader)` to section headers
- [ ] Add `.accessibilityAddTraits(.updatesFrequently)` to live data
- [ ] Add `.accessibilityRemoveTraits(.isImage)` where appropriate

**Status:** ⏳ Not Started  
**Estimated Time:** 1 hour

---

### 7.3 Custom Actions
- [ ] Add swipe actions as accessibility custom actions
- [ ] Add long-press actions as accessibility custom actions
- [ ] Test custom actions with VoiceOver

**Status:** ⏳ Not Started  
**Estimated Time:** 2 hours

---

## 🧪 Phase 8: Testing & Validation

### 8.1 VoiceOver Testing (Complete Flows)
- [ ] Test: Sign up → Dashboard → Log Meal → Save
- [ ] Test: Dashboard → Log Symptom → Save
- [ ] Test: Search Food → Add to Meal → Save
- [ ] Test: View Calendar → Navigate to Detail
- [ ] Test: View Insights → Navigate to Details
- [ ] Test: Settings → Change Preferences → Save
- [ ] Test: Error scenarios with VoiceOver
- [ ] Test: Empty states with VoiceOver

**Status:** ⏳ Not Started  
**Estimated Time:** 3-4 hours

---

### 8.2 Dynamic Type Testing
- [ ] Test all views at default size
- [ ] Test all views at XL size
- [ ] Test all views at XXXL size
- [ ] Verify no text truncation
- [ ] Verify no button overlap
- [ ] Document any layout issues

**Status:** ⏳ Not Started  
**Estimated Time:** 2 hours

---

### 8.3 Color Contrast Validation
- [ ] Re-run Accessibility Inspector
- [ ] Verify all text passes 4.5:1
- [ ] Verify large text passes 3:1
- [ ] Take screenshots for documentation

**Status:** ⏳ Not Started  
**Estimated Time:** 1 hour

---

### 8.4 Haptic Testing
- [ ] Test all haptics on physical device
- [ ] Verify haptics respect Reduce Motion
- [ ] Verify haptic intensity is appropriate
- [ ] Test battery impact

**Status:** ⏳ Not Started  
**Estimated Time:** 1 hour

---

### 8.5 Keyboard Navigation Testing
- [ ] Test with external keyboard
- [ ] Test with on-screen keyboard
- [ ] Verify Done button works
- [ ] Verify tab order is logical

**Status:** ⏳ Not Started  
**Estimated Time:** 1 hour

---

## 📚 Phase 9: Documentation

### 9.1 Create Accessibility Documentation
- [ ] Document all accessibility features
- [ ] Create user guide for VoiceOver users
- [ ] Document keyboard shortcuts
- [ ] Create testing guide for developers
- [ ] Document accessibility IDs for automated testing

**Status:** ⏳ Not Started  
**Estimated Time:** 2-3 hours

---

### 9.2 Update App Store Description
- [ ] Add accessibility features to description
- [ ] Add VoiceOver support mention
- [ ] Add Dynamic Type support mention
- [ ] Add keyboard navigation mention

**Status:** ⏳ Not Started  
**Estimated Time:** 30 minutes

---

## ✅ Phase 10: Final Validation

### 10.1 Comprehensive Test Pass
- [ ] Test entire app with VoiceOver only (eyes closed)
- [ ] Test entire app at XXXL text size
- [ ] Test with Reduce Motion enabled
- [ ] Test with Bold Text enabled
- [ ] Test with Increase Contrast enabled
- [ ] Test on physical device (not just simulator)

**Status:** ⏳ Not Started  
**Estimated Time:** 4-5 hours

---

### 10.2 Accessibility Checklist Completion
- [ ] All interactive elements have labels
- [ ] All images have alt text (or marked decorative)
- [ ] All form fields have labels
- [ ] All error messages are accessible
- [ ] Color is not the only means of conveying information
- [ ] Focus order is logical
- [ ] All functionality available via keyboard
- [ ] Text contrast meets WCAG AA standards
- [ ] App supports Dynamic Type
- [ ] VoiceOver can complete all user flows
- [ ] Haptic feedback is appropriate
- [ ] Custom controls are accessible

**Status:** ⏳ Not Started  
**Estimated Time:** 1 hour review

---

## 📊 Progress Tracking

### Overall Progress
- **Total Tasks:** 120+ individual tasks
- **Completed:** 0
- **In Progress:** 0
- **Not Started:** 120+
- **Blocked:** 0

### Phase Completion
- [ ] Phase 0: Discovery & Assessment (0%)
- [ ] Phase 1: Foundation (0%)
- [ ] Phase 2: VoiceOver Support (0%)
- [ ] Phase 3: Dynamic Type (0%)
- [ ] Phase 4: Color Contrast (0%)
- [ ] Phase 5: Haptic Feedback (0%)
- [ ] Phase 6: Keyboard Navigation (0%)
- [ ] Phase 7: Additional Features (0%)
- [ ] Phase 8: Testing & Validation (0%)
- [ ] Phase 9: Documentation (0%)
- [ ] Phase 10: Final Validation (0%)

---

## ⏱️ Time Estimation Summary

| Phase | Estimated Time | Actual Time | Status |
|-------|----------------|-------------|--------|
| Phase 0: Discovery | 2-3 hours | - | ⏳ Not Started |
| Phase 1: Foundation | 2-3 hours | - | ⏳ Not Started |
| Phase 2: VoiceOver | 15-18 hours | - | ⏳ Not Started |
| Phase 3: Dynamic Type | 6-9 hours | - | ⏳ Not Started |
| Phase 4: Color Contrast | 4-6 hours | - | ⏳ Not Started |
| Phase 5: Haptic Feedback | 3-4 hours | - | ⏳ Not Started |
| Phase 6: Keyboard Navigation | 3 hours | - | ⏳ Not Started |
| Phase 7: Additional Features | 5 hours | - | ⏳ Not Started |
| Phase 8: Testing | 11-12 hours | - | ⏳ Not Started |
| Phase 9: Documentation | 2.5-3.5 hours | - | ⏳ Not Started |
| Phase 10: Final Validation | 5-6 hours | - | ⏳ Not Started |
| **TOTAL** | **58-73 hours** | **-** | **⏳ Not Started** |

**Estimated Calendar Time:** 7-9 business days (assuming 8 hours/day)

---

## 🎯 Next Steps

### Immediate Actions (Today):
1. **Run Accessibility Inspector** on main views
2. **Test with VoiceOver** to understand current state
3. **Create foundation files** (HapticManager, AccessibilityHelpers)

### Tomorrow:
4. **Begin Phase 2** - Start with authentication and dashboard
5. **Create Typography system** for Dynamic Type

### This Week:
6. **Complete Phases 1-3** (Foundation, VoiceOver, Dynamic Type)
7. **Begin Phase 4** (Color Contrast Audit)

---

## 📝 Notes & Observations

### Issues Discovered:
_(Will be populated during implementation)_

### Decisions Made:
_(Will document any architectural decisions)_

### Open Questions:
_(Any unclear requirements or implementation questions)_

---

## 🏆 Success Criteria

This accessibility implementation will be considered complete when:

1. ✅ All user flows can be completed using VoiceOver only
2. ✅ App functions correctly at all Dynamic Type sizes
3. ✅ All text meets WCAG AA contrast requirements (4.5:1 minimum)
4. ✅ All interactive elements have appropriate labels and traits
5. ✅ Haptic feedback is implemented for key actions
6. ✅ Keyboard navigation works for all forms
7. ✅ App passes Accessibility Inspector with 0 errors
8. ✅ Real users with disabilities can successfully use the app

---

**Last Updated:** February 23, 2026  
**Status:** Ready to Begin Implementation  
**Next Review:** After Phase 1 Completion


---

# Apple Design Standards Review - GutCheck App
**Review Date:** February 23, 2026  
**Platform:** iOS/iPadOS  
**Reviewer:** Design Standards Audit

---

## 📊 Executive Summary

### Overall Compliance Score: 7.5/10

**Strengths:**
- ✅ Modern SwiftUI architecture
- ✅ Good use of SF Symbols
- ✅ Tab-based navigation (HIG compliant)
- ✅ Consistent color theming system
- ✅ Professional medical UI design

**Areas for Improvement:**
- ⚠️ Limited accessibility support
- ⚠️ No Dynamic Type support
- ⚠️ Missing haptic feedback
- ⚠️ Inconsistent spacing standards
- ⚠️ No dark mode optimization

---

## 1. ✅ WHAT YOU'RE DOING RIGHT

### 1.1 Navigation Architecture ✅ COMPLIANT
**Status:** Excellent

**Evidence:**
```swift
// AppRoot.swift - Proper TabView + NavigationStack pattern
TabView {
    NavigationStack(path: $router.path) {
        DashboardView()
            .navigationDestination(for: AppDestination.self) { destination in
                // Proper type-safe navigation
            }
    }
    .tabItem {
        Label("Dashboard", systemImage: "house.fill")
    }
}
```

**✅ What's Good:**
- Using modern `NavigationStack` (iOS 16+)
- Type-safe navigation with `AppRouter` pattern
- Proper tab bar implementation with SF Symbols
- Sheet presentations for modal views
- Deep linking support ready

**Apple HIG Reference:** ✅ Complies with "Navigation" guidelines

---

### 1.2 SF Symbols Usage ✅ EXCELLENT
**Status:** Best Practice

**Evidence:**
- `house.fill` for Dashboard
- `fork.knife` for Meals
- `heart.text.square.fill` for Symptoms
- `chart.bar.fill` for Insights
- `calendar`, `plus.circle.fill`, etc.

**✅ What's Good:**
- Consistent use of system icons
- Proper semantic naming
- No custom icons where SF Symbols exist

**Recommendation:** Keep using SF Symbols - you're doing this perfectly!

---

### 1.3 Color Theme System ✅ GOOD
**Status:** Good structure, needs enhancement

**Evidence:**
```swift
// ColorTheme usage throughout
.background(ColorTheme.surface)
.foregroundColor(ColorTheme.primaryText)
```

**✅ What's Good:**
- Centralized color management
- Semantic color naming (`primary`, `surface`, `cardBackground`)
- Consistent application across views

**⚠️ Needs Improvement:**
- Add dark mode support
- Use system color adaptivity
- Add semantic color roles (iOS 15+)

---

### 1.4 List and Form Patterns ✅ COMPLIANT
**Status:** Good

**Evidence:**
```swift
// SettingsView.swift
List {
    Section("Preferences") {
        NavigationLink(destination: LanguageSelectionView()) { ... }
    }
    Section("Privacy & Security") { ... }
}
.listStyle(.insetGrouped)
```

**✅ What's Good:**
- Proper use of `List` and `Section`
- Grouped list style for settings
- Consistent section headers
- Proper NavigationLink usage

---

### 1.5 Medical UI Design ✅ EXCELLENT
**Status:** Professional

**Evidence:**
```swift
// LogSymptomView.swift - Bristol Scale
LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
    ForEach(bristolInfo, id: \.type) { info in
        // Medical-grade UI design
    }
}
```

**✅ What's Good:**
- Professional Bristol Stool Scale implementation
- Clear pain level indicators
- Color-coded health scores
- Medical terminology with descriptions
- HIPAA-conscious design

---

## 2. ⚠️ AREAS NEEDING IMPROVEMENT

### 2.1 Accessibility ⚠️ NEEDS WORK
**Status:** Limited support
**Priority:** HIGH

#### Missing Features:

#### 2.1.1 VoiceOver Labels
**Current State:** Minimal accessibility labels

**Issues Found:**
```swift
// LogSymptomView.swift - Good example
.accessibilityLabel("Type \(info.type.rawValue): \(info.summary)")

// But many views lack this
Button(action: { ... }) {
    Image(systemName: "plus.circle.fill")
    // ❌ No accessibility label
}
```

**📋 OPTION 1A:** Add VoiceOver Support (Comprehensive)
- Add `.accessibilityLabel()` to all interactive elements
- Add `.accessibilityHint()` for complex actions
- Group related elements with `.accessibilityElement(children: .combine)`
- Test with VoiceOver enabled

**📋 OPTION 1B:** Add VoiceOver Support (Minimal)
- Focus only on critical paths (meal/symptom logging)
- Add labels to buttons without text
- Add hints to complex interactions

**Effort:** 
- Option 1A: 2-3 days
- Option 1B: 1 day

---

#### 2.1.2 Dynamic Type Support
**Current State:** ❌ NOT IMPLEMENTED

**Issue:**
```swift
// Currently using fixed font sizes
.font(.title2)
.font(.caption)

// No @ScaledMetric or relative sizing
```

**📋 OPTION 2A:** Full Dynamic Type Support
```swift
// Add to all text elements
@ScaledMetric(relativeTo: .body) var fontSize: CGFloat = 17

Text("Hello")
    .font(.system(size: fontSize))
```

**📋 OPTION 2B:** Minimum Viable Dynamic Type
- Support Accessibility Large Text for critical views:
  - Dashboard
  - Meal Builder
  - Symptom Logger
- Use `.dynamicTypeSize(.large ... .xxxLarge)` limits

**Effort:**
- Option 2A: 3-4 days (all views)
- Option 2B: 1-2 days (critical views)

**Apple HIG:** This is a requirement for App Store approval if users report issues

---

#### 2.1.3 Color Contrast
**Current State:** Needs verification

**📋 OPTION 3:** Run Accessibility Inspector
```bash
# In Xcode
Xcode → Open Developer Tool → Accessibility Inspector
# Check color contrast ratios (minimum 4.5:1)
```

**Action Items:**
- Audit all text on colored backgrounds
- Verify Bristol Scale readability
- Test pain level colors
- Check button states

**Effort:** 1-2 hours + fixes

---

### 2.2 Haptic Feedback ⚠️ MISSING
**Status:** Not implemented
**Priority:** MEDIUM

**Current State:**
```swift
// No haptic feedback found in:
Button(action: {
    // ❌ No haptic
    mealService.removeFoodItem(item)
}) { ... }
```

**📋 OPTION 4A:** Comprehensive Haptic System
```swift
// Create HapticManager.swift
class HapticManager {
    static let shared = HapticManager()
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// Usage:
Button(action: {
    HapticManager.shared.impact(.medium)
    mealService.removeFoodItem(item)
}) { ... }
```

**Add haptics to:**
- ✓ Tab bar selections (.light)
- ✓ Food item additions (.medium)
- ✓ Meal saving (.success notification)
- ✓ Deletion actions (.warning notification)
- ✓ Bristol scale selection (.selection)
- ✓ Slider adjustments (.light)

**📋 OPTION 4B:** Critical Actions Only
- Add haptics to:
  - Save meal/symptom (success)
  - Delete operations (warning)
  - Error states (error)

**Effort:**
- Option 4A: 1 day
- Option 4B: 2-3 hours

---

### 2.3 Spacing and Layout ⚠️ INCONSISTENT
**Status:** Needs standardization
**Priority:** MEDIUM

**Issues Found:**
```swift
// Inconsistent spacing values
.padding()          // Default 16
.padding(20)        // Custom 20
.padding(.vertical) // Default vertical
.padding(.top)      // Single edge
```

**📋 OPTION 5:** Create Spacing System
```swift
// Add to ColorTheme or new LayoutConstants.swift
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let pill: CGFloat = 999
}

// Usage:
.padding(.horizontal, Spacing.md)
.cornerRadius(CornerRadius.md)
```

**Benefit:** Consistent spacing across all views

**Effort:** 2-3 hours + gradual migration

---

### 2.4 Dark Mode ⚠️ LIMITED SUPPORT
**Status:** May not work properly
**Priority:** HIGH (App Store requirement)

**Current State:**
```swift
// GutCheckApp.swift
.preferredColorScheme(.light) // ❌ Forces light mode
```

**Issue:** App is locked to light mode, violating user preference

**📋 OPTION 6A:** Remove Light Mode Lock
```swift
// Simply remove this line:
// .preferredColorScheme(.light)

// Then test all views in dark mode
```

**📋 OPTION 6B:** Full Dark Mode Support
1. Remove `.preferredColorScheme(.light)`
2. Update ColorTheme to support both modes:
```swift
extension Color {
    static var adaptiveBackground: Color {
        Color(UIColor.systemBackground)
    }
    
    static var adaptiveText: Color {
        Color(UIColor.label)
    }
}
```
3. Test all views in both modes
4. Fix any contrast issues

**Effort:**
- Option 6A: 10 minutes + testing
- Option 6B: 1-2 days

**Apple HIG:** Dark mode support is expected (not required, but strongly recommended)

---

### 2.5 Animation and Transitions ⚠️ BASIC
**Status:** Minimal animations
**Priority:** LOW-MEDIUM

**Current State:**
```swift
// Mostly using default animations
Button(action: { ... }) { ... }
// No explicit animation
```

**📋 OPTION 7A:** Add Polish Animations
```swift
// Button press animations
Button(action: action) {
    content
}
.buttonStyle(ScaleButtonStyle())

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

// Sheet presentations with transitions
.sheet(...) {
    content
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}

// List animations
ForEach(items) { item in
    row
}
.animation(.default, value: items)
```

**📋 OPTION 7B:** Minimal Polish
- Add scale effect to primary buttons
- Add slide transitions to sheets
- Add subtle fade on appearance

**Effort:**
- Option 7A: 2-3 days
- Option 7B: 4-6 hours

---

### 2.6 Pull-to-Refresh ⚠️ UNCLEAR
**Status:** Needs verification
**Priority:** MEDIUM

**Expected:**
```swift
List {
    // content
}
.refreshable {
    await viewModel.refresh()
}
```

**📋 OPTION 8:** Add Pull-to-Refresh
Add to:
- DashboardView
- CalendarView (Meals/Symptoms lists)
- InsightsView

**Effort:** 2-3 hours

---

### 2.7 Empty States ✅ GOOD (with minor issues)
**Status:** Mostly good

**Found:**
```swift
// MealBuilderView.swift
if mealService.currentMeal.isEmpty {
    emptyStateView
}
```

**✅ Good:** You have empty states

**⚠️ Minor Issue:** Verify all lists have empty states:
- [ ] Meals list
- [ ] Symptoms list
- [ ] Insights list
- [ ] Search results

**📋 OPTION 9:** Audit Empty States
Check each list for:
- Descriptive message
- Helpful icon
- Action button (if applicable)

**Effort:** 1-2 hours

---

### 2.8 Loading States ⚠️ NEEDS REVIEW
**Status:** Partial implementation

**Found:**
```swift
// LoadingState pattern exists
@Published var isLoading = false
```

**📋 OPTION 10:** Standardize Loading UI
```swift
// Create LoadingView.swift
struct LoadingView: View {
    var message: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text(message)
                .foregroundColor(.secondary)
        }
    }
}

// Usage:
if viewModel.isLoading {
    LoadingView(message: "Loading meals...")
} else {
    // content
}
```

**Effort:** 3-4 hours

---

### 2.9 Error Handling UI ⚠️ NEEDS IMPROVEMENT
**Status:** Minimal error UI
**Priority:** MEDIUM

**📋 OPTION 11A:** Inline Error Messages
```swift
if let error = viewModel.errorMessage {
    Text(error)
        .foregroundColor(.red)
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
}
```

**📋 OPTION 11B:** Alert-Based Errors
```swift
.alert("Error", isPresented: $showError) {
    Button("OK", role: .cancel) { }
    Button("Retry") { viewModel.retry() }
} message: {
    Text(errorMessage)
}
```

**📋 OPTION 11C:** Toast Notifications
Create a toast system for non-critical errors

**Effort:**
- Option 11A: 2-3 hours
- Option 11B: 1-2 hours
- Option 11C: 1 day

---

### 2.10 Keyboard Handling ⚠️ UNCLEAR
**Status:** Needs verification
**Priority:** MEDIUM

**Issues to Check:**
- Does keyboard obscure text fields?
- Can users dismiss keyboard?
- Is "Done" button on number pads?

**📋 OPTION 12:** Add Keyboard Toolbar
```swift
TextField("Meal name", text: $name)
    .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                hideKeyboard()
            }
        }
    }

// Helper
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}
```

**Effort:** 2-3 hours

---

## 3. 🎨 DESIGN PATTERN COMPLIANCE

### 3.1 Human Interface Guidelines Compliance

| Category | Status | Score |
|----------|--------|-------|
| Navigation | ✅ Excellent | 10/10 |
| Visual Design | ✅ Good | 8/10 |
| Layout | ⚠️ Needs Work | 6/10 |
| Typography | ⚠️ Limited | 6/10 |
| Color | ✅ Good | 7/10 |
| Icons | ✅ Excellent | 10/10 |
| Controls | ✅ Good | 8/10 |
| Accessibility | ⚠️ Minimal | 3/10 |
| Feedback | ⚠️ Missing | 2/10 |
| Animation | ⚠️ Basic | 4/10 |

---

### 3.2 iOS-Specific Features

| Feature | Status | Implementation |
|---------|--------|----------------|
| NavigationStack | ✅ Yes | Modern iOS 16+ |
| SF Symbols | ✅ Yes | Extensive use |
| SwiftUI | ✅ Yes | Pure SwiftUI |
| Dark Mode | ❌ Disabled | Locked to light |
| Dynamic Type | ❌ No | Fixed fonts |
| VoiceOver | ⚠️ Partial | Some labels |
| Haptics | ❌ No | Not implemented |
| Widgets | ❌ No | Not implemented |
| Live Activities | ❌ No | Not implemented |
| Shortcuts | ❌ No | Not implemented |
| Handoff | ❌ No | Not implemented |

---

## 4. 📱 PLATFORM-SPECIFIC CONSIDERATIONS

### 4.1 iPad Support ⚠️ NEEDS VERIFICATION
**Status:** Unknown

**Questions:**
- Does the app work on iPad?
- Is there a split view layout?
- Are tap targets sized correctly for iPad?

**📋 OPTION 13:** iPad Optimization
```swift
// Adaptive layouts
HStack {
    if horizontalSizeClass == .regular {
        // iPad layout
        Sidebar()
        Detail()
    } else {
        // iPhone layout
        NavigationStack { ... }
    }
}
```

**Effort:** 3-5 days for full iPad support

---

### 4.2 iPhone SE Support ⚠️ NEEDS TESTING
**Status:** Unknown

**Action:** Test on smallest screen (iPhone SE 3rd gen - 4.7")

**Common Issues:**
- Text truncation
- Button overlap
- Keyboard obscuring fields

**📋 OPTION 14:** Test on Small Screens
Use Xcode simulators to verify all views

**Effort:** 1 day testing + fixes

---

### 4.3 iOS Version Support
**Current:** iOS 16+ (NavigationStack requires it)

**✅ Good:** Using modern APIs
**⚠️ Note:** 16+ limits your potential audience (~85% of devices as of Feb 2026)

---

## 5. 🎯 RECOMMENDED PRIORITY ORDER

### CRITICAL (Do First)
1. **Remove Light Mode Lock** (Option 6A) - 10 minutes
2. **Add Dark Mode Support** (Option 6B) - 1-2 days
3. **Accessibility Audit** (Option 3) - 2 hours
4. **Dynamic Type** (Option 2B - Minimal) - 1-2 days

### HIGH PRIORITY (Do Soon)
5. **VoiceOver Labels** (Option 1B - Minimal) - 1 day
6. **Haptic Feedback** (Option 4B - Critical actions) - 3 hours
7. **Pull-to-Refresh** (Option 8) - 3 hours
8. **Error Handling UI** (Option 11B - Alerts) - 2 hours

### MEDIUM PRIORITY (Nice to Have)
9. **Spacing System** (Option 5) - 3 hours
10. **Loading States** (Option 10) - 4 hours
11. **Keyboard Handling** (Option 12) - 3 hours
12. **Empty States Audit** (Option 9) - 2 hours

### LOW PRIORITY (Polish)
13. **Animation Polish** (Option 7B - Minimal) - 6 hours
14. **iPhone SE Testing** (Option 14) - 1 day
15. **iPad Support** (Option 13) - 3-5 days

---

## 6. 📋 ESTIMATED EFFORT SUMMARY

### Week 1: Critical Fixes (3-4 days)
- Remove light mode lock
- Add dark mode support
- Run accessibility audit
- Add minimal dynamic type

### Week 2: High Priority (3-4 days)
- Add VoiceOver labels to critical paths
- Implement haptic feedback
- Add pull-to-refresh
- Improve error handling

### Week 3: Polish (3-5 days)
- Spacing system
- Loading states
- Keyboard handling
- Minor animations

**Total Effort:** 9-13 days for full compliance

---

## 7. 🔍 TESTING CHECKLIST

### Before Submitting to App Store

#### Accessibility
- [ ] Test with VoiceOver enabled
- [ ] Test with largest Dynamic Type size
- [ ] Test with Bold Text enabled
- [ ] Test with Reduce Motion enabled
- [ ] Run Accessibility Inspector
- [ ] Verify color contrast ratios

#### Device Testing
- [ ] iPhone SE (smallest screen)
- [ ] iPhone 15 Pro (standard)
- [ ] iPhone 15 Pro Max (largest)
- [ ] iPad (if supported)
- [ ] Test in portrait and landscape

#### System Features
- [ ] Dark mode works
- [ ] Light mode works
- [ ] System colors adapt
- [ ] Haptics work
- [ ] Keyboard dismisses properly
- [ ] Pull-to-refresh works

#### Edge Cases
- [ ] Empty states display correctly
- [ ] Loading states show properly
- [ ] Errors display helpfully
- [ ] Offline mode works
- [ ] Network errors handled

---

## 8. 💡 ADDITIONAL RECOMMENDATIONS

### Consider Adding:
1. **Widgets** - Show today's meals/symptoms at a glance
2. **Shortcuts Support** - "Log a meal" Siri shortcut
3. **Live Activities** - Meal tracking timer
4. **App Clips** - Quick meal logging without full app
5. **HealthKit Integration** - Export to Apple Health
6. **Focus Filters** - Meal reminder scheduling

---

## 9. ✅ FINAL RECOMMENDATIONS

### Option A: Minimum Viable Compliance (1-2 weeks)
**Focus on App Store approval requirements:**
1. Remove light mode lock
2. Add basic dark mode support
3. Add VoiceOver labels to critical flows
4. Fix any accessibility audit issues
5. Add haptic feedback to key actions

**Effort:** 5-7 days  
**Result:** Meets minimum HIG requirements

---

### Option B: Good User Experience (2-3 weeks)
**Everything in Option A, plus:**
6. Full dynamic type support
7. Comprehensive haptic system
8. Pull-to-refresh everywhere
9. Polished animations
10. Standardized spacing

**Effort:** 10-15 days  
**Result:** Good, polished iOS app

---

### Option C: Exceptional App (4-6 weeks)
**Everything in Option B, plus:**
11. Full iPad support
12. Widgets
13. Shortcuts integration
14. Advanced accessibility
15. Platform-specific optimizations

**Effort:** 20-30 days  
**Result:** Apple Design Award quality

---

## 10. 🎓 RESOURCES

### Apple Documentation
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Accessibility Programming Guide](https://developer.apple.com/accessibility/)
- [iOS Design Themes](https://developer.apple.com/design/human-interface-guidelines/ios/overview/themes/)

### Testing Tools
- Accessibility Inspector (Xcode → Open Developer Tool)
- Simulator Dark Mode toggle
- VoiceOver (iOS Settings → Accessibility)

### WCAG Guidelines
- [Web Content Accessibility Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- Minimum contrast ratio: 4.5:1 for normal text

---

## ✅ SUMMARY

**Your app has a solid foundation with good navigation, proper use of system components, and a professional medical UI. The main areas to address are:**

1. ⚠️ **Accessibility** - Critical for App Store
2. ⚠️ **Dark Mode** - Currently disabled
3. ⚠️ **Haptic Feedback** - Missing entirely
4. ⚠️ **Dynamic Type** - Not supported

**Recommended Path:** Start with **Option A** (Minimum Viable Compliance) to ensure App Store approval, then progressively enhance toward Option B for a great user experience.

Would you like me to implement any of these options?
