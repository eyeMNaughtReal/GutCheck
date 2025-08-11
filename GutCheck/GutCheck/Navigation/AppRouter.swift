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
    
    // Navigation methods
    func navigateTo(_ destination: AppDestination) {
        path.append(destination)
    }
    
    func navigateBack() {
        if !path.isEmpty {
            path.removeLast()
        }
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
