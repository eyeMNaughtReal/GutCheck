//
//  CalendarView.swift
//  GutCheck
//
//  Created by Mark Conley on 7/12/25.
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
        ZStack(alignment: .bottomTrailing) {
            VStack {
                WeekSelector(selectedDate: $viewModel.selectedDate) { date in
                    viewModel.selectedDate = date
                }
                .padding(.vertical)

                ScrollView {
                    CalendarContentView(
                        selectedTab: selectedTab,
                        viewModel: viewModel
                    )
                    .padding(.bottom, 80)
                }
            }
            
            // Floating Action Button for logging
            if selectedTab == .meals || selectedTab == .symptoms {
                Button(action: {
                    if selectedTab == .meals {
                        router.startMealLogging()
                    } else if selectedTab == .symptoms {
                        router.startSymptomLogging()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: selectedTab == .meals ? "plus.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 20))
                        
                        Text("Log \(selectedTab == .meals ? "Meal" : "Symptom")")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(selectedTab == .meals ? ColorTheme.primary : ColorTheme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(24)
                    .shadow(color: ColorTheme.shadowColor.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding(.trailing, 16)
                .padding(.bottom, 100) // Position above the tab bar
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                ProfileAvatarButton(user: authService.currentUser) {
                    router.showProfile()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showLogOptions()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(ColorTheme.primary)
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
    
    private func showLogOptions() {
        // Create an ActionSheet or Menu to select between logging a meal or symptom
        // For iOS 16+, we can use a confirmation dialog
        #if canImport(UIKit)
        let alertController = UIAlertController(
            title: "Log an Entry",
            message: "What would you like to log?",
            preferredStyle: .actionSheet
        )
        
        alertController.addAction(UIAlertAction(title: "Log Meal", style: .default) { _ in
            router.startMealLogging()
        })
        
        alertController.addAction(UIAlertAction(title: "Log Symptom", style: .default) { _ in
            router.startSymptomLogging()
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(alertController, animated: true)
        }
        #endif
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
        VStack(alignment: .leading, spacing: 24) {
            if selectedTab == .meals || selectedTab == nil {
                Section(header: Text("Meals on \(viewModel.formattedDate)")
                    .font(.headline)
                    .padding(.horizontal)) {
                    if viewModel.isLoadingMeals {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 100)
                    } else if viewModel.meals.isEmpty {
                        Text("No meals logged for this date")
                            .foregroundColor(ColorTheme.secondaryText)
                            .frame(maxWidth: .infinity, minHeight: 60)
                    } else {
                        ForEach(viewModel.meals) { meal in
                            MealCalendarRow(meal: meal) {
                                router.viewMealDetails(id: meal.id)
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            if selectedTab == .symptoms || selectedTab == nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Symptoms on \(viewModel.formattedDate)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.isLoadingSymptoms {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 100)
                    } else if viewModel.symptoms.isEmpty {
                        Text("No symptoms logged for this date")
                            .foregroundColor(ColorTheme.secondaryText)
                            .frame(maxWidth: .infinity, minHeight: 60)
                    } else {
                        ForEach(viewModel.symptoms) { symptom in
                            SymptomCalendarRow(symptom: symptom) {
                                // Navigate to symptom detail
                                router.navigateTo(.symptomDetail(symptom.id))
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
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
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(meal.type.rawValue.capitalized)
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    Spacer()
                    Text(formattedTime)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                if !meal.foodItems.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(Array(meal.foodItems.enumerated()), id: \.offset) { idx, item in
                            Button(action: {
                                router.navigateTo(.mealDetail(item.id))
                            }) {
                                Text(item.name)
                                    .font(.caption)
                                    .foregroundColor(ColorTheme.secondaryText)
                                    .underline()
                            }
                        }
                    }
                }
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .cornerRadius(12)
            .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
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
    
    private var typeColor: Color {
        switch meal.type {
        case .breakfast: return .orange
        case .lunch: return .green
        case .dinner: return .blue
        case .snack: return .purple
        case .drink: return .cyan
        }
    }
}

// MARK: - Symptom Row
struct SymptomCalendarRow: View {
    let symptom: Symptom
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Stool: \(symptom.stoolType.rawValue)")
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    Spacer()
                    Text(formattedTime)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                HStack(spacing: 8) {
                    Text("Pain: \(symptom.painLevel.rawValue)")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text("Urgency: \(symptom.urgencyLevel.rawValue)")
                        .font(.caption)
                        .foregroundColor(.orange)
                    if let notes = symptom.notes {
                        Text(notes)
                            .font(.caption2)
                            .foregroundColor(ColorTheme.secondaryText)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .cornerRadius(12)
            .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var formattedTime: String {
        symptom.date.formattedTime
    }
}

// MARK: - Preview
#Preview {
    CalendarView(selectedTab: Tab.meals)
        .environmentObject(AppRouter())
        .environmentObject(AuthService())
}
