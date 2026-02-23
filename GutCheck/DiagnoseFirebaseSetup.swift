//
//  DiagnoseFirebaseSetup.swift
//  GutCheck
//
//  Helper to diagnose Firebase configuration issues
//

import Foundation

#if DEBUG
struct FirebaseDiagnostics {
    
    static func checkConfiguration() {
        print("\n" + String(repeating: "=", count: 80))
        print("🔍 FIREBASE CONFIGURATION DIAGNOSTICS")
        print(String(repeating: "=", count: 80))
        
        // Check 1: Info.plist exists and has Bundle ID
        checkInfoPlist()
        
        // Check 2: GoogleService-Info.plist exists
        checkGoogleServicePlist()
        
        // Check 3: Compare Bundle IDs
        compareBundleIDs()
        
        print(String(repeating: "=", count: 80) + "\n")
    }
    
    private static func checkInfoPlist() {
        print("\n📱 Checking Info.plist...")
        
        guard let infoPlist = Bundle.main.infoDictionary else {
            print("   ❌ ERROR: Cannot read Info.plist")
            return
        }
        
        if let bundleID = infoPlist["CFBundleIdentifier"] as? String {
            print("   ✅ Bundle Identifier: \(bundleID)")
        } else {
            print("   ❌ ERROR: No Bundle Identifier found in Info.plist")
        }
        
        if let appName = infoPlist["CFBundleDisplayName"] as? String {
            print("   ✅ App Name: \(appName)")
        } else if let appName = infoPlist["CFBundleName"] as? String {
            print("   ✅ App Name: \(appName)")
        }
        
        if let version = infoPlist["CFBundleShortVersionString"] as? String {
            print("   ✅ Version: \(version)")
        }
    }
    
    private static func checkGoogleServicePlist() {
        print("\n🔥 Checking GoogleService-Info.plist...")
        
        // Try to find the file
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            print("   ✅ File found at: \(path)")
            
            // Try to read it
            if let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
                print("   ✅ File is readable")
                
                // Check for required keys
                let requiredKeys = [
                    "API_KEY",
                    "GCM_SENDER_ID",
                    "PLIST_VERSION",
                    "BUNDLE_ID",
                    "PROJECT_ID",
                    "GOOGLE_APP_ID"
                ]
                
                for key in requiredKeys {
                    if let value = dict[key] as? String, !value.isEmpty {
                        if key == "API_KEY" {
                            // Don't print full API key
                            let masked = String(value.prefix(10)) + "..."
                            print("   ✅ \(key): \(masked)")
                        } else {
                            print("   ✅ \(key): \(value)")
                        }
                    } else {
                        print("   ❌ Missing or empty: \(key)")
                    }
                }
                
            } else {
                print("   ❌ ERROR: File exists but cannot be parsed")
                print("   💡 The file might be corrupted. Try re-downloading it.")
            }
            
        } else {
            print("   ❌ ERROR: GoogleService-Info.plist NOT FOUND")
            print("\n   📋 How to fix:")
            print("   1. Go to https://console.firebase.google.com/")
            print("   2. Select your project (or create one)")
            print("   3. Go to Project Settings → Your apps")
            print("   4. Download GoogleService-Info.plist")
            print("   5. In Xcode: Right-click project → Add Files to \"GutCheck\"")
            print("   6. ✅ Check \"Copy items if needed\"")
            print("   7. ✅ Check your app target under \"Add to targets\"")
        }
    }
    
    private static func compareBundleIDs() {
        print("\n🔗 Comparing Bundle IDs...")
        
        guard let infoBundleID = Bundle.main.bundleIdentifier else {
            print("   ❌ Cannot get Bundle ID from Info.plist")
            return
        }
        
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
              let googleBundleID = dict["BUNDLE_ID"] as? String else {
            print("   ⚠️  Cannot compare - GoogleService-Info.plist not available")
            return
        }
        
        if infoBundleID == googleBundleID {
            print("   ✅ Bundle IDs MATCH!")
            print("   📱 App: \(infoBundleID)")
            print("   🔥 Firebase: \(googleBundleID)")
        } else {
            print("   ❌ Bundle IDs DO NOT MATCH!")
            print("   📱 App Bundle ID:      \(infoBundleID)")
            print("   🔥 Firebase Bundle ID: \(googleBundleID)")
            print("\n   💡 How to fix:")
            print("   Option 1: Download a new GoogleService-Info.plist for '\(infoBundleID)'")
            print("   Option 2: Change your app's Bundle ID in Xcode to '\(googleBundleID)'")
        }
    }
    
    // Call this from your AppDelegate
    static func runDiagnostics() {
        checkConfiguration()
    }
}
#endif
