//
//  StoredUserProfile.swift
//  GutCheck
//
//  SwiftData entity backing the `User` domain struct.
//
//  There are no accounts — this is the single device-local profile. Its `id` is
//  what every record's `createdBy` points at, so meals and symptoms logged
//  before a profile edit still resolve to the same owner.
//

import Foundation
import SwiftData

@Model
final class StoredUserProfile {
    @Attribute(.unique) var id: String

    var email: String
    var firstName: String
    var lastName: String
    var createdAt: Date
    var updatedAt: Date

    var profileImageURL: String?

    var privacyPolicyAccepted: Bool
    var privacyPolicyAcceptedDate: Date?
    var privacyPolicyVersion: String

    var dateOfBirth: Date?
    /// `HKBiologicalSex` raw value, or nil when not set.
    var biologicalSexRawValue: Int?
    /// Kilograms.
    var weight: Double?
    /// Meters.
    var height: Double?

    init(
        id: String,
        email: String,
        firstName: String,
        lastName: String,
        createdAt: Date,
        updatedAt: Date,
        profileImageURL: String?,
        privacyPolicyAccepted: Bool,
        privacyPolicyAcceptedDate: Date?,
        privacyPolicyVersion: String,
        dateOfBirth: Date?,
        biologicalSexRawValue: Int?,
        weight: Double?,
        height: Double?
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.profileImageURL = profileImageURL
        self.privacyPolicyAccepted = privacyPolicyAccepted
        self.privacyPolicyAcceptedDate = privacyPolicyAcceptedDate
        self.privacyPolicyVersion = privacyPolicyVersion
        self.dateOfBirth = dateOfBirth
        self.biologicalSexRawValue = biologicalSexRawValue
        self.weight = weight
        self.height = height
    }
}

// MARK: - Domain mapping

extension StoredUserProfile {
    convenience init(_ user: User) {
        self.init(
            id: user.id,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
            profileImageURL: user.profileImageURL,
            privacyPolicyAccepted: user.privacyPolicyAccepted,
            privacyPolicyAcceptedDate: user.privacyPolicyAcceptedDate,
            privacyPolicyVersion: user.privacyPolicyVersion,
            dateOfBirth: user.dateOfBirth,
            biologicalSexRawValue: user.biologicalSexRawValue,
            weight: user.weight,
            height: user.height
        )
    }

    func apply(_ user: User) {
        email = user.email
        firstName = user.firstName
        lastName = user.lastName
        updatedAt = Date.now
        profileImageURL = user.profileImageURL
        privacyPolicyAccepted = user.privacyPolicyAccepted
        privacyPolicyAcceptedDate = user.privacyPolicyAcceptedDate
        privacyPolicyVersion = user.privacyPolicyVersion
        dateOfBirth = user.dateOfBirth
        biologicalSexRawValue = user.biologicalSexRawValue
        weight = user.weight
        height = user.height
    }

    var domainModel: User {
        var user = User(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            createdAt: createdAt,
            updatedAt: updatedAt,
            privacyPolicyAccepted: privacyPolicyAccepted,
            privacyPolicyAcceptedDate: privacyPolicyAcceptedDate,
            privacyPolicyVersion: privacyPolicyVersion
        )
        user.profileImageURL = profileImageURL
        user.dateOfBirth = dateOfBirth
        user.biologicalSexRawValue = biologicalSexRawValue
        user.weight = weight
        user.height = height
        return user
    }
}
