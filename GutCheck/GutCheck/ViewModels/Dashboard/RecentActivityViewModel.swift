import SwiftUI
import FirebaseFirestore
import HealthKit

@MainActor
class RecentActivityViewModel: ObservableObject {
    @Published var recentEntries: [ActivityEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Repository dependencies
    private let mealRepository: MealRepository
    private let symptomRepository: SymptomRepository
    private var medicationService: HealthKitMedicationService?
    
    init(mealRepository: MealRepository = MealRepository.shared,
         symptomRepository: SymptomRepository = SymptomRepository.shared) {
        self.mealRepository = mealRepository
        self.symptomRepository = symptomRepository
    }
    
    func loadRecentActivity(for date: Date, authService: AuthService) {
        isLoading = true
        errorMessage = nil
        print("📊 RecentActivityViewModel: Loading activity for date: \(date)")
        
        Task {
            do {
                let entries = try await fetchActivityEntries(for: date, authService: authService)
                print("📊 RecentActivityViewModel: Loaded \(entries.count) activity entries")
                await MainActor.run {
                    self.recentEntries = entries
                    self.isLoading = false
                    print("📊 RecentActivityViewModel: Updated UI with \(self.recentEntries.count) entries")
                }
            } catch {
                print("❌ RecentActivityViewModel: Error loading recent activity: \(error)")
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    // MARK: - Fetch Activity Entries
    
    private func fetchActivityEntries(for date: Date, authService: AuthService) async throws -> [ActivityEntry] {
        guard let currentUser = authService.currentUser else {
            print("❌ RecentActivityViewModel: No authenticated user")
            throw RepositoryError.noAuthenticatedUser
        }
        
        print("🔍 RecentActivityViewModel: Fetching activity for user \(currentUser.id) on \(date)")
        var entries: [ActivityEntry] = []
        
        // Fetch meals using repository
        let meals = try await mealRepository.fetchMealsForDate(date, userId: currentUser.id)
        print("🍽️ RecentActivityViewModel: Found \(meals.count) meals")
        for meal in meals {
            entries.append(ActivityEntry(type: .meal(meal), timestamp: meal.date))
        }
        
        // Fetch symptoms using repository
        let symptoms = try await symptomRepository.fetchSymptomsForDate(date, userId: currentUser.id)
        print("🏥 RecentActivityViewModel: Found \(symptoms.count) symptoms")
        for symptom in symptoms {
            entries.append(ActivityEntry(type: .symptom(symptom), timestamp: symptom.date))
            print("   - Symptom: \(symptom.id) at \(symptom.date)")
        }
        
        // Fetch medications for the date
        let medications = try await fetchMedicationsForDate(date)
        print("💊 RecentActivityViewModel: Found \(medications.count) medications")
        for medication in medications {
            entries.append(ActivityEntry(type: .medication(medication), timestamp: medication.startDate))
            print("   - Medication: \(medication.name) at \(medication.startDate)")
        }
        
        // Sort by timestamp (most recent first) - no limit, show all entries for the day
        let sortedEntries = entries
            .sorted { $0.timestamp > $1.timestamp }
        
        print("📊 RecentActivityViewModel: Returning \(sortedEntries.count) total entries")
        return sortedEntries
    }
    
    // MARK: - Medication Fetching
    
    private func getMedicationService() -> HealthKitMedicationService {
        if medicationService == nil {
            medicationService = HealthKitMedicationService()
        }
        return medicationService!
    }
    

    
    private func fetchMedicationsForDate(_ date: Date) async throws -> [MedicationRecord] {
        // Get the start and end of the specified date
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        do {
            // Fetch medications from HealthKit service
            let service = getMedicationService()
            let allMedications = try await service.fetchMedicationsFromHealthKit()
            
            // Filter medications that were active on the specified date
            let medicationsForDate = allMedications.filter { medication in
                // Check if medication was active on the specified date
                let medicationStart = medication.startDate
                let medicationEnd = medication.endDate ?? Date.distantFuture
                
                // Medication is active if it started before or on the date and hasn't ended yet
                return medicationStart <= endOfDay && medicationEnd >= startOfDay
            }
            
            print("💊 RecentActivityViewModel: Found \(medicationsForDate.count) medications for date \(date)")
            return medicationsForDate
        } catch {
            // Handle HealthKit authorization errors gracefully
            if let healthKitError = error as? HKError {
                switch healthKitError.code {
                case .errorAuthorizationDenied, .errorAuthorizationNotDetermined:
                    print("💊 RecentActivityViewModel: HealthKit authorization not granted for medications - skipping")
                    return []
                default:
                    print("💊 RecentActivityViewModel: HealthKit error: \(healthKitError.localizedDescription)")
                    return []
                }
            } else {
                print("💊 RecentActivityViewModel: Error fetching medications: \(error.localizedDescription)")
                return []
            }
        }
    }
}
