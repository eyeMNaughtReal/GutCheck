//
//  CalendarView.swift
//  GutCheck
//
//  Created by Mark Conley on 7/12/25.
//  Updated with Phase 2 Accessibility - February 23, 2026
//

import SwiftUI
import FirebaseAuth
#if canImport(UIKit)
import UIKit
#endif



// Using shared Tab enum from Core models
import Foundation // Required for Tab enum

struct CalendarView: View {
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var refreshManager: RefreshManager
    @StateObject private var viewModel = CalendarViewModel()
    @State private var isShowingActionMenu = false
    @State private var showNutritionDetail = false

    let selectedTab: Tab?
    let selectedDate: Date?

    init(selectedTab: Tab? = nil, selectedDate: Date? = nil) {
        self.selectedTab = selectedTab
        self.selectedDate = selectedDate
    }

    var body: some View {
        VStack(spacing: 0) {
            // Week Selector
            WeekSelector(selectedDate: $viewModel.selectedDate) { date in
                viewModel.selectedDate = date
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            
            // Content List
            // Each meal/symptom card is its own List row so .swipeActions aligns correctly.
            List {
                if selectedTab == .meals || selectedTab == nil {
                    // ── Meals static header (nutrition card + log button + title) ──
                    CalendarMealsSectionHeader(viewModel: viewModel) {
                        showNutritionDetail = true
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                    // ── Individual meal rows (one List row each → swipeActions align) ──
                    if viewModel.isLoadingMeals {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .accessibilityLabel("Loading meals")
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    } else if viewModel.meals.isEmpty {
                        EmptyStateCard(
                            icon: "fork.knife",
                            title: "No meals logged",
                            message: "Tap Log Meal above to get started"
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(Array(viewModel.meals.enumerated()), id: \.element.id) { index, meal in
                            MealCalendarRow(meal: meal) {
                                HapticManager.shared.light()
                                router.viewMealDetails(id: meal.id)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .accessibilityIdentifier(AccessibilityIdentifiers.Calendar.mealItem(index))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.shared.warning()
                                    Task { await viewModel.deleteMeal(meal.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    HapticManager.shared.light()
                                    router.editMeal(id: meal.id)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        // Bottom breathing room after last meal card
                        Color.clear.frame(height: 16)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }

                if selectedTab == .symptoms || selectedTab == nil {
                    // ── Symptoms static header ──
                    CalendarSymptomsSectionHeader()
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    // ── Individual symptom rows ──
                    if viewModel.isLoadingSymptoms {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .accessibilityLabel("Loading symptoms")
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    } else if viewModel.symptoms.isEmpty {
                        EmptyStateCard(
                            icon: "heart.text.square",
                            title: "No symptoms logged",
                            message: "Tap the + button to log a symptom"
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(Array(viewModel.symptoms.enumerated()), id: \.element.id) { index, symptom in
                            SymptomCalendarRow(symptom: symptom) {
                                HapticManager.shared.light()
                                router.viewSymptomDetails(id: symptom.id)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .accessibilityIdentifier(AccessibilityIdentifiers.Calendar.symptomItem(index))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.shared.warning()
                                    Task { await viewModel.deleteSymptom(symptom.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    HapticManager.shared.light()
                                    router.editSymptom(id: symptom.id)
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        Color.clear.frame(height: 16)
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .sheet(isPresented: $showNutritionDetail) {
                DailyNutritionDetailView(
                    nutrition: viewModel.dailyNutrition,
                    details: viewModel.dailyNutritionDetails,
                    date: viewModel.selectedDate
                )
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ProfileAvatarButton(user: authService.currentUser) {
                    router.showProfile()
                }
            }
            
            // Symptom tab keeps its toolbar + button; meals tab uses inline Log Meal button
            if selectedTab == .symptoms {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HapticManager.shared.medium()
                        router.startSymptomLogging()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibleButton(
                        label: "Add Symptom",
                        hint: "Tap to log a new symptom"
                    )
                    .accessibilityIdentifier(AccessibilityIdentifiers.Calendar.floatingActionButton)
                }
            }
        }
        .onAppear {
            print("📱 CalendarView: onAppear")
            if let date = selectedDate {
                viewModel.setDate(date)
            }
            viewModel.loadMeals()
            viewModel.loadSymptoms()
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
            print("📅 CalendarView: Date changed to \(viewModel.selectedDate)")
            viewModel.loadMeals()
            viewModel.loadSymptoms()
        }
        .onChange(of: refreshManager.refreshToken) { _, _ in
            print("🔄 CalendarView: Refresh triggered by RefreshManager")
            viewModel.loadMeals()
            viewModel.loadSymptoms()
        }
        .refreshable {
            print("🔄 CalendarView: Manual refresh triggered")
            viewModel.loadMeals()
            viewModel.loadSymptoms()
        }
    }
    
    private var title: String {
        switch selectedTab {
        case .meals: return "Meals"
        case .symptoms: return "Symptoms"
        default: return "Calendar"
        }
    }
}

// MARK: - Meals Section Header
// Static header for the meals section: DailyNutritionCard + Log Meal button + section title.
// Kept as a separate view to reduce compiler complexity in CalendarView.
struct CalendarMealsSectionHeader: View {
    @ObservedObject var viewModel: CalendarViewModel
    @EnvironmentObject var router: AppRouter
    let onNutritionTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Daily Nutrition Summary Card
            DailyNutritionCard(
                nutrition: viewModel.dailyNutrition,
                mealCount: viewModel.meals.count,
                onTap: onNutritionTap
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Log Meal inline button
            Button {
                HapticManager.shared.medium()
                router.startMealLogging()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Meal")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .accessibleButton(label: "Log Meal", hint: "Tap to log a new meal")

            // Section header label
            Text("Meals")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
    }
}

// MARK: - Symptoms Section Header
struct CalendarSymptomsSectionHeader: View {
    var body: some View {
        Text("Symptoms")
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - ViewModel
class CalendarViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var meals: [Meal] = []
    @Published var symptoms: [Symptom] = []
    @Published var isLoadingMeals = false
    @Published var isLoadingSymptoms = false
    @Published var calendarDays: [CalendarDay] = []
    

    
    // Computed property for formatted date string
    var formattedDate: String {
        selectedDate.formattedDate
    }

    // Daily nutrition totals — aggregated across every food item in every meal
    var dailyNutrition: NutritionInfo {
        var cal = 0
        var protein = 0.0; var carbs = 0.0; var fat = 0.0
        var fiber = 0.0;   var sugar = 0.0; var sodium = 0.0
        for meal in meals {
            for item in meal.foodItems {
                cal     += item.nutrition.calories ?? 0
                protein += item.nutrition.protein  ?? 0
                carbs   += item.nutrition.carbs    ?? 0
                fat     += item.nutrition.fat      ?? 0
                fiber   += item.nutrition.fiber    ?? 0
                sugar   += item.nutrition.sugar    ?? 0
                sodium  += item.nutrition.sodium   ?? 0
            }
        }
        return NutritionInfo(
            calories: cal     > 0 ? cal     : nil,
            protein:  protein > 0 ? protein : nil,
            carbs:    carbs   > 0 ? carbs   : nil,
            fat:      fat     > 0 ? fat     : nil,
            fiber:    fiber   > 0 ? fiber   : nil,
            sugar:    sugar   > 0 ? sugar   : nil,
            sodium:   sodium  > 0 ? sodium  : nil
        )
    }

    // Additional micronutrients from FoodItem.nutritionDetails (Vitamins, Minerals, etc.)
    var dailyNutritionDetails: [String: Double] {
        var details: [String: Double] = [:]
        for meal in meals {
            for item in meal.foodItems {
                for (key, value) in item.nutritionDetails {
                    let numStr = value.filter { $0.isNumber || $0 == "." }
                    if let num = Double(numStr), num > 0 {
                        details[key] = (details[key] ?? 0) + num
                    }
                }
            }
        }
        return details
    }

    // Public method to load meals from Firebase
    func loadMeals() {
        isLoadingMeals = true
        print("📅 CalendarView: Loading meals for date: \(selectedDate)")
        Task {
            do {
                guard let userId = AuthenticationManager.shared.currentUserId else {
                    print("❌ CalendarView: No authenticated user for meals")
                    await MainActor.run {
                        self.meals = []
                        self.isLoadingMeals = false
                    }
                    return
                }
                let loadedMeals = try await MealRepository.shared.fetchMealsForDate(selectedDate, userId: userId)
                print("🍽️ CalendarView: Loaded \(loadedMeals.count) meals from Firebase")
                await MainActor.run {
                    self.meals = loadedMeals
                    self.isLoadingMeals = false
                                    print("🍽️ CalendarView: Updated UI with \(self.meals.count) meals")
                }
            } catch {
                print("❌ CalendarView: Error loading meals: \(error)")
                await MainActor.run {
                    self.meals = []
                    self.isLoadingMeals = false
                }
            }
        }
    }

    // Public method to load symptoms from Firebase
    func loadSymptoms() {
        isLoadingSymptoms = true
        print("📅 CalendarView: Loading symptoms for date: \(selectedDate)")
        Task {
            do {
                let loadedSymptoms = try await SymptomRepository.shared.getSymptoms(for: selectedDate)
                print("📊 CalendarView: Loaded \(loadedSymptoms.count) symptoms from Firebase")
                await MainActor.run {
                    self.symptoms = loadedSymptoms
                    self.isLoadingSymptoms = false
                    print("📊 CalendarView: Updated UI with \(self.symptoms.count) symptoms")
                }
            } catch {
                print("❌ CalendarView: Error loading symptoms: \(error)")
                await MainActor.run {
                    self.symptoms = []
                    self.isLoadingSymptoms = false
                }
            }
        }
    }
    
    // Method expected by UnifiedCalendarView
    func loadCalendarData(for date: Date) async {
        await MainActor.run {
            self.selectedDate = date
            self.loadMeals()
            self.loadSymptoms()
            self.generateCalendarDays(for: date)
        }
    }
    
    // Delete a meal
    func deleteMeal(_ mealId: String) async {
        do {
            try await MealRepository.shared.delete(id: mealId)
            await MainActor.run {
                self.meals.removeAll { $0.id == mealId }
                AccessibilityAnnouncement.announce("Meal deleted")
            }
        } catch {
            print("❌ Error deleting meal: \(error)")
            await MainActor.run {
                AccessibilityAnnouncement.announce("Failed to delete meal")
            }
        }
    }
    
    // Delete a symptom
    func deleteSymptom(_ symptomId: String) async {
        do {
            try await SymptomRepository.shared.delete(id: symptomId)
            await MainActor.run {
                self.symptoms.removeAll { $0.id == symptomId }
                AccessibilityAnnouncement.announce("Symptom deleted")
            }
        } catch {
            print("❌ Error deleting symptom: \(error)")
            await MainActor.run {
                AccessibilityAnnouncement.announce("Failed to delete symptom")
            }
        }
    }
    
    // Set the selected date
    func setDate(_ date: Date) {
        selectedDate = date
    }
    
    // Generate calendar days for the month view
    private func generateCalendarDays(for date: Date) {
        let calendar = Calendar.current
        guard let monthRange = calendar.range(of: .day, in: .month, for: date) else { return }
        
        var days: [CalendarDay] = []
        for day in 1...monthRange.count {
            var components = calendar.dateComponents([.year, .month], from: date)
            components.day = day
            
            guard let dayDate = calendar.date(from: components) else { continue }
            
            // Check if we have meal or symptom data for this day
            let hasMealsData = calendar.isDate(dayDate, inSameDayAs: selectedDate) && !meals.isEmpty
            let hasSymptomsData = calendar.isDate(dayDate, inSameDayAs: selectedDate) && !symptoms.isEmpty
            
            var entryTypes: Set<CalendarDay.EntryType> = []
            if hasMealsData {
                entryTypes.insert(.meals)
            }
            if hasSymptomsData {
                entryTypes.insert(.symptom)
            }
            if hasMealsData && hasSymptomsData {
                entryTypes.insert(.both)
            }
            
            let calendarDay = CalendarDay(
                date: dayDate,
                isCurrentMonth: true,
                hasEntries: hasMealsData || hasSymptomsData,
                entryTypes: entryTypes
            )
            
            days.append(calendarDay)
        }
        
        calendarDays = days
    }
    

}

// MARK: - Meal Row
struct MealCalendarRow: View {
    let meal: Meal
    let onTap: () -> Void
    @State private var isNavigating = false
    
    var body: some View {
        Button(action: {
            guard !isNavigating else { return }
            isNavigating = true
            
            // Debounce the navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNavigating = false
            }
            
            onTap()
        }) {
            HStack(spacing: 16) {
                // Icon Circle
                ZStack {
                    Circle()
                        .fill(mealIconColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: mealIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(mealIconColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(meal.type.rawValue.capitalized)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(formattedTime)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    
                    if !meal.foodItems.isEmpty {
                        Text(foodItemsPreview)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.3))
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isNavigating)
    }
    
    private var mealIcon: String {
        switch meal.type {
        case .breakfast:
            return "sunrise.fill"
        case .lunch:
            return "fork.knife"
        case .dinner:
            return "moon.stars.fill"
        case .snack:
            return "leaf.fill"
        case .drink:
            return "cup.and.saucer.fill"
        }
    }
    
    private var mealIconColor: Color {
        switch meal.type {
        case .breakfast:
            return .orange
        case .lunch:
            return .blue
        case .dinner:
            return .purple
        case .snack:
            return .green
        case .drink:
            return .cyan
        }
    }
    
    private var formattedTime: String {
        meal.date.formattedTime
    }
    
    private var foodItemsPreview: String {
        let names = meal.foodItems.prefix(3).map { $0.name }
        let preview = names.joined(separator: ", ")
        if meal.foodItems.count > 3 {
            return preview + ", ..."
        }
        return preview
    }
}

// MARK: - Symptom Row
struct SymptomCalendarRow: View {
    let symptom: Symptom
    let onTap: () -> Void
    @State private var isNavigating = false
    
    var body: some View {
        Button(action: {
            guard !isNavigating else { return }
            isNavigating = true
            
            // Debounce the navigation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNavigating = false
            }
            
            onTap()
        }) {
            HStack(spacing: 16) {
                // Icon Circle
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.red)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Type \(symptom.stoolType.rawValue)")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(formattedTime)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 6) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                            Text(painLevelText)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.orange)
                            Text(urgencyLevelText)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let notes = symptom.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.3))
            }
            .padding(16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isNavigating)
    }
    
    private var formattedTime: String {
        symptom.date.formattedTime
    }
    
    private var painLevelText: String {
        switch symptom.painLevel {
        case .none: return "None"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }
    
    private var urgencyLevelText: String {
        switch symptom.urgencyLevel {
        case .none: return "None"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .urgent: return "Urgent"
        }
    }
}

// MARK: - Daily Nutrition Card

struct DailyNutritionCard: View {
    let nutrition: NutritionInfo
    let mealCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                HStack {
                    Text("Daily Nutrition")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    if mealCount > 0 {
                        Text("See details")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }

                if mealCount == 0 {
                    Text("Log a meal to see your daily nutrition totals.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    // Calorie count — prominent
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(nutrition.calories ?? 0)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("kcal")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(mealCount) meal\(mealCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // P / C / F pills
                    HStack(spacing: 8) {
                        MacroPill(label: "P", value: nutrition.protein, color: .blue)
                        MacroPill(label: "C", value: nutrition.carbs,   color: .green)
                        MacroPill(label: "F", value: nutrition.fat,     color: .red)
                        if let fiber = nutrition.fiber, fiber > 0 {
                            MacroPill(label: "Fiber", value: fiber, color: .orange)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(mealCount == 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(mealCount == 0
            ? "Daily nutrition — no meals logged"
            : "Daily nutrition: \(nutrition.calories ?? 0) calories. Tap to see full breakdown."
        )
    }
}

private struct MacroPill: View {
    let label: String
    let value: Double?
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Text(label)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(value.map { String(format: "%.1fg", $0) } ?? "--")
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .cornerRadius(8)
    }
}

// MARK: - Daily Nutrition Detail View

struct DailyNutritionDetailView: View {
    let nutrition: NutritionInfo
    let details: [String: Double]
    let date: Date
    @Environment(\.dismiss) private var dismiss

    // Known mineral keys stored in nutritionDetails
    private let mineralKeys = ["Sodium", "Potassium", "Calcium", "Iron",
                               "Magnesium", "Phosphorus", "Zinc", "Copper", "Manganese", "Selenium"]
    private let vitaminKeys = ["Vitamin A", "Vitamin C", "Vitamin D", "Vitamin E", "Vitamin K",
                               "Thiamin", "Riboflavin", "Niacin", "Vitamin B6", "Folate",
                               "Vitamin B12", "Biotin", "Pantothenic Acid"]
    private let fatKeys = ["Saturated Fat", "Trans Fat", "Polyunsaturated Fat", "Monounsaturated Fat",
                           "Cholesterol"]

    private var dateTitle: String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today's Nutrition" }
        if cal.isDateInYesterday(date) { return "Yesterday's Nutrition" }
        let f = DateFormatter()
        f.dateFormat = "MMMM d"
        return f.string(from: date)
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: Macronutrients
                Section(header: Text("Macronutrients")) {
                    NutritionDetailRow(label: "Calories",     value: nutrition.calories.map { Double($0) }, unit: "kcal",  color: .orange)
                    NutritionDetailRow(label: "Protein",      value: nutrition.protein,   unit: "g",    color: .blue)
                    NutritionDetailRow(label: "Carbohydrates",value: nutrition.carbs,     unit: "g",    color: .green)
                    NutritionDetailRow(label: "Total Fat",    value: nutrition.fat,       unit: "g",    color: .red)
                    NutritionDetailRow(label: "Fiber",        value: nutrition.fiber,     unit: "g",    color: .orange)
                    NutritionDetailRow(label: "Sugar",        value: nutrition.sugar,     unit: "g",    color: .pink)
                    NutritionDetailRow(label: "Sodium",       value: nutrition.sodium,    unit: "mg",   color: .yellow)
                }

                // MARK: Fats (if any detail data present)
                let fatData = fatKeys.compactMap { key -> (String, Double)? in
                    guard let v = details[key] else { return nil }
                    return (key, v)
                }
                if !fatData.isEmpty {
                    Section(header: Text("Fats")) {
                        ForEach(fatData, id: \.0) { key, value in
                            NutritionDetailRow(label: key, value: value,
                                               unit: key == "Cholesterol" ? "mg" : "g",
                                               color: .red)
                        }
                    }
                }

                // MARK: Minerals
                let mineralData = mineralKeys.compactMap { key -> (String, Double)? in
                    guard let v = details[key] else { return nil }
                    return (key, v)
                }
                if !mineralData.isEmpty {
                    Section(header: Text("Minerals")) {
                        ForEach(mineralData, id: \.0) { key, value in
                            NutritionDetailRow(label: key, value: value, unit: "mg", color: .teal)
                        }
                    }
                }

                // MARK: Vitamins
                let vitaminData = vitaminKeys.compactMap { key -> (String, Double)? in
                    guard let v = details[key] else { return nil }
                    return (key, v)
                }
                if !vitaminData.isEmpty {
                    Section(header: Text("Vitamins")) {
                        ForEach(vitaminData, id: \.0) { key, value in
                            NutritionDetailRow(label: key, value: value, unit: "mg", color: .purple)
                        }
                    }
                }

                // MARK: Other tracked nutrients (anything not in above lists)
                let knownKeys = Set(mineralKeys + vitaminKeys + fatKeys)
                let otherData = details.filter { !knownKeys.contains($0.key) }.sorted { $0.key < $1.key }
                if !otherData.isEmpty {
                    Section(header: Text("Other Nutrients")) {
                        ForEach(otherData, id: \.key) { key, value in
                            NutritionDetailRow(label: key, value: value, unit: "", color: .gray)
                        }
                    }
                }

                if nutrition.calories == nil && details.isEmpty {
                    Section {
                        Text("No nutrition data for this day. Log a meal to see your breakdown.")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle(dateTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct NutritionDetailRow: View {
    let label: String
    let value: Double?
    let unit: String
    let color: Color

    private var formattedValue: String {
        guard let v = value else { return "—" }
        if unit == "kcal" || unit == "mg" {
            return "\(Int(v)) \(unit)"
        }
        return String(format: "%.1f %@", v, unit)
    }

    var body: some View {
        HStack {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.primary)
            Spacer()
            Text(formattedValue)
                .foregroundColor(value != nil ? .primary : .secondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(formattedValue)")
    }
}

// MARK: - Preview
#Preview {
    CalendarView(selectedTab: Tab.meals)
        .environmentObject(AppRouter())
        .environmentObject(AuthService())
}
