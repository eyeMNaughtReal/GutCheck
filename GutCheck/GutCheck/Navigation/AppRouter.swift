import SwiftUI

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

// Settings sub-screen navigation
enum SettingsRoute: Hashable {
    case language
    case units
    case appearance
    case reminders
    case medications
    case healthcareExport
    case privacyPolicy
    case dataDeletion
    case localStorage
    case deleteAccount
}

// Insights navigation
enum InsightsRoute: Hashable {
    case insightDetail(HealthInsight)
    case categoryInsights(InsightCategory)
}

// Privacy policy navigation
enum PrivacyPolicyRoute: Hashable {
    case sectionDetail(PolicySection)
}

// Profile menu navigation
enum ProfileMenuRoute: Hashable {
    case settings
    case reminders
}

// Calendar navigation
enum CalendarRoute: Hashable {
    case dayDetail(Date)
    case fullCalendar(Date)
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
@Observable class AppRouter {
    static let shared = AppRouter()
    
    // Per-tab navigation paths to prevent cross-tab state leakage
    var dashboardPath = NavigationPath()
    var mealsPath = NavigationPath()
    var symptomsPath = NavigationPath()
    var activeSheet: SheetDestination?
    var selectedTab: Tab = .dashboard
    private var isNavigating = false
    
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
        
        // Prevent duplicate navigation while one is in progress
        guard !isNavigating else {
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
        navigateTo(.mealDetail(id))
    }
    
    func viewSymptomDetails(id: String) {
        navigateTo(.symptomDetail(id))
    }
    
    func showProfile() {
        presentSheet(.profile)
    }
    
    func navigateToCalendar(date: Date) {
        navigateTo(.calendar(date))
    }
}
