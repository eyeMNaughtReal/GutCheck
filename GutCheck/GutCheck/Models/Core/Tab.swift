import Foundation

enum Tab: String, CaseIterable {
    case dashboard
    case meals
    case add
    case symptoms
    case insights
    
    var title: String {
        switch self {
        case .dashboard: return "Home"
        case .meals: return "Meals"
        case .add: return ""
        case .symptoms: return "Symptoms"
        case .insights: return "Insights"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "house"
        case .meals: return "list.bullet"
        case .add: return "plus"
        case .symptoms: return "waveform.path.ecg"
        case .insights: return "chart.bar.xaxis"
        }
    }
}
