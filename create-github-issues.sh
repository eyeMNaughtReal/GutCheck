#!/usr/bin/env bash
# =============================================================================
# GutCheck — Apple Ecosystem Enhancement: GitHub Issue Creator
#
# Usage:
#   export GITHUB_TOKEN=ghp_yourTokenHere
#   bash create-github-issues.sh
#
# Requirements: curl, jq
# =============================================================================

set -euo pipefail

REPO="eyeMNaughtReal/GutCheck"
API="https://api.github.com"
TOKEN="${GITHUB_TOKEN:?Please set GITHUB_TOKEN env var}"
HEADERS=(-H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -H "Accept: application/vnd.github+json")

create_issue() {
  local title="$1"
  local body="$2"
  local labels="$3"

  local payload
  payload=$(jq -n \
    --arg title "$title" \
    --arg body "$body" \
    --argjson labels "$labels" \
    '{title: $title, body: $body, labels: $labels}')

  local response
  response=$(curl -s -X POST "${HEADERS[@]}" \
    "${API}/repos/${REPO}/issues" \
    -d "$payload")

  local number url
  number=$(echo "$response" | jq -r '.number // "error"')
  url=$(echo "$response" | jq -r '.html_url // "error"')

  if [[ "$number" == "error" ]]; then
    echo "  ERROR: $(echo "$response" | jq -r '.message // "unknown"')"
  else
    echo "  Created #$number → $url"
  fi

  echo "$number"
}

# Ensure labels exist
ensure_label() {
  local name="$1" color="$2" description="$3"
  curl -s -X POST "${HEADERS[@]}" \
    "${API}/repos/${REPO}/labels" \
    -d "{\"name\":\"$name\",\"color\":\"$color\",\"description\":\"$description\"}" \
    > /dev/null 2>&1 || true
}

echo "==> Creating labels..."
ensure_label "enhancement"      "a2eeef" "New feature or enhancement"
ensure_label "free-tier"        "0e8a16" "Available on free plan"
ensure_label "plus-tier"        "1d76db" "Plus tier (\$1.99/mo · \$19.99/yr)"
ensure_label "pro-tier"         "e4e669" "Pro tier (\$2.99/mo · \$29.99/yr)"
ensure_label "apple-ecosystem"  "f9d0c4" "Apple platform integration"
ensure_label "watchos"          "c5def5" "watchOS / Apple Watch"
ensure_label "SwiftUI"          "bfdadc" "SwiftUI work"
ensure_label "no-api-cost"      "d4c5f9" "Zero ongoing API cost"
ensure_label "monetization"     "fef2c0" "Revenue / subscription related"

echo ""
echo "==> Creating parent epics..."

# ==============================================================================
# EPIC 1 — Free Tier (no cost, ship now)
# ==============================================================================
echo ""
echo "-- EPIC: Free Tier Apple Integrations --"

EPIC_FREE=$(create_issue \
  "[Epic] Free Tier — Apple Ecosystem Integrations (Zero API Cost)" \
  "## Overview
All enhancements in this epic use native Apple frameworks with **no ongoing API cost** and belong on the free tier. They improve discoverability, accessibility, and system integration without requiring a subscription.

## Sub-issues
Items will be linked below as individual issues are created.

## Acceptance Criteria
- [ ] Sign in with Apple available as auth option
- [ ] At least one home screen widget ships
- [ ] Siri Shortcuts available for core logging actions
- [ ] Spotlight indexes meals and symptoms
- [ ] Focus Filter configurable in iOS Settings

## Tier
**Free** — these are table-stakes for a modern iOS health app and must be available to all users." \
  '["enhancement","free-tier","apple-ecosystem","no-api-cost"]')

# ==============================================================================
# EPIC 2 — Plus Tier
# ==============================================================================
echo ""
echo "-- EPIC: Plus Tier --"

EPIC_PLUS=$(create_issue \
  "[Epic] Plus Tier — Apple Ecosystem Integrations (\$1.99/mo · \$19.99/yr)" \
  "## Overview
Convenience and ecosystem depth features that cost nothing to operate at runtime (pure Apple frameworks) but represent clear premium value. These justify the Plus subscription.

## Sub-issues
Items will be linked below as individual issues are created.

## Acceptance Criteria
- [ ] Apple Watch companion app ships with complications and quick logging
- [ ] Lock screen, StandBy, and home screen widgets complete
- [ ] Live Activities track post-meal symptom window
- [ ] Dynamic Island shows compact health context
- [ ] Core Motion activity data feeds into pattern analysis
- [ ] CloudKit backup enabled
- [ ] Unlimited history unlocked

## Tier
**Plus (\$1.99/mo · \$19.99/yr)** — Apple Watch is the highest-perceived-value feature at this tier." \
  '["enhancement","plus-tier","apple-ecosystem","no-api-cost"]')

# ==============================================================================
# EPIC 3 — Pro Tier
# ==============================================================================
echo ""
echo "-- EPIC: Pro Tier --"

EPIC_PRO=$(create_issue \
  "[Epic] Pro Tier — AI & Clinical Features (\$2.99/mo · \$29.99/yr)" \
  "## Overview
AI-powered features with real compute costs and clinical-grade capabilities. Prefer on-device Apple APIs over external services to reduce per-user cost and strengthen privacy story.

## Sub-issues
Items will be linked below as individual issues are created.

## Acceptance Criteria
- [ ] On-device food photo recognition (Core ML / Vision) replaces or supplements Google Vision API
- [ ] ARKit portion estimation ships on supported devices
- [ ] NaturalLanguage symptom extraction from free-text notes
- [ ] Vision framework reads nutrition labels from photos
- [ ] Healthcare export (PDF, HIPAA-compliant) available
- [ ] CareKit provider sharing portal ships
- [ ] Advanced AI pattern analysis available

## Tier
**Pro (\$2.99/mo · \$29.99/yr)** — AI features with compute costs and deep clinical value." \
  '["enhancement","pro-tier","apple-ecosystem"]')

# ==============================================================================
# FREE TIER ISSUES
# ==============================================================================
echo ""
echo "==> Creating Free Tier issues..."

# --- Sign in with Apple ---
echo ""
echo "-- Sign in with Apple --"
create_issue \
  "Add Sign in with Apple authentication" \
  "## Context
App Store guidelines require Sign in with Apple when any third-party/social login is offered (Firebase email/phone currently exists). This is also required to clear App Store review for new submissions.

## Goal
Add Sign in with Apple as an authentication option alongside the existing Firebase email/phone auth.

## Sub-tasks
- [ ] Add \`Sign in with Apple\` capability in Xcode project settings
- [ ] Import \`AuthenticationServices\` in \`AuthService.swift\`
- [ ] Implement \`ASAuthorizationAppleIDProvider\` sign-in flow
- [ ] Handle credential state changes and revocation via \`ASAuthorizationAppleIDProvider.credentialState\`
- [ ] Link Apple ID to Firebase Auth using \`OAuthProvider\` with the identity token
- [ ] Store \`userIdentifier\` for future credential validation
- [ ] Add \"Sign in with Apple\" button (\`SignInWithAppleButton\`) to \`AuthView\`
- [ ] Handle first-time (full name available) vs returning user (name nil) flows
- [ ] Test on device (Simulator does not fully support SIWA)
- [ ] Update privacy policy to mention Apple ID data usage

## Files Likely Affected
- \`Services/Firebase/AuthService.swift\`
- \`Views/Authentication/\` (login/signup views)
- \`GutCheck.entitlements\`
- \`Info.plist\`

## Notes
- No ongoing API cost — Apple processes authentication on-device
- Required by App Store guidelines (guideline 4.8)
- Apple provides a hashed email relay, so users can hide their real email" \
  '["enhancement","free-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# --- App Intents / Siri Shortcuts ---
echo ""
echo "-- App Intents / Siri Shortcuts --"
create_issue \
  "Implement App Intents for Siri Shortcuts and Spotlight actions" \
  "## Context
App Intents (iOS 16+) allow users to trigger GutCheck actions via Siri voice commands, Shortcuts automations, and the Shortcuts app. For a health logging app, voice-first interaction is critical — users may have their hands full.

## Goal
Expose core GutCheck actions as \`AppIntent\` conforming types so users can say \"Hey Siri, log my lunch in GutCheck\" or build automation flows.

## Sub-tasks
- [ ] Add \`AppIntents\` framework to project
- [ ] Create \`LogMealIntent: AppIntent\` with meal-type parameter
- [ ] Create \`LogSymptomIntent: AppIntent\` with symptom-type and severity parameters
- [ ] Create \`GetHealthScoreIntent: AppIntent\` returning today's score
- [ ] Create \`LogWaterIntent: AppIntent\` (if water tracking exists)
- [ ] Create \`AppShortcutsProvider\` with curated phrase suggestions
- [ ] Add \`SiriTipView\` in onboarding to surface shortcut discovery
- [ ] Add \`AppIntentsPackage\` for iOS 17+ shortcut phrase suggestions
- [ ] Test intent donation after user performs actions (for Siri suggestions)
- [ ] Test with both Siri and the Shortcuts app

## Files Likely Affected
- New file: \`Intents/GutCheckIntents.swift\`
- New file: \`Intents/AppShortcuts.swift\`
- \`ViewModels/Meal/MealViewModel.swift\` (intent handlers call existing VM logic)
- \`ViewModels/Dashboard/\`

## Notes
- Zero ongoing cost — entirely on-device
- Siri phrases don't require phrases to be exact; App Intents uses NL understanding
- iOS 16 minimum for App Intents (project already targets iOS 15 — add availability guard)
- Donating interactions (\`INInteraction\`) for iOS 15 compatibility as fallback" \
  '["enhancement","free-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# --- WidgetKit ---
echo ""
echo "-- WidgetKit --"
create_issue \
  "Add WidgetKit home screen and lock screen widgets" \
  "## Context
Widgets give users glanceable health context without opening the app. For GutCheck, the daily health score, last meal, and next reminder are ideal widget content.

## Goal
Ship a WidgetKit extension with home screen and lock screen (iOS 16+) widget families.

## Sub-tasks

### Widget Extension Setup
- [ ] Add Widget Extension target to Xcode project
- [ ] Configure App Group entitlement to share data between app and widget
- [ ] Set up shared \`UserDefaults(suiteName:)\` or Core Data for widget data

### Widget Types — Free Tier
- [ ] **Daily Health Score widget** — small/medium, shows score (1–10) and trend arrow
  - Families: \`.systemSmall\`, \`.systemMedium\`
  - Lock screen: \`.accessoryCircular\` (score gauge), \`.accessoryRectangular\` (score + label)

### Widget Data & Timeline
- [ ] Create \`WidgetDataProvider\` that reads from shared App Group store
- [ ] App writes latest score, last meal, and next reminder to shared store on every update
- [ ] Widget \`TimelineProvider\` refreshes every hour or on next-meal-time event
- [ ] Handle placeholder/redacted state for privacy

### Intents for Configurable Widget
- [ ] \`WidgetConfigurationIntent\` to let user choose which metric to display

## Files Likely Affected
- New target: \`GutCheckWidgets/\`
- \`Services/\` — add App Group data write after each score calculation
- \`ViewModels/Dashboard/DashboardViewModel.swift\`

## Notes
- Lock screen widgets require iOS 16+; home screen widgets require iOS 14+
- Zero ongoing cost
- Plus tier will add additional widget types (see Plus epic)" \
  '["enhancement","free-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# --- Spotlight Search ---
echo ""
echo "-- Spotlight Search --"
create_issue \
  "Index meals and symptoms in Spotlight search" \
  "## Context
CoreSpotlight lets users find their GutCheck logs directly from the iOS Spotlight search without opening the app. A user should be able to type \"salmon dinner\" or \"bloating Tuesday\" and immediately jump to that entry.

## Goal
Index meal and symptom entries in Spotlight so they appear in system search results with a deep link back into the app.

## Sub-tasks
- [ ] Import \`CoreSpotlight\` and \`MobileCoreServices\`
- [ ] Create \`SpotlightIndexService\` that wraps \`CSSearchableIndex\`
- [ ] Define \`CSSearchableItemAttributeSet\` for Meal: title (food name), description (nutritional summary), date, thumbnail (food photo)
- [ ] Define \`CSSearchableItemAttributeSet\` for Symptom: title (symptom type), description (severity + notes), date
- [ ] Index entries on create/update; delete index entry on delete
- [ ] Handle \`application(_:continue:restorationHandler:)\` / \`onContinueUserActivity\` for deep link navigation to the specific entry
- [ ] Respect user privacy settings — only index if user has not set data to \"confidential\"
- [ ] Test search results appear within ~30 seconds of indexing

## Files Likely Affected
- New file: \`Services/SpotlightIndexService.swift\`
- \`Services/CoreData/CoreDataStorageService.swift\` (call indexer on save)
- \`Navigation/AppRouter.swift\` (handle \`NSUserActivity\` deep link)

## Notes
- Zero ongoing cost
- Spotlight indexing is done locally and privately
- Use \`CSSearchableItem.domainIdentifier\` to namespace GutCheck items" \
  '["enhancement","free-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# --- Focus Filters ---
echo ""
echo "-- Focus Filters --"
create_issue \
  "Add Focus Filter so GutCheck respects iOS Focus modes" \
  "## Context
iOS Focus Filters (iOS 16+) let apps adjust their behavior based on the user's active Focus mode. GutCheck can suppress or enable reminders based on whether the user is in \"Do Not Disturb,\" \"Sleep,\" or a custom \"Health\" Focus.

## Goal
Implement \`AppIntents\`-based Focus Filter so GutCheck appears in iOS Settings → Focus for each Focus mode.

## Sub-tasks
- [ ] Create \`GutCheckFocusFilter: SetFocusFilterIntent\`
- [ ] Define configurable parameter: \`suppressReminders: Bool\` (default false)
- [ ] In \`RemindersKitService\` / notification scheduling, check current Focus filter state before scheduling
- [ ] Register \`AppContext\` update when Focus filter changes via \`FocusFilterIntent.appContext\`
- [ ] Test that toggling \"Do Not Disturb\" suppresses/enables GutCheck notification scheduling
- [ ] Add documentation in onboarding explaining Focus mode integration

## Files Likely Affected
- New file: \`Intents/GutCheckFocusFilter.swift\`
- \`Services/RemindersKitService.swift\`
- \`Services/Notifications/\` (notification scheduling logic)

## Notes
- Zero ongoing cost — entirely on-device
- Requires iOS 16+; wrap in \`@available(iOS 16, *)\`
- Focus Filters appear automatically in iOS Settings once registered" \
  '["enhancement","free-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# --- Background Tasks ---
echo ""
echo "-- Background Tasks --"
create_issue \
  "Implement BackgroundTasks framework for pre-computed insights" \
  "## Context
Currently insights are generated when the user opens the app, causing a delay. Using \`BGProcessingTask\` (BackgroundTasks framework), GutCheck can compute pattern analysis and health scores while the device charges at night, so insights are instant on next open.

## Goal
Schedule background processing for insight generation and data sync using \`BGTaskScheduler\`.

## Sub-tasks
- [ ] Add \`Background Modes\` capability: \"Background processing\" and \"Background fetch\"
- [ ] Register background task identifiers in \`Info.plist\` under \`BGTaskSchedulerPermittedIdentifiers\`
- [ ] Create \`BGProcessingTask\` handler: \`com.gutcheck.insights-refresh\`
  - Runs \`InsightsService.generateInsights()\`
  - Runs \`PatternRecognitionService.analyzePatterns()\`
  - Stores result in shared Core Data / App Group store for instant display
- [ ] Create \`BGAppRefreshTask\` handler: \`com.gutcheck.data-sync\`
  - Runs lightweight Firebase sync check
- [ ] Schedule tasks in \`applicationDidEnterBackground\` and on task completion
- [ ] Handle task expiration gracefully (save partial progress)
- [ ] Test using Xcode background task simulation commands

## Files Likely Affected
- \`GutCheckApp.swift\` (register BGTask identifiers)
- New file: \`Services/BackgroundTaskService.swift\`
- \`Services/Insights/InsightsService.swift\`
- \`Services/CoreData/DataSyncManager.swift\`
- \`Info.plist\`

## Notes
- Zero ongoing cost
- \`BGProcessingTask\` requires device charging and connected to WiFi (configurable)
- iOS throttles background tasks — test on device, not Simulator" \
  '["enhancement","free-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# ==============================================================================
# PLUS TIER ISSUES
# ==============================================================================
echo ""
echo "==> Creating Plus Tier issues..."

# --- Apple Watch ---
echo ""
echo "-- Apple Watch --"
create_issue \
  "[Plus] Apple Watch companion app with complications and quick logging" \
  "## Context
Apple Watch is the single highest-impact feature gap in GutCheck. Users who log symptoms or meals immediately after eating benefit most from a wrist-based interface. A Watch app with complications keeps GutCheck visible throughout the day.

## Goal
Ship a watchOS companion app with quick-log UI, complications, and HealthKit-backed health context.

## Sub-tasks

### watchOS Target Setup
- [ ] Add watchOS App target to Xcode project (target: watchOS 8+)
- [ ] Configure shared App Group for iPhone ↔ Watch data transfer
- [ ] Set up \`WatchConnectivity\` (\`WCSession\`) for real-time data sync
- [ ] Enable HealthKit entitlement on Watch target

### Core Watch UI
- [ ] **Home screen**: Daily health score ring, last meal time, quick-log button
- [ ] **Quick log meal**: Crown-scrollable food picker with recent foods, meal type selector
- [ ] **Quick log symptom**: Bristol scale picker (1–7), pain level, \"log\" confirmation
- [ ] **Log confirmation**: Haptic feedback on successful log
- [ ] **History list**: Last 5 meals and symptoms in a scrollable list

### Complications
- [ ] \`.graphicCorner\` — health score gauge
- [ ] \`.graphicBezel\` — score + trend text
- [ ] \`.graphicCircular\` — score ring
- [ ] \`.graphicRectangular\` — score + last meal summary
- [ ] Update complication timeline when new data syncs from iPhone

### Notifications
- [ ] Mirror meal reminders from iPhone to Watch
- [ ] Add actionable notification buttons: \"Log Now\" → opens quick-log
- [ ] Handle Watch-only notification when iPhone is not nearby

### Data Sync
- [ ] Logs created on Watch sync to iPhone via \`WCSession.transferUserInfo\`
- [ ] iPhone pushes latest score/meal to Watch via \`WCSession.updateApplicationContext\`
- [ ] Offline queue: store Watch logs locally if iPhone unreachable, sync on reconnect

## Files Likely Affected
- New target: \`GutCheckWatch/\`
- New files: \`GutCheckWatch/Views/\`, \`GutCheckWatch/Complications/\`
- \`Services/WatchConnectivityService.swift\` (new, shared framework)
- \`ViewModels/Dashboard/DashboardViewModel.swift\` (expose data for Watch)

## Tier
**Plus (\$1.99/mo · \$19.99/yr)** — Highest perceived value feature at this tier; zero runtime API cost." \
  '["enhancement","plus-tier","apple-ecosystem","watchos","no-api-cost"]' > /dev/null

# --- Live Activities ---
echo ""
echo "-- Live Activities --"
create_issue \
  "[Plus] Live Activities and Dynamic Island for post-meal symptom tracking" \
  "## Context
After logging a meal, GutCheck could track the post-meal window (typically 2–4 hours when symptoms appear) as a Live Activity. The Dynamic Island compact view keeps this context visible without opening the app.

## Goal
Start a Live Activity when a meal is logged, showing elapsed time, a \"Log Symptoms Now\" button, and a symptom prompt at configurable intervals.

## Sub-tasks
- [ ] Add \`ActivityKit\` import and \`NSSupportsLiveActivities\` to \`Info.plist\`
- [ ] Define \`MealTrackingAttributes: ActivityAttributes\`
  - Static: meal name, meal time
  - Dynamic (\`ContentState\`): elapsed minutes, symptom-prompt-active flag, health score
- [ ] Design Live Activity layouts:
  - **Lock screen / Dynamic Island expanded**: meal icon + name, elapsed time ring, \"Log Symptoms\" button
  - **Dynamic Island compact leading**: elapsed time
  - **Dynamic Island compact trailing**: meal type icon
  - **Dynamic Island minimal**: small elapsed time dot
- [ ] Start activity when meal is saved in \`MealViewModel\`
- [ ] Update \`ContentState\` via \`Activity.update\` every 15 minutes
- [ ] End activity when user logs a symptom OR after 4 hours
- [ ] Handle \"Log Symptoms\" button action via \`AppIntent\` (deep links into symptom logging)
- [ ] Add user setting to disable Live Activities

## Files Likely Affected
- New file: \`LiveActivities/MealTrackingActivity.swift\`
- New file: \`LiveActivities/MealTrackingActivityView.swift\`
- \`ViewModels/Meal/MealViewModel.swift\` (start activity on meal save)
- \`ViewModels/Bowel/SymptomViewModel.swift\` (end activity on symptom log)

## Notes
- Zero ongoing cost — on-device only
- Requires iOS 16.1+; wrap in \`@available(iOS 16.1, *)\`
- Live Activities end automatically after 8 hours if not manually ended
- Test Dynamic Island on iPhone 14 Pro or later; test expanded view on older devices" \
  '["enhancement","plus-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# --- Extended Widgets ---
echo ""
echo "-- Extended Widgets (Plus) --"
create_issue \
  "[Plus] Extended widgets — Lock Screen, StandBy mode, and widget stack" \
  "## Context
Extending the free-tier widget set with lock screen complications, StandBy mode full-screen widgets, and additional metric widgets for Plus subscribers.

## Goal
Add Premium widget types gated behind the Plus subscription, surfacing deeper health metrics at a glance.

## Sub-tasks

### Lock Screen Widgets (iOS 16+)
- [ ] \`.accessoryInline\` — \"Score: 7.4 ↑\" single line
- [ ] \`.accessoryCircular\` — symptom count gauge for the day
- [ ] \`.accessoryRectangular\` — last meal + elapsed time

### StandBy Mode Widgets (iOS 17+)
- [ ] Full-screen StandBy layout: large health score, today's meal count, next reminder time
- [ ] Design for night-mode legibility (dark background, high contrast)
- [ ] Use \`.systemLarge\` family with StandBy-specific \`widgetURL\` deep link

### Additional Home Screen Widgets
- [ ] **Symptom trend widget** (medium) — 7-day Bristol scale trend sparkline
- [ ] **Meal log widget** (medium) — last 3 meals with icons
- [ ] **Streak widget** (small) — consecutive days logged

### Subscription Gating
- [ ] Check Plus subscription status before rendering premium widgets
- [ ] Show upgrade prompt in widget configuration if not subscribed
- [ ] Widgets update subscription status via App Group shared \`UserDefaults\`

## Files Likely Affected
- \`GutCheckWidgets/\` (existing widget extension from free-tier issue)
- New view files per widget type

## Notes
- Builds on the widget extension created in the free-tier Widget issue
- Zero ongoing cost
- StandBy requires physical device with iOS 17; not testable in Simulator" \
  '["enhancement","plus-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# --- Core Motion ---
echo ""
echo "-- Core Motion --"
create_issue \
  "[Plus] Integrate Core Motion for physical activity correlation with symptoms" \
  "## Context
Physical activity (steps, exercise minutes, sedentary time) is clinically correlated with digestive health outcomes. Core Motion provides this data on-device without HealthKit permissions.

## Goal
Collect step count and activity classification data and include it as a variable in GutCheck's pattern recognition engine.

## Sub-tasks
- [ ] Import \`CoreMotion\` and add \`CMMotionActivityManager\` / \`CMPedometer\`
- [ ] Create \`CoreMotionService\` that:
  - Queries daily step count from \`CMPedometer.queryPedometerData\`
  - Classifies activity type (walking, running, stationary, automotive) via \`CMMotionActivityManager\`
- [ ] Request \`NSMotionUsageDescription\` permission (add to \`Info.plist\`)
- [ ] Enrich daily health data model with \`activityMinutes\`, \`stepCount\`, \`sedentaryMinutes\`
- [ ] Feed activity data into \`PatternRecognitionService\` as an input variable
- [ ] Display activity summary on Dashboard (steps + activity ring)
- [ ] Add correlation insight: \"On days you walk 8,000+ steps, your symptom score is 23% better\"

## Files Likely Affected
- New file: \`Services/CoreMotionService.swift\`
- \`Services/Insights/PatternRecognitionService.swift\`
- \`Views/Dashboard/\`
- \`Info.plist\`

## Notes
- Zero ongoing cost — all on-device
- \`CMPedometer\` requires physical device; Simulator returns zeros
- Prefer Core Motion over HealthKit for steps to avoid additional permission prompt
- If user has already granted HealthKit step access, de-duplicate" \
  '["enhancement","plus-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# --- CloudKit ---
echo ""
echo "-- CloudKit --"
create_issue \
  "[Plus] CloudKit backup and multi-device sync" \
  "## Context
CloudKit provides iCloud-native backup and multi-device sync funded by the user's iCloud storage — zero cost to the developer. For health data this is compelling: end-to-end encrypted, Apple-managed, no additional account needed.

## Goal
Add CloudKit as an optional (or primary) sync backend for Plus subscribers, complementing or replacing Firebase for on-device data.

## Sub-tasks

### CloudKit Setup
- [ ] Add \`iCloud\` capability with CloudKit enabled in Xcode
- [ ] Create \`CKContainer\` and \`CKDatabase\` (private database for user data)
- [ ] Define CloudKit record types mirroring Core Data schema: \`Meal\`, \`Symptom\`, \`Medication\`

### Core Data + CloudKit Integration (Preferred approach)
- [ ] Migrate Core Data stack to \`NSPersistentCloudKitContainer\`
  - This automatically syncs Core Data with CloudKit with minimal code
  - Handles conflict resolution, merge policies, and offline queueing
- [ ] Configure \`NSPersistentStoreDescription\` with CloudKit options
- [ ] Test sync between two devices on the same Apple ID

### Sync Logic
- [ ] Add CloudKit sync status indicator in Settings
- [ ] Handle \`CKError.accountTemporarilyUnavailable\` and show user-friendly message
- [ ] Respect user's \"Private Relay\" / iCloud+ settings
- [ ] Provide \"Disable CloudKit sync\" toggle for users who prefer Firebase only

### Subscription Gating
- [ ] Enable \`NSPersistentCloudKitContainer\` only for Plus+ subscribers
- [ ] Free tier continues using local Core Data only

## Files Likely Affected
- \`Services/CoreData/CoreDataStack.swift\` (migrate to \`NSPersistentCloudKitContainer\`)
- \`Services/CoreData/DataSyncManager.swift\`
- \`GutCheck.entitlements\`

## Notes
- \`NSPersistentCloudKitContainer\` is the lowest-friction path — Apple does the heavy lifting
- User's iCloud storage bears the cost (not the developer)
- End-to-end encrypted in iCloud private database" \
  '["enhancement","plus-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# ==============================================================================
# PRO TIER ISSUES
# ==============================================================================
echo ""
echo "==> Creating Pro Tier issues..."

# --- On-device Food Recognition (replace Google Vision) ---
echo ""
echo "-- On-device Food Recognition --"
create_issue \
  "[Pro] Replace Google Vision API with on-device food recognition using Core ML + Vision" \
  "## Context
GutCheck currently uses Google Vision API for food photo recognition. This has per-call costs (~\$1.50/1,000 images) and sends user food photos to Google's servers — a privacy concern for a health app. Apple's Vision framework + a local Core ML model can provide equivalent or better recognition entirely on-device.

An InceptionV3 model (94.7MB) is already embedded in the app. This work expands that to a full food-first pipeline.

## Goal
Migrate food photo recognition to an on-device Core ML model with Vision framework, eliminating Google Vision API dependency for photo recognition. Google Vision remains optional for barcode/label fallback if needed.

## Sub-tasks

### Model Evaluation & Upgrade
- [ ] Benchmark existing InceptionV3 model accuracy on a food photo test set
- [ ] Evaluate Apple's \`Create ML\` to fine-tune or train a food-specific classifier
- [ ] Consider \`Food-101\` dataset or custom dataset for fine-tuning
- [ ] Optionally download a \`MobileNetV3\` or \`EfficientNet\` food model from Apple's Model Gallery

### Vision + Core ML Pipeline
- [ ] Create \`OnDeviceFoodRecognitionService\` using \`VNCoreMLRequest\` + \`VNImageRequestHandler\`
- [ ] Chain \`VNRecognizeObjectsRequest\` (object detection) → \`VNCoreMLRequest\` (classification)
- [ ] Support multiple food items in a single photo using bounding box detection
- [ ] Return top-5 classification results with confidence scores
- [ ] Map recognized labels to \`FoodItem\` via existing \`FoodSearchService\`

### Integration
- [ ] Replace \`FoodRecognitionService\` Google Vision call path with on-device path
- [ ] Fall back to barcode scanning (\`VNDetectBarcodesRequest\`) if recognition confidence < 0.5
- [ ] Maintain existing Google Vision path as a Pro-only \"cloud confirmation\" option (off by default)
- [ ] Show recognized items with edit capability before saving

### Privacy
- [ ] Confirm no photo data leaves device in default on-device path
- [ ] Add privacy notice: \"Food photos are analyzed on your device and never uploaded\"

## Files Likely Affected
- New file: \`Services/ML/OnDeviceFoodRecognitionService.swift\`
- \`Services/ML/FoodRecognitionService.swift\` (refactor to use new service)
- \`Resources/\` (add/replace Core ML model)

## Notes
- This is a Pro tier feature because it replaces a paid API
- Eliminates Google Vision API cost entirely for standard users
- Vision framework \`VNRecognizeObjectsRequest\` is iOS 12+ (compatible)
- Model size trade-off: larger model = better accuracy, larger app download" \
  '["enhancement","pro-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# --- ARKit Portion Estimation ---
echo ""
echo "-- ARKit Portion Estimation --"
create_issue \
  "[Pro] ARKit + LiDAR portion size estimation" \
  "## Context
Accurate portion size estimation is one of the hardest problems in food logging. ARKit + LiDAR (available on iPhone 12 Pro, 13 Pro, 14 Pro, 15 Pro, 16 Pro) enables 3D volumetric measurement of food items, providing far more accurate portion sizes than image-only estimation.

This is listed on the GutCheck roadmap as an in-development feature.

## Goal
Use ARKit scene reconstruction to estimate food volume and map it to gram-weight portion estimates.

## Sub-tasks

### AR Scene Setup
- [ ] Add \`ARKit\` import; check \`ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)\` at runtime
- [ ] Create \`PortionEstimationARView\` using \`ARView\` (RealityKit) or \`ARSCNView\` (SceneKit)
- [ ] Show AR camera feed with mesh overlay to visualize detected surfaces
- [ ] Provide non-AR fallback (reference object comparison) for non-LiDAR devices

### Volume Measurement
- [ ] Use \`ARMeshGeometry\` from scene reconstruction to capture food mesh
- [ ] Implement convex hull or voxel-based volume calculation from mesh vertices
- [ ] Allow user to tap to select the food item in the AR scene
- [ ] Convert volume (cm³) to estimated weight using food density lookup table
- [ ] Cross-reference weight estimate with \`FoodItem.servingSize\` from nutrition database

### UI Flow
- [ ] Add \"Measure Portion\" button in meal logging view (only shown on LiDAR-capable devices)
- [ ] Full-screen AR view with guidance overlay: \"Place food on flat surface, tap to measure\"
- [ ] Show estimated weight + serving size equivalent after measurement
- [ ] Allow user to adjust estimate with ± stepper before confirming
- [ ] Haptic confirmation when measurement is locked

### Edge Cases
- [ ] Handle reflective/transparent containers (known LiDAR limitation — show warning)
- [ ] Handle multiple food items (let user tap each one separately)
- [ ] Minimum distance requirement: require food to be within 30cm for accuracy

## Files Likely Affected
- New file: \`Views/Meal/PortionEstimationARView.swift\`
- New file: \`Services/ML/PortionEstimationService.swift\`
- \`Views/Meal/MealLoggingView.swift\`

## Notes
- LiDAR required for scene reconstruction; degrade gracefully on non-LiDAR devices
- Zero API cost — entirely on-device
- Measurement accuracy ~10–15% error rate vs kitchen scale; acceptable for diet logging" \
  '["enhancement","pro-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# --- NaturalLanguage NLP ---
echo ""
echo "-- NaturalLanguage Symptom Extraction --"
create_issue \
  "[Pro] On-device NLP symptom extraction from free-text notes using NaturalLanguage framework" \
  "## Context
Users often type free-text notes like \"sharp pain in lower left after dinner, felt better after walking\" in symptom entries. Apple's \`NaturalLanguage\` framework can extract structured data (body location, timing, activities, food triggers) from this text entirely on-device — no external NLP API needed.

## Goal
Parse symptom notes with NaturalLanguage to auto-populate structured symptom fields and surface richer data for pattern recognition.

## Sub-tasks

### Named Entity Recognition
- [ ] Use \`NLTagger\` with \`NLTagScheme.nameType\` to extract entities from notes
- [ ] Create custom word embeddings or gazetteer for health-specific terms:
  - Body locations: \"lower left,\" \"upper right,\" \"stomach,\" \"chest\"
  - Timing words: \"after eating,\" \"before bed,\" \"30 minutes later\"
  - Activities: \"walking,\" \"lying down,\" \"exercise\"
  - Food mentions: cross-reference with FoodCompoundDatabase

### Sentiment & Severity
- [ ] Use \`NLTagger\` with \`NLTagScheme.sentimentScore\` to estimate distress level from note tone
- [ ] Map sentiment score to severity suggestion (if negative/extreme → suggest higher pain level)

### Auto-population
- [ ] After user types note, run NLP in background (debounced, 1s delay)
- [ ] Surface suggestions: \"We detected: Lower abdomen · After meal · Possible trigger: spicy food\"
- [ ] Let user accept/reject each suggestion with a tap
- [ ] Store accepted extractions as structured fields alongside free text

### Pattern Recognition Integration
- [ ] Feed extracted entities into \`PatternRecognitionService\` as structured variables
- [ ] Enable query: \"How often do lower abdomen symptoms follow high-fat meals?\"

## Files Likely Affected
- New file: \`Services/NLP/SymptomNLPService.swift\`
- \`Services/Insights/PatternRecognitionService.swift\`
- \`Views/Bowel/SymptomLoggingView.swift\`

## Notes
- Zero ongoing cost — all on-device, private
- \`NLTagger\` works offline; no internet required
- Fine-tuning with \`Create ML\` and a health-specific corpus would improve accuracy
- Start with regex + NLTagger hybrid; upgrade to full ML model in v2" \
  '["enhancement","pro-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# --- Vision Nutrition Label ---
echo ""
echo "-- Vision Nutrition Label Scanning --"
create_issue \
  "[Pro] Scan nutrition labels from photos using Vision framework VNRecognizeTextRequest" \
  "## Context
Users frequently log packaged foods. Instead of manual data entry or barcode scanning (which requires a database match), Vision's \`VNRecognizeTextRequest\` can read the nutrition facts panel directly from a photo and auto-populate all nutritional fields.

## Goal
Add a \"Scan Nutrition Label\" option in meal logging that uses the camera to read and parse nutrition facts entirely on-device.

## Sub-tasks

### OCR Pipeline
- [ ] Use \`VNRecognizeTextRequest\` with \`recognitionLevel: .accurate\` on the captured photo
- [ ] Parse recognized text blocks for nutrition label structure:
  - Serving size and servings per container
  - Calories, Total Fat, Saturated Fat, Trans Fat
  - Cholesterol, Sodium, Total Carbohydrates, Dietary Fiber, Total Sugars, Protein
  - Vitamins/minerals if present
- [ ] Handle common label formats: US FDA, Canadian, European (metric/imperial)
- [ ] Use regex patterns to match nutrition label field names with common OCR errors (e.g., \"Caiories\" → \"Calories\")

### Camera Integration
- [ ] Add \"Scan Label\" button in the manual food entry form
- [ ] Show live camera view with rectangular guide overlay
- [ ] Capture still frame automatically when text is detected in guide area
- [ ] Show recognized nutrition facts with edit capability before confirming

### Data Population
- [ ] Map parsed values to \`FoodItem\` nutrition fields
- [ ] Pre-populate serving size selector from label data
- [ ] Allow user to confirm/edit each parsed value
- [ ] Save as a custom \`FoodItem\` for future reuse

## Files Likely Affected
- New file: \`Services/Vision/NutritionLabelScannerService.swift\`
- New file: \`Views/Meal/NutritionLabelScannerView.swift\`
- \`Views/Meal/ManualFoodEntryView.swift\`

## Notes
- Zero ongoing cost — on-device only
- Replaces a use case that would otherwise require a nutrition database API lookup
- VNRecognizeTextRequest is iOS 13+ (compatible)
- Accuracy depends on image quality and label format; provide edit step as safety net" \
  '["enhancement","pro-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# --- CareKit ---
echo ""
echo "-- CareKit Healthcare Provider Sharing --"
create_issue \
  "[Pro] CareKit integration for healthcare provider sharing and care plan management" \
  "## Context
GutCheck's roadmap includes a healthcare provider portal. CareKit (Apple's open-source framework) provides pre-built care plan, task, and contact UI that directly maps to GutCheck's use case — without needing to build a clinical data management system from scratch.

## Goal
Integrate CareKit to enable users to share their GutCheck data with healthcare providers and manage care plans (e.g., elimination diet protocols, medication schedules from their GI doctor).

## Sub-tasks

### CareKit Setup
- [ ] Add CareKit and CareKitStore packages via Swift Package Manager
  - \`https://github.com/carekit-apple/CareKit\`
- [ ] Initialize \`OCKStore\` backed by Core Data

### Care Plan Features
- [ ] **Daily Task Cards**: Map GutCheck meal/symptom logging goals to \`OCKTask\` (e.g., \"Log 3 meals today\")
- [ ] **Symptom Charts**: Use \`OCKCartesianChartViewController\` to show Bristol scale trend
- [ ] **Medication Schedule**: Map medication reminders to \`OCKTask\` events
- [ ] **Contact Card**: Store user's GI doctor / dietitian info with \`OCKContact\`

### Provider Sharing
- [ ] Generate FHIR-compatible export (CareKit's \`OCKHealthKitPassthroughStore\` or custom serializer)
- [ ] Allow user to share a time-range summary as PDF or FHIR JSON
- [ ] QR code / share sheet integration for sharing summary with provider in-office
- [ ] Leverage existing \`HealthcareExportService.swift\` (50KB — already partially built)

### Privacy
- [ ] Provider sharing is opt-in per export, never automatic
- [ ] Shared data is de-identified by default; user opts in to include name

## Files Likely Affected
- New folder: \`Services/CareKit/\`
- New views: \`Views/CareKit/CareCardView.swift\`, \`ProviderShareView.swift\`
- \`Services/HealthcareExportService.swift\` (integrate with CareKit export)

## Notes
- CareKit is Apache 2.0 open source — zero licensing cost
- FHIR R4 compatibility helps with EHR integration (Epic, Cerner)
- CareKit's UI is UIKit-based; wrap in \`UIViewControllerRepresentable\` for SwiftUI" \
  '["enhancement","pro-tier","apple-ecosystem","no-api-cost"]' > /dev/null

# --- StoreKit 2 ---
echo ""
echo "-- StoreKit 2 Subscriptions --"
create_issue \
  "Implement StoreKit 2 subscription management for Plus and Pro tiers" \
  "## Context
To monetize the Plus (\$1.99/mo · \$19.99/yr) and Pro (\$2.99/mo · \$29.99/yr) tiers, GutCheck needs StoreKit 2 — Apple's modern Swift-native in-app purchase API with on-device receipt validation, no server required.

## Goal
Implement full subscription lifecycle using StoreKit 2: purchase, restore, entitlement verification, and paywall UI.

## Sub-tasks

### App Store Connect Setup
- [ ] Create subscription group \"GutCheck Premium\" in App Store Connect
- [ ] Create products:
  - \`com.gutcheck.plus.monthly\` — \$1.99/month
  - \`com.gutcheck.plus.annual\` — \$19.99/year
  - \`com.gutcheck.pro.monthly\` — \$2.99/month
  - \`com.gutcheck.pro.annual\` — \$29.99/year
- [ ] Configure free trial period (7 days recommended)
- [ ] Set up introductory offer (first month 50% off)

### StoreKit 2 Implementation
- [ ] Create \`SubscriptionService\` using \`StoreKit.Product\` and \`Transaction\`
- [ ] Fetch available products with \`Product.products(for:)\`
- [ ] Purchase with \`product.purchase()\`
- [ ] Verify entitlement: iterate \`Transaction.currentEntitlements\` (no server receipt validation needed)
- [ ] Listen for \`Transaction.updates\` for renewals, cancellations, refunds
- [ ] Restore purchases with \`AppStore.sync()\`
- [ ] Handle \`Product.SubscriptionInfo.RenewalState\` for subscription status

### Paywall UI
- [ ] Design paywall screen showing Free vs Plus vs Pro feature comparison
- [ ] Monthly/Annual toggle with savings callout (\"Save 17% annually\")
- [ ] \"Start Free Trial\" CTA
- [ ] Legal: include links to Terms of Service and Privacy Policy
- [ ] \"Restore Purchases\" button

### Entitlement Enforcement
- [ ] Create \`EntitlementManager\` \`@Observable\` class with \`currentTier: SubscriptionTier\`
- [ ] Inject into environment; gate features with \`if entitlementManager.hasPro { ... }\`
- [ ] Check entitlement on app launch and after any transaction

### Testing
- [ ] Use StoreKit Testing in Xcode (StoreKit configuration file)
- [ ] Test purchase, cancel, refund, and expiry flows with \`SKTestSession\`

## Files Likely Affected
- New file: \`Services/SubscriptionService.swift\`
- New file: \`Services/EntitlementManager.swift\`
- New file: \`Views/Paywall/PaywallView.swift\`
- \`GutCheckApp.swift\` (inject EntitlementManager into environment)
- All feature views that check entitlement

## Notes
- StoreKit 2 requires iOS 15+ (project already targets iOS 15 ✓)
- No server-side receipt validation needed — on-device verification is cryptographically secure
- Apple takes 15% commission for subscriptions after the first year (30% first year unless small business program)
- Test with real StoreKit sandbox before submission" \
  '["enhancement","monetization","apple-ecosystem"]' > /dev/null

# --- iPad ---
echo ""
echo "-- iPad Layout --"
create_issue \
  "iPad adaptive layout with split-view and expanded analytics canvas" \
  "## Context
GutCheck currently targets iPhone only. An iPad layout would provide a larger canvas for the analytics and insights views, and a split-view interface for browsing history while logging simultaneously.

## Goal
Adapt GutCheck's SwiftUI interface for iPad using adaptive layouts, NavigationSplitView, and expanded chart canvases.

## Sub-tasks
- [ ] Audit all views for \`.frame\` hardcoded widths that break on iPad
- [ ] Replace \`NavigationStack\` on iPad with \`NavigationSplitView\` (sidebar + detail)
  - Sidebar: dashboard summary, meal/symptom/medication list
  - Detail: selected entry or insights chart
- [ ] Adapt TabView: on iPad, use sidebar navigation instead of bottom tab bar (\`tabViewStyle(.sidebarAdaptable)\` iOS 18+, or manual sidebar)
- [ ] Expand chart views (\`InsightsView\`) to use full iPad width with multi-column layout
- [ ] Meal logging sheet → popover or split-pane on iPad
- [ ] Test all modal sheets for appropriate presentation style (\`.sheet\` vs \`.popover\`)
- [ ] Support multitasking: Split View (50/50), Slide Over
- [ ] Test with keyboard attached (external keyboard shortcut support via \`KeyboardShortcut\`)

## Files Likely Affected
- \`Views/AppRoot.swift\` (navigation architecture)
- \`Views/Insights/\` (chart layout)
- \`Views/Meal/\` (logging sheets)
- Most view files — audit \`.frame(width:)\` usage

## Notes
- Zero ongoing cost
- Lower priority than Watch; address after Watch app ships
- Use \`horizontalSizeClass\` environment value to branch layouts
- Universal binary (iPhone + iPad) = single App Store listing" \
  '["enhancement","apple-ecosystem","no-api-cost"]' > /dev/null

echo ""
echo "==> All issues created successfully!"
echo ""
echo "Next steps:"
echo "  1. Visit https://github.com/$REPO/issues to review and organize"
echo "  2. Link child issues to their Epic parent issues"
echo "  3. Create a Milestone for each tier (Free v1, Plus v1, Pro v1)"
echo "  4. Assign issues to the relevant milestone"
