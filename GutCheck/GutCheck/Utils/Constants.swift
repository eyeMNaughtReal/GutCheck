import Foundation

enum Constants {
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    
    enum API {
        static let baseURL = "https://api-dev.gutcheck.example.com" // Development URL by default
    }
    
    enum Features {
        static let enableHealthKit = true  // Enable HealthKit integration by default
        static let enableLiDAR = true     // Enable LiDAR scanning feature by default 
        static let enableAIAnalysis = true // Enable AI analysis features by default
    }
}

extension Bundle {
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}
