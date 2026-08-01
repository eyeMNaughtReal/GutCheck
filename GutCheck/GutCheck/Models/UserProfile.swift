import Foundation

struct UserProfile: Identifiable, Codable {
    var id: String  // Local profile id
    var email: String
    var fullName: String?
    var age: Int?
    var weight: Double?  // kg
    var height: Double?  // cm
    var createdAt: Date = Date.now
}
