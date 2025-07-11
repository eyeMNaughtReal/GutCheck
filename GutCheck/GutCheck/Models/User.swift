//
//  User.swift
//  GutCheck
//
//  Created by Mark Conley on 7/11/25.
//

import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let createdAt: Date
    let updatedAt: Date
    
    // Computed properties
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let firstInitial = firstName.prefix(1).uppercased()
        let lastInitial = lastName.prefix(1).uppercased()
        return "\(firstInitial)\(lastInitial)"
    }
    
    // Firebase timestamp conversion
    init(id: String, email: String, firstName: String, lastName: String, createdAt: Timestamp, updatedAt: Timestamp) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.createdAt = createdAt.dateValue()
        self.updatedAt = updatedAt.dateValue()
    }
    
    // Standard initializer
    init(id: String, email: String, firstName: String, lastName: String, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
