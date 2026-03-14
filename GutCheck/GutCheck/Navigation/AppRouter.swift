import SwiftUI

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
        Task {
            try? await Task.sleep(for: .milliseconds(100))
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
