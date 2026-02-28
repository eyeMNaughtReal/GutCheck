import Foundation

enum Tab: String, CaseIterable {
    case dashboard
    case meals
    case symptoms
    case medications
    case insights

    var title: String {
        switch self {
        case .dashboard:   return "Home"
        case .meals:       return "Meals"
        case .symptoms:    return "Symptoms"
        case .medications: return "Meds"
        case .insights:    return "Insights"
        }
    }

    var icon: String {
        switch self {
        case .dashboard:   return "house"
        case .meals:       return "list.bullet"
        case .symptoms:    return "waveform.path.ecg"
        case .medications: return "pills.fill"
        case .insights:    return "chart.bar.xaxis"
        }
    }
}
