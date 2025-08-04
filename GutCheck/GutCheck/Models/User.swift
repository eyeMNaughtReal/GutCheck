//
//  User.swift
//  GutCheck
//
//  Fixed User model with proper Codable compliance
//

import Foundation
import FirebaseFirestore
import HealthKit

struct User: Codable, Identifiable, Hashable, Equatable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let signInMethod: SignInMethod
    let createdAt: Date
    let updatedAt: Date
    
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
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
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
    
    // Firebase timestamp conversion initializer
    init(id: String, email: String, firstName: String, lastName: String, signInMethod: SignInMethod, createdAt: Timestamp, updatedAt: Timestamp) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.signInMethod = signInMethod
        self.createdAt = createdAt.dateValue()
        self.updatedAt = updatedAt.dateValue()
    }
    
    // Standard initializer
    init(id: String, email: String, firstName: String, lastName: String, signInMethod: SignInMethod = .email, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.signInMethod = signInMethod
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Firestore Conversion
    
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "signInMethod": signInMethod.rawValue,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // Add optional health data
        if let dateOfBirth = dateOfBirth {
            data["dateOfBirth"] = Timestamp(date: dateOfBirth)
        }
        if let weight = weight {
            data["weight"] = weight
        }
        if let height = height {
            data["height"] = height
        }
        if let biologicalSexRawValue = biologicalSexRawValue {
            data["biologicalSexRawValue"] = biologicalSexRawValue
        }
        
        return data
    }
    
}

// MARK: - Sign In Methods
enum SignInMethod: String, CaseIterable, Codable {
    case email = "email"
    case apple = "apple"
    case phone = "phone"
    
    var displayName: String {
        switch self {
        case .email:
            return "Email"
        case .apple:
            return "Apple"
        case .phone:
            return "Phone"
        }
    }
    
    var icon: String {
        switch self {
        case .email:
            return "envelope.fill"
        case .apple:
            return "applelogo"
        case .phone:
            return "phone.fill"
        }
    }
}
