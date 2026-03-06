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



@MainActor
class AppRouter: ObservableObject {
    static let shared = AppRouter()
    
    // Per-tab navigation paths to prevent cross-tab state leakage
    @Published var dashboardPath = NavigationPath()
    @Published var mealsPath = NavigationPath()
    @Published var symptomsPath = NavigationPath()
    @Published var activeSheet: SheetDestination?
    @Published var selectedTab: Tab = .dashboard
    @Published private var isNavigating = false
    
    /// The navigation path for the currently selected tab
    private var activePath: NavigationPath {
        get {
            switch selectedTab {
            case .dashboard: return dashboardPath
            case .meals: return mealsPath
            case .symptoms: return symptomsPath
            default: return NavigationPath()
            }
        }
        set {
            switch selectedTab {
            case .dashboard: dashboardPath = newValue
            case .meals: mealsPath = newValue
            case .symptoms: symptomsPath = newValue
            default: break
            }
        }
    }
    
    // Navigation methods
    func navigateTo(_ destination: AppDestination) {
        print("🧭 AppRouter: Navigating to \(destination)")
        
        // Prevent duplicate navigation while one is in progress
        guard !isNavigating else {
            print("🧭 AppRouter: Navigation already in progress, skipping \(destination)")
            return
        }
        
        isNavigating = true
        
        activePath.append(destination)
        
        // Reset navigation flag after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isNavigating = false
        }
    }
    
    func navigateBack() {
        if !activePath.isEmpty {
            activePath.removeLast()
        }
    }
    
    func clearNavigationPath() {
        activePath = NavigationPath()
    }
    
    func navigateToRoot() {
        activePath = NavigationPath()
    }
    
    /// Reset everything back to the Dashboard tab with empty navigation stacks
    func resetToHome() {
        dashboardPath = NavigationPath()
        mealsPath = NavigationPath()
        symptomsPath = NavigationPath()
        activeSheet = nil
        selectedTab = .dashboard
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
        navigateTo(.mealDetail(id))
        print("🧭 AppRouter: Navigating to meal detail: \(id)")
    }
    
    func viewSymptomDetails(id: String) {
        print("🧭 AppRouter: viewSymptomDetails called with ID: \(id)")
        navigateTo(.symptomDetail(id))
        print("🧭 AppRouter: Navigating to symptom detail: \(id)")
    }
    
    func showProfile() {
        presentSheet(.profile)
    }
    
    func navigateToCalendar(date: Date) {
        navigateTo(.calendar(date))
    }
}
