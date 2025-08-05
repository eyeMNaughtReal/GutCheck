//
//  ProfileImageError.swift
//  GutCheck
//
//  Shared error types for profile image operations
//

import Foundation

enum ProfileImageError: LocalizedError {
    case imageCompressionFailed
    case invalidURL
    case imageDecodingFailed
    case uploadFailed
    case uploadFailedWithMessage(String)
    case downloadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image for upload"
        case .invalidURL:
            return "Invalid image URL"
        case .imageDecodingFailed:
            return "Failed to decode image data"
        case .uploadFailed:
            return "Upload failed"
        case .uploadFailedWithMessage(let message):
            return "Upload failed: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        }
    }
}