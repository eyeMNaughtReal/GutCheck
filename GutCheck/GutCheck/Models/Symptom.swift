//
//  Symptom.swift
//  GutCheck
//
//  Updated to include FirestoreModel conformance
//

import Foundation

enum StoolType: Int, Codable, CaseIterable {
    case type1 = 1, type2, type3, type4, type5, type6, type7
}

enum PainLevel: Int, Codable, CaseIterable {
    case none = 0, mild = 1, moderate = 2, severe = 3
}

enum UrgencyLevel: Int, Codable, CaseIterable {
    case none = 0, mild = 1, moderate = 2, urgent = 3
}

struct Symptom: Identifiable, Codable, Hashable, Equatable, FirestoreModel {
    var id: String = UUID().uuidString
    var date: Date
    var stoolType: StoolType
    var painLevel: PainLevel
    var urgencyLevel: UrgencyLevel
    var notes: String?
    var tags: [String] = []
    var createdBy: String  // Firebase UID
}
