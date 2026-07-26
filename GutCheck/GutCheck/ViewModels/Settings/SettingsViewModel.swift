import SwiftUI

@Observable class SettingsViewModel {
    private static let defaults = UserDefaults.standard

    // MARK: - Stored properties (tracked by @Observable)

    var languageRaw: String {
        didSet { Self.defaults.set(languageRaw, forKey: "appLanguage") }
    }
    var unitRaw: String {
        didSet { Self.defaults.set(unitRaw, forKey: "unitOfMeasure") }
    }
    var colorSchemeRaw: String {
        didSet { Self.defaults.set(colorSchemeRaw, forKey: "appColorScheme") }
    }
    var healthKitSyncEnabled: Bool {
        didSet { Self.defaults.set(healthKitSyncEnabled, forKey: "healthKitSyncEnabled") }
    }
    var healthKitWriteMeals: Bool {
        didSet { Self.defaults.set(healthKitWriteMeals, forKey: "healthKitWriteMeals") }
    }
    var healthKitWriteSymptoms: Bool {
        didSet { Self.defaults.set(healthKitWriteSymptoms, forKey: "healthKitWriteSymptoms") }
    }

    // MARK: - Developer / Beta Toggles (DEBUG only)

    #if DEBUG
    var testMealModeEnabled: Bool {
        didSet { Self.defaults.set(testMealModeEnabled, forKey: "dev.testMealMode") }
    }
    var experimentalAIEnabled: Bool {
        didSet { Self.defaults.set(experimentalAIEnabled, forKey: "dev.experimentalAI") }
    }
    var showSyncDebugInfo: Bool {
        didSet { Self.defaults.set(showSyncDebugInfo, forKey: "dev.showSyncDebugInfo") }
    }
    #endif

    // MARK: - Init (read current values from UserDefaults)

    init() {
        let defaults = Self.defaults
        self.languageRaw = defaults.string(forKey: "appLanguage") ?? AppLanguage.english.rawValue
        self.unitRaw = defaults.string(forKey: "unitOfMeasure") ?? UnitSystem.metric.rawValue
        self.colorSchemeRaw = defaults.string(forKey: "appColorScheme") ?? AppColorScheme.system.rawValue
        self.healthKitSyncEnabled = defaults.object(forKey: "healthKitSyncEnabled") as? Bool ?? true
        self.healthKitWriteMeals = defaults.object(forKey: "healthKitWriteMeals") as? Bool ?? true
        self.healthKitWriteSymptoms = defaults.object(forKey: "healthKitWriteSymptoms") as? Bool ?? true

        #if DEBUG
        self.testMealModeEnabled = defaults.object(forKey: "dev.testMealMode") as? Bool ?? false
        self.experimentalAIEnabled = defaults.object(forKey: "dev.experimentalAI") as? Bool ?? false
        self.showSyncDebugInfo = defaults.object(forKey: "dev.showSyncDebugInfo") as? Bool ?? false
        #endif
    }

    // MARK: - Computed convenience properties

    var language: AppLanguage {
        get { AppLanguage(rawValue: languageRaw) ?? .english }
        set { languageRaw = newValue.rawValue }
    }
    var unitOfMeasure: UnitSystem {
        get { UnitSystem(rawValue: unitRaw) ?? .metric }
        set { unitRaw = newValue.rawValue }
    }
    var colorScheme: AppColorScheme {
        get { AppColorScheme(rawValue: colorSchemeRaw) ?? .system }
        set { colorSchemeRaw = newValue.rawValue }
    }
    var preferredColorScheme: ColorScheme? {
        switch colorScheme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
