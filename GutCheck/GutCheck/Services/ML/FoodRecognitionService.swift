// FoodRecognitionService.swift
// GutCheck
//
// Core ML food recognition integration for LiDAR workflow

import Foundation
import CoreML
import Vision
import UIKit

class FoodRecognitionService {
    static let shared = FoodRecognitionService()
    private let model: VNCoreMLModel

    private init() {
        do {
            let mlModel = try Inceptionv3(configuration: MLModelConfiguration()).model
            self.model = try VNCoreMLModel(for: mlModel)
        } catch {
            fatalError("Failed to initialize FoodRecognitionService: \(error)")
        }
    }
    
    func predictFood(from image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }
        let request = VNCoreMLRequest(model: model) { request, error in
            guard let results = request.results as? [VNClassificationObservation] else {
                completion([])
                return
            }
            let topResults = results.prefix(3).map { $0.identifier }
            completion(topResults)
        }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }
}
