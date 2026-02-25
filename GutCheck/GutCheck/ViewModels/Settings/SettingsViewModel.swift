import SwiftUI

class SettingsViewModel: ObservableObject {
    @AppStorage("appLanguage") var languageRaw: String = AppLanguage.english.rawValue
    @AppStorage("unitOfMeasure") var unitRaw: String = UnitSystem.metric.rawValue
    @AppStorage("appColorScheme") var colorSchemeRaw: String = AppColorScheme.system.rawValue

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
