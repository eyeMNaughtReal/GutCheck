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
            List {
                CalendarContentView(
                    selectedTab: selectedTab,
                    viewModel: viewModel
                )
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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
            
            // Add button based on selected tab
            if selectedTab == .meals || selectedTab == .symptoms {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HapticManager.shared.medium()
                        if selectedTab == .meals {
                            router.startMealLogging()
                        } else {
                            router.startSymptomLogging()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibleButton(
                        label: "Add \(selectedTab == .meals ? "Meal" : "Symptom")",
                        hint: "Tap to log a new \(selectedTab == .meals ? "meal" : "symptom")"
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

// Extracted subview to help compiler
struct CalendarContentView: View {
    let selectedTab: Tab?
    @ObservedObject var viewModel: CalendarViewModel
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        Group {
            if selectedTab == .meals || selectedTab == nil {
                // Meals Section
                VStack(alignment: .leading, spacing: 0) {
                    // Section Header
                    Text("Meals")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 12)
                    
                    if viewModel.isLoadingMeals {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .accessibilityLabel("Loading meals")
                    } else if viewModel.meals.isEmpty {
                        EmptyStateCard(
                            icon: "fork.knife",
                            title: "No meals logged",
                            message: "Tap the + button to log a meal"
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(Array(viewModel.meals.enumerated()), id: \.element.id) { index, meal in
                                MealCalendarRow(meal: meal) {
                                    HapticManager.shared.light()
                                    router.viewMealDetails(id: meal.id)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemGroupedBackground))
                                )
                                .accessibilityIdentifier(AccessibilityIdentifiers.Calendar.mealItem(index))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HapticManager.shared.warning()
                                        Task {
                                            await viewModel.deleteMeal(meal.id)
                                        }
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
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            
            if selectedTab == .symptoms || selectedTab == nil {
                // Symptoms Section
                VStack(alignment: .leading, spacing: 0) {
                    // Section Header
                    Text("Symptoms")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 12)
                    
                    if viewModel.isLoadingSymptoms {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 100)
                            .accessibilityLabel("Loading symptoms")
                    } else if viewModel.symptoms.isEmpty {
                        EmptyStateCard(
                            icon: "heart.text.square",
                            title: "No symptoms logged",
                            message: "Tap the + button to log a symptom"
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(Array(viewModel.symptoms.enumerated()), id: \.element.id) { index, symptom in
                                SymptomCalendarRow(symptom: symptom) {
                                    HapticManager.shared.light()
                                    router.viewSymptomDetails(id: symptom.id)
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.secondarySystemGroupedBackground))
                                )
                                .accessibilityIdentifier(AccessibilityIdentifiers.Calendar.symptomItem(index))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        HapticManager.shared.warning()
                                        Task {
                                            await viewModel.deleteSymptom(symptom.id)
                                        }
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
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
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

// MARK: - Preview
#Preview {
    CalendarView(selectedTab: Tab.meals)
        .environmentObject(AppRouter())
        .environmentObject(AuthService())
}
