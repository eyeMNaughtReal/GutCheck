//
//  SymptomFilter.swift
//  GutCheck
//
//  Shared symptom filter enum
//

import Foundation

enum SymptomFilter: String, CaseIterable {
    case all = "all"
    case pain = "pain"
    case urgency = "urgency"
    case stool = "stool"
    case bloating = "bloating"
    case nausea = "nausea"
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .pain: return "Pain"
        case .urgency: return "Urgency"
        case .stool: return "Stool"
        case .bloating: return "Bloating"
        case .nausea: return "Nausea"
        }
    }
}

