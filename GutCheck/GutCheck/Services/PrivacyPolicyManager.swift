//
//  PrivacyPolicyManager.swift
//  GutCheck
//
//  Service for managing privacy policy versions and acceptance tracking
//
//  Created by Mark Conley on 8/18/25.
//

import Foundation
import FirebaseFirestore

@MainActor
class PrivacyPolicyManager: ObservableObject {
    static let shared = PrivacyPolicyManager()
    
    @Published var currentVersion = "1.0"
    @Published var lastUpdated = "August 18, 2025"
    @Published var isPrivacyPolicyAccepted = false
    @Published var privacyPolicyAcceptedDate: Date?
    
    private let firestore = Firestore.firestore()
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
    
    /// Accepts the current privacy policy version
    func acceptPrivacyPolicy() async throws {
        guard let userId = getCurrentUserId() else {
            throw PrivacyPolicyError.userNotAuthenticated
        }
        
        // Update local status
        isPrivacyPolicyAccepted = true
        privacyPolicyAcceptedDate = Date()
        savePrivacyPolicyStatus()
        
        // Update Firestore
        try await updatePrivacyPolicyAcceptance(userId: userId)
    }
    
    /// Updates privacy policy acceptance in Firestore
    private func updatePrivacyPolicyAcceptance(userId: String) async throws {
        let userRef = firestore.collection("users").document(userId)
        
        try await userRef.updateData([
            "privacyPolicyAccepted": true,
            "privacyPolicyAcceptedDate": FieldValue.serverTimestamp(),
            "privacyPolicyVersion": currentVersion,
            "updatedAt": FieldValue.serverTimestamp()
        ])
        
        print("🔐 PrivacyPolicyManager: Privacy policy accepted for user \(userId)")
    }
    
    /// Checks if user needs to accept updated privacy policy
    func needsPrivacyPolicyUpdate() -> Bool {
        // For now, always return false since we're on version 1.0
        // In the future, this would check against a server version
        return false
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
        
        GutCheck ("we", "us", or "our") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, store, and protect your data in accordance with U.S. privacy regulations and HIPAA principles.
        
        1. Data We Collect
        We collect personal health data that you log within the app, including:
        - Meals and ingredients (manually entered, scanned, or photographed)
        - Symptoms and bowel movements
        - Timestamps and app usage behavior
        - Authentication credentials via Apple, Google, or Email
        
        We also collect the following data from Apple HealthKit (with your permission):
        - Age, Weight, Height
        - Additional relevant health metrics that may enhance analysis
        
        2. How We Use Your Data
        Your data is used solely to:
        - Provide insights and pattern recognition between food and symptoms
        - Help you track digestive health over time
        - Power AI-based suggestions and predictions tailored to your physiological profile
        
        3. Data Storage and Security
        All data is stored securely in Google Firebase and is encrypted in transit (TLS). HealthKit data is only used locally or securely synced if permitted, and is never shared with third parties.
        
        4. Your Rights and Choices
        You have the right to:
        - View, export, or delete your data
        - Delete your account at any time from within the app
        - Revoke HealthKit permissions at any time via iOS Settings
        - Contact us with privacy-related questions or requests
        
        5. Contact Us
        If you have any questions about this policy or your data, please contact us at:
        Email: gutcheckapp@protonmail.com
        
        This policy may be updated. The latest version will always be accessible from within the app's Settings.
        """
    }
    
    // MARK: - Helper Methods
    
    /// Gets the current user ID from AuthService
    private func getCurrentUserId() -> String? {
        // This would typically get the user ID from AuthService
        // For now, we'll use a placeholder
        return nil
    }
}

// MARK: - Privacy Policy Errors

enum PrivacyPolicyError: LocalizedError {
    case userNotAuthenticated
    case updateFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated to accept privacy policy"
        case .updateFailed:
            return "Failed to update privacy policy acceptance"
        }
    }
}
