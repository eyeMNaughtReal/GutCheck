//
//  User.swift
//  GutCheck
//
//  The single device-local profile.
//
//  There are no accounts and no server: this describes the person using this
//  install, and its `id` is what every meal, symptom and medication record
//  points at through `createdBy`.
//

import Foundation
import HealthKit

struct User: Codable, Identifiable, Hashable, Equatable {
    /// Identity and creation time are fixed for the life of the profile —
    /// every record's `createdBy` resolves through `id`.
    let id: String
    let createdAt: Date
    let updatedAt: Date

    // Editable profile fields.
    //
    // These were `let` while they came from the auth provider and could only be
    // set at account creation. The profile is now filled in and edited in-app,
    // so they are `var` like the health fields below.

    /// Optional contact address the user can set for healthcare exports. Empty
    /// when they haven't given one — nothing signs in with it.
    var email: String
    var firstName: String
    var lastName: String

    // Profile image
    var profileImageURL: String?
    
    // Privacy Policy Tracking
    var privacyPolicyAccepted: Bool
    var privacyPolicyAcceptedDate: Date?
    var privacyPolicyVersion: String
    
    // Health data (optional) - using raw values for Codable compliance
    var dateOfBirth: Date?
    var biologicalSexRawValue: Int? // Store HKBiologicalSex as raw value
    var weight: Double? // in kg
    var height: Double? // in meters
    
    // Computed properties
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let firstInitial = firstName.prefix(1).uppercased()
        let lastInitial = lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
    
    var age: Int? {
        guard let dateOfBirth = dateOfBirth else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date.now)
        return ageComponents.year
    }
    
    var heightInCm: Double? {
        guard let height = height else { return nil }
        return height * 100 // Convert meters to cm
    }
    
    func formattedHeight(using unitSystem: UnitSystem = .metric) -> String {
        guard let height = height else { return "-" }
        let formatter = LengthFormatter()
        formatter.unitStyle = .medium
        
        switch unitSystem {
        case .metric:
            return formatter.string(fromValue: height, unit: .meter)
        case .imperial:
            let feet = height * 3.28084
            return formatter.string(fromValue: feet, unit: .foot)
        }
    }
    
    func formattedWeight(using unitSystem: UnitSystem = .metric) -> String {
        guard let weight = weight else { return "-" }
        let formatter = MassFormatter()
        formatter.unitStyle = .medium
        
        switch unitSystem {
        case .metric:
            return formatter.string(fromValue: weight, unit: .kilogram)
        case .imperial:
            let pounds = weight * 2.20462
            return formatter.string(fromValue: pounds, unit: .pound)
        }
    }
    
    // Computed property for biological sex
    var biologicalSex: HKBiologicalSex? {
        get {
            guard let rawValue = biologicalSexRawValue else { return nil }
            return HKBiologicalSex(rawValue: rawValue)
        }
        set {
            biologicalSexRawValue = newValue?.rawValue
        }
    }
    
    var genderString: String {
        guard let biologicalSex = biologicalSex else { return "Not Set" }
        switch biologicalSex {
        case .male:
            return "Male"
        case .female:
            return "Female"
        case .other:
            return "Other"
        case .notSet:
            return "Not Set"
        @unknown default:
            return "Unknown"
        }
    }
    
    // MARK: - Initializers

    init(id: String,
         email: String = "",
         firstName: String,
         lastName: String,
         createdAt: Date = Date.now,
         updatedAt: Date = Date.now,
         privacyPolicyAccepted: Bool = false,
         privacyPolicyAcceptedDate: Date? = nil,
         privacyPolicyVersion: String = "1.0") {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.privacyPolicyAccepted = privacyPolicyAccepted
        self.privacyPolicyAcceptedDate = privacyPolicyAcceptedDate
        self.privacyPolicyVersion = privacyPolicyVersion
    }
}
