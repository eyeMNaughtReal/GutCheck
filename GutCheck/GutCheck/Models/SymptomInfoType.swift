// SymptomInfoType.swift
// GutCheck
// Shared enum for symptom info sheet navigation

import Foundation

public enum SymptomInfoType: String, Identifiable, CaseIterable {
    case bristol, pain, urgency
    public var id: String { rawValue }
}
