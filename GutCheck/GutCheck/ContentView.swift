//
//  ContentView.swift
//  GutCheck
//
//  Updated ContentView with meal logging and viewing functionality
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack(path: navigationCoordinator.currentNavigationPath) {
                Group {
                    switch navigationCoordinator.selectedTab {
                    case .home:
                        DashboardView()
                    case .meal:
                        MealCalendarView()
                    case .symptoms:
                        LogSymptomView() // Temporary placeholder instead of SymptomCalendarView
                    case .insights:
                        InsightsView()
                    case .plus:
                        DashboardView() // Plus button shows actions, doesn't navigate
                    }
                }
                .navigationDestination(for: NavigationCoordinator.Destination.self) { destination in
                    destinationView(for: destination)
                }
                .sheet(isPresented: $navigationCoordinator.isShowingProfile) {
                    if let currentUser = authService.currentUser {
                        UserProfileView(user: currentUser)
                    }
                }
                .sheet(isPresented: $navigationCoordinator.isShowingSettings) {
                    SettingsView()
                }
            }
            
            CustomTabBar(selectedTab: $navigationCoordinator.selectedTab) { action in
                handleTabBarAction(action)
            }
        }
        .environmentObject(navigationCoordinator)
        .background(ColorTheme.background.ignoresSafeArea())
        .sheet(isPresented: $navigationCoordinator.isShowingMealLoggingOptions) {
            MealLoggingOptionsView()
                .environmentObject(navigationCoordinator)
        }
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationCoordinator.Destination) -> some View {
        switch destination {
        case .profile(let user):
            UserProfileView(user: user)
        case .settings:
            SettingsView()
        case .mealDetail(let meal):
            MealDetailView(meal: meal)
        case .symptomDetail(let symptom):
            Text("Symptom Details") // Placeholder for SymptomDetailView
        case .logMeal:
            // This now goes to options view as a sheet instead
            EmptyView()
        case .logSymptom:
            LogSymptomView()
        case .calendar(let date):
            CalendarView(selectedDate: date)
        case .insights:
            InsightsView()
        case .userReminders:
            UserRemindersView()
        }
    }
    
    private func handleTabBarAction(_ action: TabBarAction) {
        switch action {
        case .logMeal:
            // Show meal logging options as a sheet
            navigationCoordinator.isShowingMealLoggingOptions = true
        case .logSymptom:
            navigationCoordinator.navigateTo(.logSymptom)
        }
    }
}

// MARK: - Tab Bar Actions
enum TabBarAction {
    case logMeal
    case logSymptom
}

// MARK: - Placeholder Views (to be implemented)
struct MealCalendarView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @StateObject private var viewModel = MealCalendarViewModel()
    
    var body: some View {
        VStack {
            // Calendar view
            DatePicker("Select Date", selection: $viewModel.selectedDate, displayedComponents: [.date])
                .datePickerStyle(.graphical)
                .padding()
            
            // Meals for selected date
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Meals on \(viewModel.formattedDate)")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if viewModel.meals.isEmpty {
                        Text("No meals logged for this date")
                            .foregroundColor(ColorTheme.secondaryText)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        ForEach(viewModel.meals) { meal in
                            MealCalendarRow(meal: meal) {
                                navigationCoordinator.navigateTo(.mealDetail(meal))
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("Meals")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ProfileAvatarButton {
                    navigationCoordinator.isShowingProfile = true
                }
            }
        }
        .onAppear {
            viewModel.loadMeals()
        }
        .onChange(of: viewModel.selectedDate) { oldDate, newDate in
            viewModel.loadMeals()
        }
    }
}

struct MealCalendarRow: View {
    let meal: Meal
    let onTap: () -> Void
    
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
                
                // Food items preview
                if !meal.foodItems.isEmpty {
                    Text(foodItemsPreview)
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .lineLimit(1)
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
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: meal.date)
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
        case .breakfast:
            return .orange
        case .lunch:
            return .green
        case .dinner:
            return .blue
        case .snack:
            return .purple
        case .drink:
            return .cyan
        }
    }
}

// MARK: - MealCalendarViewModel
class MealCalendarViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var meals: [Meal] = []
    @Published var isLoading = false
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: selectedDate)
    }
    
    func loadMeals() {
        isLoading = true
        
        // In a real app, this would load from Firestore
        // For now, we'll create mock data with a delay
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Generate mock meals for the selected date
            self.meals = self.generateMockMeals(for: self.selectedDate)
            self.isLoading = false
        }
    }
    
    private func generateMockMeals(for date: Date) -> [Meal] {
        // Create 0-3 random meals for this date
        let count = Int.random(in: 0...3)
        var meals: [Meal] = []
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        for i in 0..<count {
            // Create meal times based on type
            var mealType: MealType
            var hour: Int
            
            switch i {
            case 0:
                mealType = .breakfast
                hour = 8
            case 1:
                mealType = .lunch
                hour = 12
            case 2:
                mealType = .dinner
                hour = 18
            default:
                mealType = .snack
                hour = 15
            }
            
            // Create date with time component
            var dateComponents = components
            dateComponents.hour = hour
            dateComponents.minute = Int.random(in: 0...59)
            
            let mealDate = calendar.date(from: dateComponents) ?? date
            
            // Create meal
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
        
        // Sort by time
        return meals.sorted { $0.date < $1.date }
    }
    
    private func getMealName(for type: MealType) -> String {
        switch type {
        case .breakfast:
            return ["Morning Breakfast", "Quick Breakfast", "Healthy Start"].randomElement()!
        case .lunch:
            return ["Lunch Break", "Midday Meal", "Quick Lunch"].randomElement()!
        case .dinner:
            return ["Evening Dinner", "Family Dinner", "Light Dinner"].randomElement()!
        case .snack:
            return ["Afternoon Snack", "Quick Bite", "Protein Snack"].randomElement()!
        case .drink:
            return ["Coffee Break", "Afternoon Tea", "Protein Shake"].randomElement()!
        }
    }
    
    private func generateMockFoodItems(for mealType: MealType) -> [FoodItem] {
        var items: [FoodItem] = []
        let count = Int.random(in: 1...3)
        
        // Breakfast items
        let breakfastOptions = [
            ("Oatmeal", "1 cup", 240.0, 158, 6.0, 27.0, 3.0),
            ("Banana", "1 medium", 118.0, 105, 1.3, 27.0, 0.4),
            ("Toast", "2 slices", 60.0, 170, 4.0, 30.0, 2.0),
            ("Eggs", "2 large", 100.0, 140, 12.0, 1.0, 10.0),
            ("Coffee", "8 oz", 240.0, 5, 0.0, 0.0, 0.0)
        ]
        
        // Lunch/Dinner items
        let mainMealOptions = [
            ("Chicken Breast", "6 oz", 170.0, 280, 54.0, 0.0, 6.0),
            ("Rice", "1 cup", 200.0, 205, 4.0, 45.0, 0.5),
            ("Salad", "2 cups", 100.0, 30, 2.0, 6.0, 0.0),
            ("Pasta", "1 cup", 200.0, 220, 8.0, 43.0, 1.0),
            ("Sandwich", "1 whole", 250.0, 350, 15.0, 40.0, 12.0)
        ]
        
        // Snack items
        let snackOptions = [
            ("Apple", "1 medium", 182.0, 95, 0.5, 25.0, 0.3),
            ("Yogurt", "6 oz", 170.0, 120, 15.0, 15.0, 0.0),
            ("Almonds", "1 oz", 28.0, 160, 6.0, 6.0, 14.0),
            ("Protein Bar", "1 bar", 60.0, 200, 20.0, 15.0, 8.0),
            ("Chips", "1 oz", 28.0, 150, 2.0, 15.0, 10.0)
        ]
        
        // Drink items
        let drinkOptions = [
            ("Coffee", "12 oz", 355.0, 5, 0.0, 0.0, 0.0),
            ("Smoothie", "16 oz", 475.0, 250, 10.0, 45.0, 3.0),
            ("Tea", "8 oz", 240.0, 0, 0.0, 0.0, 0.0),
            ("Soda", "12 oz", 355.0, 150, 0.0, 39.0, 0.0),
            ("Water", "16 oz", 475.0, 0, 0.0, 0.0, 0.0)
        ]
        
        // Select options based on meal type
        let options: [(String, String, Double, Int, Double, Double, Double)]
        switch mealType {
        case .breakfast:
            options = breakfastOptions
        case .lunch, .dinner:
            options = mainMealOptions
        case .snack:
            options = snackOptions
        case .drink:
            options = drinkOptions
        }
        
        // Create food items
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

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
