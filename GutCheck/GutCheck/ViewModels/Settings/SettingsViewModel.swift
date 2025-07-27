import SwiftUI

class SettingsViewModel: ObservableObject {
    @AppStorage("appLanguage") var languageRaw: String = AppLanguage.english.rawValue
    @AppStorage("unitOfMeasure") var unitRaw: String = UnitSystem.metric.rawValue
    
    var language: AppLanguage {
        get { AppLanguage(rawValue: languageRaw) ?? .english }
        set { languageRaw = newValue.rawValue }
    }
    var unitOfMeasure: UnitSystem {
        get { UnitSystem(rawValue: unitRaw) ?? .metric }
        set { unitRaw = newValue.rawValue }
    }
}
