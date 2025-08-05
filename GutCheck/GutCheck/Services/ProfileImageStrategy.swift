//
//  ProfileImageStrategy.swift
//  GutCheck
//
//  Protocol defining profile image storage strategies
//

import UIKit

protocol ProfileImageStrategy {
    func uploadProfileImage(_ image: UIImage, for userId: String) async throws -> String
    func downloadProfileImage(from urlString: String) async throws -> UIImage
    func deleteProfileImage(for userId: String) async throws
}

@MainActor
protocol ProfileImageStrategyDelegate: AnyObject {
    func strategyDidUpdateProgress(_ progress: Double)
    func strategyDidEncounterError(_ error: String)
}