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
