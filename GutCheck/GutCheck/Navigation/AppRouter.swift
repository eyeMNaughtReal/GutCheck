import SwiftUI

// Main navigation destinations
enum AppDestination: Hashable {
    case dashboard
    case calendar(Date)
    case mealDetail(String? = nil) // nil for new meal, String ID for existing
    case symptomDetail(String? = nil) // nil for new symptom, String ID for existing
    case settings
    case analytics
}

// Sheet presentations
enum SheetDestination: Identifiable {
    case profile
    case mealForm(String? = nil) // nil for new, ID for edit
    case symptomForm(String? = nil) // nil for new, ID for edit
    case logEntry // Entry point for choosing what to log
    
    var id: String {
        switch self {
        case .profile: return "profile"
        case .mealForm(let id): return "meal-\(id ?? "new")"
        case .symptomForm(let id): return "symptom-\(id ?? "new")"
        case .logEntry: return "log-entry"
        }
    }
}

// Detail sheet presentations
struct SymptomDetailSheet: Identifiable {
    let id: String
    let symptomId: String
    
    init(symptomId: String) {
        self.id = symptomId
        self.symptomId = symptomId
    }
}

struct MealDetailSheet: Identifiable {
    let id: String
    let mealId: String
    
    init(mealId: String) {
        self.id = mealId
        self.mealId = mealId
    }
}

@MainActor
class AppRouter: ObservableObject {
    static let shared = AppRouter()
    
    @Published var path = NavigationPath()
    @Published var activeSheet: SheetDestination?
    @Published var symptomDetailSheet: SymptomDetailSheet?
    @Published var mealDetailSheet: MealDetailSheet?
    @Published var selectedTab: Tab = .dashboard
    
    // Navigation methods
    func navigateTo(_ destination: AppDestination) {
        print("🧭 AppRouter: Navigating to \(destination)")
        print("🧭 AppRouter: Current path before navigation: \(path)")
        
        // Prevent duplicate navigation to the same destination
        if !path.isEmpty {
            // We can't easily check the last destination with NavigationPath, so we'll just proceed
            // The duplicate prevention will be handled by SwiftUI's navigation system
        }
        
        path.append(destination)
        print("🧭 AppRouter: Path now contains \(path.count) destinations: \(path)")
    }
    
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    func clearNavigationPath() {
        // NavigationPath doesn't have removeAll, so we'll clear it by setting to empty
        path = NavigationPath()
    }
    
    func navigateToRoot() {
        path = NavigationPath()
    }
    
    // Sheet presentation methods
    func presentSheet(_ sheet: SheetDestination) {
        activeSheet = sheet
    }
    
    func dismissSheet() {
        activeSheet = nil
    }
    
    // Common workflows
    func presentLogEntryView() {
        presentSheet(.logEntry)
    }
    
    func startMealLogging() {
        presentSheet(.mealForm())
    }
    
    func startSymptomLogging() {
        presentSheet(.symptomForm())
    }
    
    func editMeal(id: String) {
        presentSheet(.mealForm(id))
    }
    
    func editSymptom(id: String) {
        presentSheet(.symptomForm(id))
    }
    
    func viewMealDetails(id: String) {
        print("🧭 AppRouter: viewMealDetails called with ID: \(id)")
        mealDetailSheet = MealDetailSheet(mealId: id)
        print("🧭 AppRouter: mealDetailSheet set to: \(mealDetailSheet?.mealId ?? "nil")")
    }
    
    func viewSymptomDetails(id: String) {
        print("🧭 AppRouter: viewSymptomDetails called with ID: \(id)")
        symptomDetailSheet = SymptomDetailSheet(symptomId: id)
        print("🧭 AppRouter: symptomDetailSheet set to: \(symptomDetailSheet?.symptomId ?? "nil")")
    }
    
    func showProfile() {
        presentSheet(.profile)
    }
    
    func navigateToCalendar(date: Date) {
        navigateTo(.calendar(date))
    }
}
