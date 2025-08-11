import SwiftUI

// MARK: - Insight Category

enum InsightCategory: String, CaseIterable, Identifiable {
    case foodTriggers = "Food Triggers"
    case patterns = "Patterns"
    case trends = "Trends"
    case recommendations = "Recommendations"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .foodTriggers: return "exclamationmark.triangle.fill"
        case .patterns: return "chart.bar.fill"
        case .trends: return "chart.line.uptrend.xyaxis"
        case .recommendations: return "lightbulb.fill"
        }
    }
    
    var accentColor: Color {
        switch self {
        case .foodTriggers: return .red
        case .patterns: return .blue
        case .trends: return .green
        case .recommendations: return .purple
        }
    }
    
    var description: String {
        switch self {
        case .foodTriggers:
            return "Identify foods that may be causing symptoms"
        case .patterns:
            return "Discover recurring patterns in your health data"
        case .trends:
            return "Track changes and progress over time"
        case .recommendations:
            return "Get personalized suggestions for improvement"
        }
    }
    
    var title: String { rawValue }
}

// MARK: - Health Pattern

struct HealthPattern: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let confidence: Double
    let dateRange: String
    let supportingData: [String]
    let recommendations: [String]
}

// MARK: - Health Recommendation

struct HealthRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    let priority: RecommendationPriority
    let actionItems: [String]
    let source: String
    let dateCreated: Date
    
    enum RecommendationPriority: Int, Comparable {
        case low = 0
        case medium = 1
        case high = 2
        
        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}

// MARK: - Insight Type

enum InsightType: String, Codable {
    case foodTrigger = "Food Trigger"
    case symptomPattern = "Symptom Pattern"
    case mealTiming = "Meal Timing"
    case nutritionTrend = "Nutrition Trend"
    case activityCorrelation = "Activity Correlation"
    case recommendation = "Recommendation"
}

// MARK: - Insight Status

enum InsightStatus: String, Codable {
    case active = "Active"
    case resolved = "Resolved"
    case dismissed = "Dismissed"
    case archived = "Archived"
}

// MARK: - Insight Confidence Level

enum InsightConfidenceLevel: Int, Codable {
    case low = 1
    case medium = 2
    case high = 3
    
    var percentage: Int {
        switch self {
        case .low: return 60
        case .medium: return 80
        case .high: return 95
        }
    }
    
    var description: String {
        switch self {
        case .low: return "Low Confidence"
        case .medium: return "Medium Confidence"
        case .high: return "High Confidence"
        }
    }
}

// MARK: - Supporting Types

struct InsightEvidence: Codable {
    let type: String
    let description: String
    let data: [String: Any]
    let confidence: Double
    
    enum CodingKeys: String, CodingKey {
        case type, description, data, confidence
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        description = try container.decode(String.self, forKey: .description)
        confidence = try container.decode(Double.self, forKey: .confidence)
        
        // Handle dynamic data dictionary
        if let dataDict = try? container.decode([String: AnyCodable].self, forKey: .data) {
            data = dataDict.mapValues { $0.value }
        } else {
            data = [:]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(description, forKey: .description)
        try container.encode(confidence, forKey: .confidence)
        
        // Convert data dictionary to AnyCodable
        let codableData = data.mapValues { AnyCodable($0) }
        try container.encode(codableData, forKey: .data)
    }
}

// Helper type for encoding/decoding Any
private struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
        }
    }
}
