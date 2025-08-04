//
//  CalendarView.swift
//  GutCheck
//
//  Created by Mark Conley on 7/12/25.
//

import SwiftUI

// Using shared Tab enum from Core models
import Foundation // Required for Tab enum
struct CalendarView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = CalendarViewModel()

    let selectedTab: Tab?
    let selectedDate: Date?

    init(selectedTab: Tab? = nil, selectedDate: Date? = nil) {
        self.selectedTab = selectedTab
        self.selectedDate = selectedDate
    }

    var body: some View {
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
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ProfileAvatarButton {
                    navigationCoordinator.isShowingProfile = true
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
        .refreshable {
            print("🔄 CalendarView: Manual refresh triggered")
            viewModel.loadMeals()
            viewModel.loadSymptoms()
        }
    }

// Extracted subview to help compiler
struct CalendarContentView: View {
    let selectedTab: Tab?
    @ObservedObject var viewModel: CalendarViewModel
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
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
                                navigationCoordinator.navigateTo(.mealDetail(meal))
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            if selectedTab == .symptoms || selectedTab == nil {
                Section(header: Text("Symptoms on \(viewModel.formattedDate)")
                    .font(.headline)
                    .padding(.horizontal)) {
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
                                // Ensure we are on the symptoms tab before navigating
                                navigationCoordinator.selectedTab = .symptoms
                                navigationCoordinator.navigateTo(.symptomDetail(symptom))
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
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

    // Public method to load meals (mock implementation)
    func loadMeals() {
        isLoadingMeals = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.meals = self.generateMockMeals(for: self.selectedDate)
            self.isLoadingMeals = false
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
            self.generateCalendarDays(for: date)
            self.loadMeals()
            self.loadSymptoms()
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
            
            // Mock some entry types for demonstration
            let hasEntries = Int.random(in: 1...10) > 7 // 30% chance of having entries
            let entryTypes: Set<CalendarDay.EntryType> = hasEntries ? 
                (Int.random(in: 1...3) == 1 ? [.meals] : 
                 Int.random(in: 1...3) == 2 ? [.symptom] : [.both]) : []
            
            let calendarDay = CalendarDay(
                date: dayDate,
                isCurrentMonth: true,
                hasEntries: hasEntries,
                entryTypes: entryTypes
            )
            days.append(calendarDay)
        }
        
        calendarDays = days
    }

    private func generateMockMeals(for date: Date) -> [Meal] {
        let count = Int.random(in: 0...3)
        var meals: [Meal] = []
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        for i in 0..<count {
            var mealType: MealType
            var hour: Int
            switch i {
            case 0: mealType = .breakfast; hour = 8
            case 1: mealType = .lunch; hour = 12
            case 2: mealType = .dinner; hour = 18
            default: mealType = .snack; hour = 15
            }
            var dateComponents = components
            dateComponents.hour = hour
            dateComponents.minute = Int.random(in: 0...59)
            let mealDate = calendar.date(from: dateComponents) ?? date
            let meal = Meal(
                name: getMealName(for: mealType),
                date: mealDate,
                type: mealType,
                source: .manual,
                foodItems: generateMockFoodItems(for: mealType),
                notes: i == 0 ? "This is a note for the meal" : nil,
                tags: ["mock", mealType.rawValue],
                createdBy: "testUser"
            )
            meals.append(meal)
        }
        return meals.sorted { $0.date < $1.date }
    }
    private func getMealName(for type: MealType) -> String {
        switch type {
        case .breakfast: return ["Morning Breakfast", "Quick Breakfast", "Healthy Start"].randomElement()!
        case .lunch: return ["Lunch Break", "Midday Meal", "Quick Lunch"].randomElement()!
        case .dinner: return ["Evening Dinner", "Family Dinner", "Light Dinner"].randomElement()!
        case .snack: return ["Afternoon Snack", "Quick Bite", "Protein Snack"].randomElement()!
        case .drink: return ["Coffee Break", "Afternoon Tea", "Protein Shake"].randomElement()!
        }
    }
    private func generateMockFoodItems(for mealType: MealType) -> [FoodItem] {
        var items: [FoodItem] = []
        let count = Int.random(in: 1...3)
        let breakfastOptions = [
            ("Oatmeal", "1 cup", 240.0, 158, 6.0, 27.0, 3.0),
            ("Banana", "1 medium", 118.0, 105, 1.3, 27.0, 0.4),
            ("Toast", "2 slices", 60.0, 170, 4.0, 30.0, 2.0),
            ("Eggs", "2 large", 100.0, 140, 12.0, 1.0, 10.0),
            ("Coffee", "8 oz", 240.0, 5, 0.0, 0.0, 0.0)
        ]
        let mainMealOptions = [
            ("Chicken Breast", "6 oz", 170.0, 280, 54.0, 0.0, 6.0),
            ("Rice", "1 cup", 200.0, 205, 4.0, 45.0, 0.5),
            ("Salad", "2 cups", 100.0, 30, 2.0, 6.0, 0.0),
            ("Pasta", "1 cup", 200.0, 220, 8.0, 43.0, 1.0),
            ("Sandwich", "1 whole", 250.0, 350, 15.0, 40.0, 12.0)
        ]
        let snackOptions = [
            ("Apple", "1 medium", 182.0, 95, 0.5, 25.0, 0.3),
            ("Yogurt", "6 oz", 170.0, 120, 15.0, 15.0, 0.0),
            ("Almonds", "1 oz", 28.0, 160, 6.0, 6.0, 14.0),
            ("Protein Bar", "1 bar", 60.0, 200, 20.0, 15.0, 8.0),
            ("Chips", "1 oz", 28.0, 150, 2.0, 15.0, 10.0)
        ]
        let drinkOptions = [
            ("Coffee", "12 oz", 355.0, 5, 0.0, 0.0, 0.0),
            ("Smoothie", "16 oz", 475.0, 250, 10.0, 45.0, 3.0),
            ("Tea", "8 oz", 240.0, 0, 0.0, 0.0, 0.0),
            ("Soda", "12 oz", 355.0, 150, 0.0, 39.0, 0.0),
            ("Water", "16 oz", 475.0, 0, 0.0, 0.0, 0.0)
        ]
        let options: [(String, String, Double, Int, Double, Double, Double)]
        switch mealType {
        case .breakfast: options = breakfastOptions
        case .lunch, .dinner: options = mainMealOptions
        case .snack: options = snackOptions
        case .drink: options = drinkOptions
        }
        for _ in 0..<count {
            let option = options.randomElement()!
            let foodItem = FoodItem(
                name: option.0,
                quantity: option.1,
                estimatedWeightInGrams: option.2,
                nutrition: NutritionInfo(
                    calories: option.3,
                    protein: option.4,
                    carbs: option.5,
                    fat: option.6
                )
            )
            items.append(foodItem)
        }
        return items
    }
}

// MARK: - Meal Row (reuse from previous)
struct MealCalendarRow: View {
    let meal: Meal
    let onTap: () -> Void
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(meal.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.primaryText)
                    Spacer()
                    Text(formattedTime)
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                Text(meal.type.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(typeColor.opacity(0.2))
                    .foregroundColor(typeColor)
                    .cornerRadius(8)
                if !meal.foodItems.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(meal.foodItems.indices, id: \.self) { idx in
                            let item = meal.foodItems[idx]
                            Button(action: {
                                navigationCoordinator.navigateTo(.foodDetail(item))
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
// ...existing code...
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
        .environmentObject(NavigationCoordinator())
        .environmentObject(AuthService())
}
