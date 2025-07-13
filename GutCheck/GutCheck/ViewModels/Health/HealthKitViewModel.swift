import SwiftUI
@MainActor
final class HealthKitViewModel: ObservableObject {
    @Published var profile: UserHealthProfile?
    @Published var isAuthorized = false
    @Published var showPermissionError = false

    func requestHealthKitAccess() async {
        let (granted, _) = await withCheckedContinuation { continuation in
            HealthKitManager.shared.requestAuthorization { granted, error in
                continuation.resume(returning: (granted, error))
            }
        }

        if granted {
            await fetchProfile()
            isAuthorized = true
        } else {
            showPermissionError = true
        }
    }

    func fetchProfile() async {
        await withCheckedContinuation { continuation in
            HealthKitManager.shared.fetchUserProfile { profile in
                DispatchQueue.main.async {
                    self.profile = profile
                    continuation.resume()
                }
            }
        }
    }

    // Formatting helpers...
    func formattedAge() -> String {
        guard let dob = profile?.dateOfBirth else { return "-" }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
        if let years = ageComponents.year {
            return String(years)
        }
        return "-"
    }

    func formattedHeight() -> String {
        guard let height = profile?.height else { return "-" }
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        return formatter.string(fromValue: height, unit: .meter)
    }

    func formattedWeight() -> String {
        guard let weight = profile?.weight else { return "-" }
        let formatter = MassFormatter()
        formatter.unitStyle = .short
        return formatter.string(fromValue: weight, unit: .kilogram)
    }
}
