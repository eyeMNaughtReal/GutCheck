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
    
    @Published var path = NavigationPath()
    @Published var activeSheet: SheetDestination?
    @Published var selectedTab: Tab = .dashboard
    @Published private var isNavigating = false
    
    // Navigation methods
    func navigateTo(_ destination: AppDestination) {
        print("🧭 AppRouter: Navigating to \(destination)")
        print("🧭 AppRouter: Current path before navigation: \(path)")
        
        // Prevent duplicate navigation while one is in progress
        guard !isNavigating else {
            print("🧭 AppRouter: Navigation already in progress, skipping \(destination)")
            return
        }
        
        isNavigating = true
        
        path.append(destination)
        print("🧭 AppRouter: Path now contains \(path.count) destinations: \(path)")
        
        // Reset navigation flag after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isNavigating = false
        }
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
