import Foundation
import UIKit

class GoogleVisionService {
    static let shared = GoogleVisionService()
    private let apiKey = VisionSecrets.apiKey
    private let baseURL = "https://vision.googleapis.com/v1/images:annotate"
    
    private init() {}
    
    func recognizeFood(from image: UIImage) async throws -> [String] {
        let imageData = try ImageCompressionUtility.compress(image, quality: .standard)
        
        let base64Image = imageData.base64EncodedString()
        
        let requestBody: [String: Any] = [
            "requests": [
                [
                    "image": ["content": base64Image],
                    "features": [
                        ["type": "LABEL_DETECTION", "maxResults": 10],
                        ["type": "OBJECT_LOCALIZATION", "maxResults": 5]
                    ]
                ]
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw NSError(domain: "GoogleVisionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GoogleVisionResponse.self, from: data)
        
        // Filter food-related labels and objects
        return filterFoodItems(from: response)
    }
    
    private func filterFoodItems(from response: GoogleVisionResponse) -> [String] {
        var foodItems = Set<String>()
        
        // Process label annotations with lower confidence threshold for better detection
        if let annotations = response.responses.first?.labelAnnotations {
            for annotation in annotations {
                if annotation.score > 0.5 && isFoodRelated(annotation.description) {
                    foodItems.insert(annotation.description)
                    print("🔍 Vision detected label: \(annotation.description) (confidence: \(annotation.score))")
                }
            }
        }
        
        // Process object annotations with lower confidence threshold
        if let objects = response.responses.first?.localizedObjectAnnotations {
            for object in objects {
                if object.score > 0.5 && isFoodRelated(object.name) {
                    foodItems.insert(object.name)
                    print("🔍 Vision detected object: \(object.name) (confidence: \(object.score))")
                }
            }
        }
        
        let result = Array(foodItems).sorted()
        print("🔍 Final filtered food items: \(result)")
        return result
    }
    
    private func isFoodRelated(_ text: String) -> Bool {
        let foodKeywords = ["food", "dish", "meal", "fruit", "vegetable", "meat", "beverage", "drink", "snack"]
        let specificFoods = [
            "apple", "banana", "orange", "grape", "berry", "lemon", "lime", "pear", "peach", "plum",
            "tomato", "potato", "carrot", "onion", "pepper", "broccoli", "lettuce", "spinach",
            "bread", "pizza", "burger", "sandwich", "pasta", "rice", "chicken", "beef", "pork",
            "fish", "salmon", "tuna", "egg", "cheese", "milk", "yogurt", "cake", "cookie",
            "salad", "soup", "cereal", "corn", "beans", "nuts", "avocado", "cucumber"
        ]
        
        let text = text.lowercased()
        
        // Check for general food keywords
        if foodKeywords.contains(where: { text.contains($0) }) {
            return true
        }
        
        // Check for specific food items
        if specificFoods.contains(where: { text.contains($0) }) {
            return true
        }
        
        return false
    }
}

// MARK: - Response Models
struct GoogleVisionResponse: Codable {
    let responses: [VisionResponseItem]
}

struct VisionResponseItem: Codable {
    let labelAnnotations: [Annotation]?
    let localizedObjectAnnotations: [ObjectAnnotation]?
}

struct Annotation: Codable {
    let description: String
    let score: Float
}

struct ObjectAnnotation: Codable {
    let name: String
    let score: Float
}
