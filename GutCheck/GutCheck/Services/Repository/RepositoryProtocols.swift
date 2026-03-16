//
//  RepositoryProtocols.swift
//  GutCheck
//
//  Concrete, non-generic protocols for each repository type.
//  These enable dependency injection in ViewModels without
//  the associatedtype constraint of the generic FirebaseRepository protocol.
//

import Foundation

// MARK: - MealRepositoryProtocol

@MainActor
protocol MealRepositoryProtocol {
    func save(_ item: Meal) async throws
    func fetch(id: String) async throws -> Meal?
    func delete(id: String) async throws
    func fetchMealsForDate(_ date: Date, userId: String) async throws -> [Meal]
    func fetchRecentMeals(userId: String, limit: Int) async throws -> [Meal]
    func fetchMealsForDateRange(startDate: Date, endDate: Date, userId: String) async throws -> [Meal]
}

// MARK: - SymptomRepositoryProtocol

@MainActor
protocol SymptomRepositoryProtocol {
    func save(_ item: Symptom) async throws
    func fetch(id: String) async throws -> Symptom?
    func delete(id: String) async throws
    func getSymptoms(for date: Date) async throws -> [Symptom]
    func fetchSymptomsForDate(_ date: Date, userId: String) async throws -> [Symptom]
    func fetchRecentSymptoms(userId: String, limit: Int) async throws -> [Symptom]
    func fetchSymptomsForDateRange(startDate: Date, endDate: Date, userId: String) async throws -> [Symptom]
}

// MARK: - MedicationRepositoryProtocol

@MainActor
protocol MedicationRepositoryProtocol {
    func save(_ item: MedicationRecord) async throws
    func fetch(id: String) async throws -> MedicationRecord?
    func delete(id: String) async throws
    func fetchActiveMedications(userId: String) async throws -> [MedicationRecord]
    func fetchAllMedications(userId: String) async throws -> [MedicationRecord]
}

// MARK: - MedicationDoseRepositoryProtocol

@MainActor
protocol MedicationDoseRepositoryProtocol {
    func save(_ item: MedicationDoseLog) async throws
    func fetch(id: String) async throws -> MedicationDoseLog?
    func delete(id: String) async throws
    func fetchDosesForDate(_ date: Date, userId: String) async throws -> [MedicationDoseLog]
    func fetchRecentDoses(userId: String, limit: Int) async throws -> [MedicationDoseLog]
}
