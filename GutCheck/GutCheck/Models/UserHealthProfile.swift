import Foundation
import HealthKit

struct UserHealthProfile {
    var dateOfBirth: Date?
    var biologicalSex: HKBiologicalSex?
    var weight: Double?  // in kg
    var height: Double?  // in meters
}
