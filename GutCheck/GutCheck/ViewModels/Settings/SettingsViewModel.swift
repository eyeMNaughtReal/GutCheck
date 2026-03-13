import SwiftUI

@Observable class SettingsViewModel {
    @ObservationIgnored @AppStorage("appLanguage") var languageRaw: String = AppLanguage.english.rawValue
    @ObservationIgnored @AppStorage("unitOfMeasure") var unitRaw: String = UnitSystem.metric.rawValue
    @ObservationIgnored @AppStorage("appColorScheme") var colorSchemeRaw: String = AppColorScheme.system.rawValue

    // HealthKit write preferences
    @ObservationIgnored @AppStorage("healthKitSyncEnabled") var healthKitSyncEnabled: Bool = true
    @ObservationIgnored @AppStorage("healthKitWriteMeals") var healthKitWriteMeals: Bool = true
    @ObservationIgnored @AppStorage("healthKitWriteSymptoms") var healthKitWriteSymptoms: Bool = true

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
