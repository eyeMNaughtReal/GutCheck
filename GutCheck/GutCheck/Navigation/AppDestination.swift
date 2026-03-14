//
//  AppDestination.swift
//  GutCheck
//
//  Main navigation destinations for the app.
//

import Foundation

// Main navigation destinations (used by AppRoot tab NavigationStacks)
enum AppDestination: Hashable {
    case dashboard
    case calendar(Date)
    case mealDetail(String? = nil) // nil for new meal, String ID for existing
    case symptomDetail(String? = nil) // nil for new symptom, String ID for existing
    case settings
    case analytics
    case symptomHistory(Symptom)
    case medicationList
}
