# GutCheck Project Wiki

Welcome to the GutCheck project wiki! This resource is designed to help contributors, maintainers, and users understand the architecture, development process, CI/CD, and best practices for the GutCheck iOS app.

---

## Table of Contents
- [Project Overview](#project-overview)
- [Architecture & File Structure](#architecture--file-structure)
- [Development Workflow](#development-workflow)
- [CI/CD & Automation](#cicd--automation)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Code Citations](#code-citations)
- [Resources](#resources)

---

## Project Overview
GutCheck is a SwiftUI-based iOS app for gastrointestinal symptom tracking, meal logging, and AI-powered analysis. It uses Firebase, Core Data, and HealthKit for data management and analytics.

---

## Architecture & File Structure
- **GutCheck/**: Main app entry, configuration, and resources.
- **Models/**: Core data structures (Meal, Symptom, UserProfile, FoodItem).
- **Views/**: UI screens, organized by feature (Dashboard, MealLogging, SymptomLogging, Calendar, Analysis, Settings, Authentication).
- **ViewModels/**: Logic and bindings for each view.
- **Services/**: Utilities and shared logic (AI, Firebase, Sync, Local Storage, Barcode, HealthKit, Mock Data).
- **Resources/**: Assets, localization, privacy policy, Firebase config.
- **Tests/**: Unit and integration tests for all major features.

---

## Development Workflow
- Use feature branches for all new work.
- Submit pull requests for code review.
- Write unit and UI tests for new features.
- Keep Apple Sign In code commented out unless you have a paid developer account.
- Use the DebugView for development-only tools; remove before production.
- Sensitive files (e.g., `GoogleService-Info.plist`) should not be committed.

---

## CI/CD & Automation
- Use a GitHub Actions workflow (see `ios.yml` example below) for automated build and test on PRs and pushes to `main`.
- Ensure all build/test steps use the correct working directory if your `.xcodeproj` is in a subfolder.

**Example iOS Workflow:**
```yaml
name: iOS starter workflow
on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
jobs:
  build:
    name: Build and Test default scheme using any available iPhone simulator
    runs-on: macos-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Set Default Scheme
        run: |
          scheme_list=$(xcodebuild -list -json | tr -d "\n")
          default=$(echo $scheme_list | ruby -e "require 'json'; puts JSON.parse(STDIN.gets)['project']['targets'][0]")
          echo $default | cat >default
          echo Using default scheme: $default
        working-directory: GutCheck
      - name: Build
        env:
          scheme: ${{ 'default' }}
          platform: ${{ 'iOS Simulator' }}
        run: |
          device=`xcrun xctrace list devices 2>&1 | grep -oE 'iPhone.*?[^\(]+' | head -1 | awk '{$1=$1;print}' | sed -e "s/ Simulator$//"`
          if [ $scheme = default ]; then scheme=$(cat default); fi
          if [ "`ls -A | grep -i \\.xcworkspace$`" ]; then filetype_parameter="workspace" && file_to_build="`ls -A | grep -i \\.xcworkspace$`"; else filetype_parameter="project" && file_to_build="`ls -A | grep -i \\.xcodeproj$`"; fi
          file_to_build=`echo $file_to_build | awk '{$1=$1;print}'`
          xcodebuild build-for-testing -scheme "$scheme" -"$filetype_parameter" "$file_to_build" -destination "platform=$platform,name=$device"
        working-directory: GutCheck
      - name: Test
        env:
          scheme: ${{ 'default' }}
          platform: ${{ 'iOS Simulator' }}
        run: |
          device=`xcrun xctrace list devices 2>&1 | grep -oE 'iPhone.*?[^\(]+' | head -1 | awk '{$1=$1;print}' | sed -e "s/ Simulator$//"`
          if [ $scheme = default ]; then scheme=$(cat default); fi
          if [ "`ls -A | grep -i \\.xcworkspace$`" ]; then filetype_parameter="workspace" && file_to_build="`ls -A | grep -i \\.xcworkspace$`"; else filetype_parameter="project" && file_to_build="`ls -A | grep -i \\.xcodeproj$`"; fi
          file_to_build=`echo $file_to_build | awk '{$1=$1;print}'`
          xcodebuild test-without-building -scheme "$scheme" -"$filetype_parameter" "$file_to_build" -destination "platform=$platform,name=$device"
        working-directory: GutCheck
```

---

## Testing
- Unit tests for all major features in `Tests/`.
- UI tests for authentication and core flows.
- Run tests locally before pushing or opening a PR.

---

## Troubleshooting
- **Build Issues:** Try deleting DerivedData and resetting Swift Package dependencies.
- **Simulator Issues:** Reset the simulator or clean the build folder if UI tests fail to launch.
- **Firebase:** Ensure `GoogleService-Info.plist` is present (not checked into git).
- **CI Failures:** Check the GitHub Actions logs for dependency or test failures.
- **Xcode Version:** Ensure your project format matches the Xcode version available on GitHub Actions.

---

## Code Citations
This project’s CI workflow is inspired by open-source examples:
- [kokwanimohit1803/CICDExample](https://github.com/kokwanimohit1803/CICDExample/tree/99722724566d22b5dc680b4f31cd05443b6810bb/.github/workflows/ios.yml)
- [prplecake/Swift-Landmarks](https://github.com/prplecake/Swift-Landmarks/tree/052b236cf8907679ed38cad05e5cf9f5db4d817b/.github/workflows/ios.yml)
- [Cay-Zhang/RSSBud (MIT License)](https://github.com/Cay-Zhang/RSSBud/tree/e6c6af73215bacfc87f51296451831744cb9cd46/.github/workflows/ios.yml)
- [jiamitegong118/666](https://github.com/jiamitegong118/666/tree/0f242c4735943614b21fe0b140b3971ff9c9349a/ci/ios.yml)
- [OpenEmu/OpenEmu](https://github.com/OpenEmu/OpenEmu/tree/375f1b6705065549d3235688353743b5a87cc3f2/.github/workflows/objective-c-xcode.yml)

---

## Resources
- [GutCheck_Developer_Guide.md](GutCheck_Developer_Guide.md)
- [GutCheck_Architecture_Plan.md](GutCheck_Architecture_Plan.md)
- [CONTRIBUTING.md](CONTRIBUTING.md)
- [README.md](README.md)

---

_Last Updated: August 2025_
