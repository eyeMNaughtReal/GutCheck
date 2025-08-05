//
//  ImageCompressionUtility.swift
//  GutCheck
//
//  Centralized image compression utility to standardize image processing across the app
//

import UIKit

struct ImageCompressionUtility {
    
    // MARK: - Default Quality Levels
    enum CompressionQuality {
        case low        // 0.3 - For thumbnails or heavily constrained uploads
        case medium     // 0.6 - For general use with size constraints
        case standard   // 0.8 - Default quality for profile images and most use cases
        case high       // 0.9 - For high-quality images where file size is less important
        case maximum    // 1.0 - No compression
        
        var value: CGFloat {
            switch self {
            case .low: return 0.3
            case .medium: return 0.6
            case .standard: return 0.8
            case .high: return 0.9
            case .maximum: return 1.0
            }
        }
    }
    
    // MARK: - Compression Methods
    
    /// Compress image with predefined quality level
    /// - Parameters:
    ///   - image: The UIImage to compress
    ///   - quality: The compression quality level (default: .standard)
    /// - Returns: Compressed image data
    /// - Throws: ImageCompressionError if compression fails
    static func compress(
        _ image: UIImage,
        quality: CompressionQuality = .standard
    ) throws -> Data {
        guard let compressedData = image.jpegData(compressionQuality: quality.value) else {
            throw ImageCompressionError.compressionFailed
        }
        
        print("🗜️ ImageCompressionUtility: Compressed image from original to \(compressedData.count) bytes at quality \(quality.value)")
        
        return compressedData
    }
    
    /// Compress image with custom quality value
    /// - Parameters:
    ///   - image: The UIImage to compress
    ///   - quality: Custom compression quality (0.0 to 1.0)
    /// - Returns: Compressed image data
    /// - Throws: ImageCompressionError if compression fails or quality is invalid
    static func compress(
        _ image: UIImage,
        quality: CGFloat
    ) throws -> Data {
        guard quality >= 0.0 && quality <= 1.0 else {
            throw ImageCompressionError.invalidQuality
        }
        
        guard let compressedData = image.jpegData(compressionQuality: quality) else {
            throw ImageCompressionError.compressionFailed
        }
        
        print("🗜️ ImageCompressionUtility: Compressed image to \(compressedData.count) bytes at quality \(quality)")
        
        return compressedData
    }
    
    /// Compress image to target file size (approximate)
    /// - Parameters:
    ///   - image: The UIImage to compress
    ///   - targetSizeKB: Target file size in kilobytes
    ///   - maxIterations: Maximum compression attempts (default: 5)
    /// - Returns: Compressed image data
    /// - Throws: ImageCompressionError if target size cannot be achieved
    static func compressToTargetSize(
        _ image: UIImage,
        targetSizeKB: Int,
        maxIterations: Int = 5
    ) throws -> Data {
        let targetSizeBytes = targetSizeKB * 1024
        var quality: CGFloat = 0.9
        var iteration = 0
        
        while iteration < maxIterations {
            guard let compressedData = image.jpegData(compressionQuality: quality) else {
                throw ImageCompressionError.compressionFailed
            }
            
            if compressedData.count <= targetSizeBytes {
                print("🗜️ ImageCompressionUtility: Achieved target size of \(targetSizeKB)KB in \(iteration + 1) iterations")
                return compressedData
            }
            
            // Reduce quality for next iteration
            quality *= 0.8
            iteration += 1
            
            // Don't go below minimum quality
            if quality < 0.1 {
                break
            }
        }
        
        // If we can't achieve target size, return the best we got
        guard let finalData = image.jpegData(compressionQuality: max(quality, 0.1)) else {
            throw ImageCompressionError.compressionFailed
        }
        
        print("⚠️ ImageCompressionUtility: Could not achieve target size \(targetSizeKB)KB, final size: \(finalData.count / 1024)KB")
        return finalData
    }
    
    /// Get estimated file size for image at given quality without actually compressing
    /// - Parameters:
    ///   - image: The UIImage to estimate
    ///   - quality: Compression quality
    /// - Returns: Estimated file size in bytes
    static func estimateFileSize(
        for image: UIImage,
        at quality: CompressionQuality
    ) -> Int? {
        guard let data = image.jpegData(compressionQuality: quality.value) else {
            return nil
        }
        return data.count
    }
}

// MARK: - Error Types

enum ImageCompressionError: LocalizedError {
    case compressionFailed
    case invalidQuality
    case targetSizeNotAchievable
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress image"
        case .invalidQuality:
            return "Invalid compression quality. Must be between 0.0 and 1.0"
        case .targetSizeNotAchievable:
            return "Could not compress image to target size"
        }
    }
}
