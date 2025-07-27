import Foundation
import UIKit

class GoogleVisionService {
    static let shared = GoogleVisionService()
    private let apiKey = VisionSecrets.apiKey
    private let baseURL = "https://vision.googleapis.com/v1/images:annotate"
    
    private init() {}
    
    func recognizeFood(from image: UIImage) async throws -> [String] {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "GoogleVisionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
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
        
        // Process label annotations
        if let annotations = response.responses.first?.labelAnnotations {
            for annotation in annotations {
                if annotation.score > 0.7 && isFoodRelated(annotation.description) {
                    foodItems.insert(annotation.description)
                }
            }
        }
        
        // Process object annotations
        if let objects = response.responses.first?.localizedObjectAnnotations {
            for object in objects {
                if object.score > 0.7 && isFoodRelated(object.name) {
                    foodItems.insert(object.name)
                }
            }
        }
        
        return Array(foodItems).sorted()
    }
    
    private func isFoodRelated(_ text: String) -> Bool {
        let foodKeywords = ["food", "dish", "meal", "fruit", "vegetable", "meat", "beverage", "drink", "snack"]
        let text = text.lowercased()
        return foodKeywords.contains { text.contains($0) }
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
