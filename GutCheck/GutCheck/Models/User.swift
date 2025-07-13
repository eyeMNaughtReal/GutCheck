//
//  User.swift
//  GutCheck
//
//  Consolidated user model replacing User.swift, UserProfile.swift, and UserHealthProfile.swift
//

import Foundation
import FirebaseFirestore
import HealthKit

struct User: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let signInMethod: SignInMethod
    let createdAt: Date
    let updatedAt: Date
    
    // Health data (optional)
    var dateOfBirth: Date?
    var biologicalSex: HKBiologicalSex?
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
    
    var formattedHeight: String {
        guard let height = height else { return "-" }
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        return formatter.string(fromValue: height, unit: .meter)
    }
    
    var formattedWeight: String {
        guard let weight = weight else { return "-" }
        let formatter = MassFormatter()
        formatter.unitStyle = .short
        return formatter.string(fromValue: weight, unit: .kilogram)
    }
    
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
