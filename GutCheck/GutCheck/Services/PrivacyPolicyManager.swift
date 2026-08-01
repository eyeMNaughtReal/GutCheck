//
//  PrivacyPolicyManager.swift
//  GutCheck
//
//  Service for managing privacy policy versions and acceptance tracking
//
//  Created by Mark Conley on 8/18/25.
//

import Foundation

@MainActor
@Observable class PrivacyPolicyManager {
    static let shared = PrivacyPolicyManager()

    /// Bumped to 2.0 because the policy text below changed materially: the app
    /// no longer has accounts and no longer sends anything to a server, so the
    /// previous version described handling that no longer happens.
    var currentVersion = "2.0"
    var lastUpdated = "August 1, 2026"
    var isPrivacyPolicyAccepted = false
    var privacyPolicyAcceptedDate: Date?

    private let userDefaults = UserDefaults.standard

    private init() {
        loadPrivacyPolicyStatus()
    }

    // MARK: - Privacy Policy Status

    /// Loads privacy policy acceptance status from UserDefaults
    private func loadPrivacyPolicyStatus() {
        isPrivacyPolicyAccepted = userDefaults.bool(forKey: "privacyPolicyAccepted")
        if let date = userDefaults.object(forKey: "privacyPolicyAcceptedDate") as? Date {
            privacyPolicyAcceptedDate = date
        }
    }

    /// Saves privacy policy acceptance status to UserDefaults
    private func savePrivacyPolicyStatus() {
        userDefaults.set(isPrivacyPolicyAccepted, forKey: "privacyPolicyAccepted")
        if let date = privacyPolicyAcceptedDate {
            userDefaults.set(date, forKey: "privacyPolicyAcceptedDate")
        }
    }

    // MARK: - Privacy Policy Acceptance

    /// Records acceptance of the current policy version.
    ///
    /// Written to the local profile as well as `UserDefaults` so it travels
    /// with the profile and shows up in the healthcare export.
    func acceptPrivacyPolicy() async throws {
        isPrivacyPolicyAccepted = true
        privacyPolicyAcceptedDate = Date.now
        savePrivacyPolicyStatus()

        do {
            try await LocalUserService.shared.acceptPrivacyPolicy(version: currentVersion)
        } catch {
            throw PrivacyPolicyError.updateFailed
        }
    }

    /// Checks whether the user has accepted the version currently shipping.
    func needsPrivacyPolicyUpdate() -> Bool {
        guard let acceptedVersion = LocalUserService.shared.currentUser?.privacyPolicyVersion else {
            return !isPrivacyPolicyAccepted
        }
        return !isPrivacyPolicyAccepted || acceptedVersion != currentVersion
    }

    /// Forces user to re-accept privacy policy (for updates)
    func forcePrivacyPolicyUpdate() {
        isPrivacyPolicyAccepted = false
        privacyPolicyAcceptedDate = nil
        savePrivacyPolicyStatus()
    }

    // MARK: - Privacy Policy Content

    /// Gets the current privacy policy content
    func getPrivacyPolicyContent() -> String {
        return """
        GutCheck Privacy Policy
        Effective Date: \(lastUpdated)

        GutCheck ("we", "us", or "our") is committed to protecting your privacy. \
        This Privacy Policy explains how your data is collected, used, and stored.

        1. Data We Collect
        GutCheck records only what you enter in the app:
        - Meals and ingredients (manually entered, scanned, or photographed)
        - Symptoms and bowel movements
        - Medications and doses
        - The dates and times you logged them

        There are no accounts. GutCheck does not ask for an email address or \
        password, and does not collect analytics, advertising identifiers, or \
        usage telemetry.

        We also read the following from Apple HealthKit, with your permission:
        - Age, Weight, Height
        - Additional relevant health metrics that may enhance analysis

        2. How We Use Your Data
        Your data is used solely to:
        - Provide insights and pattern recognition between food and symptoms
        - Help you track digestive health over time
        - Power on-device suggestions and predictions tailored to your profile

        3. Data Storage and Security
        All of your data is stored on this device and nowhere else. There is no \
        GutCheck server and no cloud account, so your health history is never \
        transmitted to us or to any third party.

        The on-device database is protected by iOS Data Protection, which keeps \
        it encrypted at rest while your device is locked. Data leaves the device \
        only when you explicitly export or share it — for example, when you \
        generate a healthcare report and choose where to send it.

        Food and nutrition lookups are the one exception: searching for a food \
        sends only the search term you typed to third-party nutrition databases \
        (Open Food Facts and the USDA FoodData Central API). No personal or \
        health information is included in those requests.

        4. Your Rights and Choices
        You have the right to:
        - View, export, or delete your data
        - Erase everything at any time from within the app, which takes effect \
          immediately and permanently
        - Revoke HealthKit permissions at any time via iOS Settings
        - Contact us with privacy-related questions or requests

        Because your data lives only on this device, deleting the app also \
        deletes your history. Export anything you want to keep first.

        5. Contact Us
        If you have any questions about this policy or your data, please contact us at:
        Email: gutcheckapp@protonmail.com

        This policy may be updated. The latest version will always be accessible \
        from within the app's Settings.
        """
    }
}

// MARK: - Privacy Policy Errors

enum PrivacyPolicyError: LocalizedError {
    case updateFailed

    var errorDescription: String? {
        switch self {
        case .updateFailed:
            return "Failed to update privacy policy acceptance"
        }
    }
}
