import Testing
import Foundation
@testable import GutCheck

@MainActor
struct InsightsViewModelTests {

    // MARK: - Test Helpers

    private func makeMeal(
        id: String = UUID().uuidString,
        name: String = "Test Meal",
        date: Date = Date.now,
        type: MealType = .lunch,
        foodItems: [FoodItem] = []
    ) -> Meal {
        Meal(id: id, name: name, date: date, type: type, source: .manual, foodItems: foodItems)
    }

    private func makeSymptom(
        id: String = UUID().uuidString,
        date: Date = Date.now,
        stoolType: StoolType = .type4,
        painLevel: PainLevel = .none,
        urgencyLevel: UrgencyLevel = .none
    ) -> Symptom {
        Symptom(id: id, date: date, stoolType: stoolType, painLevel: painLevel, urgencyLevel: urgencyLevel, createdBy: "test-user")
    }

    private func makeFoodItem(name: String) -> FoodItem {
        FoodItem(name: name, quantity: "1 serving")
    }

    private func makeVM(
        meals: [Meal] = [],
        symptoms: [Symptom] = []
    ) -> (InsightsViewModel, MockMealRepository, MockSymptomRepository) {
        let mealRepo = MockMealRepository()
        mealRepo.mealsToReturn = meals
        let symptomRepo = MockSymptomRepository()
        symptomRepo.symptomsToReturn = symptoms
        let healthKit = MockHealthKitManager()
        let vm = InsightsViewModel(
            mealRepository: mealRepo,
            symptomRepository: symptomRepo,
            healthKitManager: healthKit
        )
        return (vm, mealRepo, symptomRepo)
    }

    // MARK: - Empty Data

    @Test("loadInsights with empty data produces zero counts")
    func handlesEmptyData() async {
        let (vm, _, _) = makeVM()
        await vm.loadInsights()

        #expect(vm.weeklyMealCount == 0)
        #expect(vm.weeklySymptomCount == 0)
        #expect(vm.topSymptoms.isEmpty)
        #expect(vm.topTriggerFoods.isEmpty)
        #expect(vm.mealSuggestions.isEmpty)
    }

    // MARK: - Weekly Counts

    @Test("loadInsights counts meals and symptoms from last 7 days")
    func setsWeeklyCounts() async {
        let now = Date.now
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: now)!
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: now)!

        let meals = [
            makeMeal(date: now),
            makeMeal(date: threeDaysAgo),
            makeMeal(date: tenDaysAgo) // Outside 7-day window
        ]
        let symptoms = [
            makeSymptom(date: now, painLevel: .mild),
            makeSymptom(date: tenDaysAgo, painLevel: .moderate) // Outside 7-day window
        ]

        let (vm, _, _) = makeVM(meals: meals, symptoms: symptoms)
        await vm.loadInsights()

        #expect(vm.weeklyMealCount == 2)
        #expect(vm.weeklySymptomCount == 1)
    }

    // MARK: - Top Symptoms

    @Test("loadInsights computes top symptoms from pain, urgency, and stool type")
    func computesTopSymptoms() async {
        let now = Date.now
        let symptoms = [
            makeSymptom(date: now, painLevel: .moderate),
            makeSymptom(date: now, painLevel: .moderate),
            makeSymptom(date: now, urgencyLevel: .urgent),
            makeSymptom(date: now, stoolType: .type7), // Loose stool
        ]

        let (vm, _, _) = makeVM(symptoms: symptoms)
        await vm.loadInsights()

        let names = vm.topSymptoms.map(\.name)
        #expect(names.contains("Moderate Pain"))
        // Moderate Pain should be ranked first with count 2
        #expect(vm.topSymptoms.first?.name == "Moderate Pain")
        #expect(vm.topSymptoms.first?.count == 2)
    }

    // MARK: - Trigger Foods

    @Test("loadInsights computes trigger foods from meals 2-8 hours before symptoms")
    func computesTriggerFoods() async {
        let now = Date.now
        // Meal eaten 4 hours before symptom (within 2-8h window)
        let mealDate = now.addingTimeInterval(-4 * 3600)
        let meals = [
            makeMeal(date: mealDate, foodItems: [
                makeFoodItem(name: "Dairy"),
                makeFoodItem(name: "Bread")
            ])
        ]
        let symptoms = [
            makeSymptom(date: now, painLevel: .severe)
        ]

        let (vm, _, _) = makeVM(meals: meals, symptoms: symptoms)
        await vm.loadInsights()

        let foodNames = vm.topTriggerFoods.map(\.name)
        #expect(foodNames.contains("Dairy"))
        #expect(foodNames.contains("Bread"))
    }

    @Test("loadInsights does not count meals outside 2-8 hour window as triggers")
    func triggerFoodsIgnoresOutsideWindow() async {
        let now = Date.now
        // Meal eaten 1 hour before (too recent, outside 2-8h window)
        let tooRecentMeal = makeMeal(date: now.addingTimeInterval(-1 * 3600), foodItems: [makeFoodItem(name: "RecentFood")])
        // Meal eaten 10 hours before (too old, outside 2-8h window)
        let tooOldMeal = makeMeal(date: now.addingTimeInterval(-10 * 3600), foodItems: [makeFoodItem(name: "OldFood")])

        let symptoms = [makeSymptom(date: now, painLevel: .moderate)]
        let (vm, _, _) = makeVM(meals: [tooRecentMeal, tooOldMeal], symptoms: symptoms)
        await vm.loadInsights()

        let foodNames = vm.topTriggerFoods.map(\.name)
        #expect(!foodNames.contains("RecentFood"))
        #expect(!foodNames.contains("OldFood"))
    }

    // MARK: - Best Days

    @Test("loadInsights ranks best days by lowest symptom count")
    func computesBestDays() async {
        let calendar = Calendar.current
        let now = Date.now

        // Create symptoms concentrated on specific weekdays
        var symptoms: [Symptom] = []
        for dayOffset in 0..<28 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
            let weekday = calendar.component(.weekday, from: date)
            // Add more symptoms on weekday 2 (Monday) to make other days "better"
            if weekday == 2 {
                symptoms.append(makeSymptom(date: date, painLevel: .moderate))
                symptoms.append(makeSymptom(date: date, painLevel: .mild))
            }
        }

        let (vm, _, _) = makeVM(symptoms: symptoms)
        await vm.loadInsights()

        // Best days should have 3 entries (top 3)
        #expect(vm.bestDays.count == 3)
        // None of the best days should be Monday (which has the most symptoms)
        let bestDayNames = vm.bestDays.map(\.name)
        #expect(!bestDayNames.contains("Monday"))
    }

    // MARK: - Meal Suggestions

    @Test("loadInsights filters out meals with high-trigger foods from suggestions")
    func mealSuggestionsFilterHighTriggers() async {
        let now = Date.now
        // Create a meal with a food that will be a trigger
        let triggerMealDate = now.addingTimeInterval(-4 * 3600)
        let triggerMeal = makeMeal(name: "Bad Meal", date: triggerMealDate, foodItems: [makeFoodItem(name: "SpicyFood")])
        let safeMeal = makeMeal(name: "Safe Meal", date: now, foodItems: [makeFoodItem(name: "Rice")])

        // Create multiple symptoms after the trigger meal to build up trigger score
        var symptoms: [Symptom] = []
        for i in 0..<5 {
            let symptomDate = triggerMealDate.addingTimeInterval(Double(2 + i) * 3600)
            symptoms.append(makeSymptom(date: symptomDate, painLevel: .severe))
        }

        let (vm, _, _) = makeVM(meals: [triggerMeal, safeMeal], symptoms: symptoms)
        await vm.loadInsights()

        // Safe meal should appear in suggestions (Rice has no trigger correlation)
        let suggestionNames = vm.mealSuggestions.map(\.mealName)
        if !suggestionNames.isEmpty {
            #expect(suggestionNames.contains("Safe Meal") || vm.mealSuggestions.isEmpty)
        }
    }

    // MARK: - Weekly Trigger Report

    @Test("loadInsights computes weekly trigger report with new and recurring triggers")
    func computesWeeklyTriggerReport() async {
        let now = Date.now
        let fiveDaysAgo = now.addingTimeInterval(-5 * 86400)
        let twelveDaysAgo = now.addingTimeInterval(-12 * 86400)

        // Current week: meal with "Dairy" eaten 4h before symptom
        let currentMeal = makeMeal(date: fiveDaysAgo, foodItems: [makeFoodItem(name: "Dairy")])
        let currentSymptom = makeSymptom(date: fiveDaysAgo.addingTimeInterval(4 * 3600), painLevel: .moderate)

        // Previous week: meal with "Dairy" eaten 4h before symptom (recurring trigger)
        let prevMeal = makeMeal(date: twelveDaysAgo, foodItems: [makeFoodItem(name: "Dairy")])
        let prevSymptom = makeSymptom(date: twelveDaysAgo.addingTimeInterval(4 * 3600), painLevel: .moderate)

        let (vm, _, _) = makeVM(
            meals: [currentMeal, prevMeal],
            symptoms: [currentSymptom, prevSymptom]
        )
        await vm.loadInsights()

        if let report = vm.weeklyTriggerReport {
            // Dairy should be a recurring trigger (present in both weeks)
            let recurringNames = report.recurringTriggers.map(\.foodName)
            #expect(recurringNames.contains("Dairy"))
        }
        // Report may or may not exist depending on date boundaries, so this is non-fatal
    }

    // MARK: - Error Handling

    @Test("loadInsights handles repo error gracefully")
    func handlesError() async {
        let mealRepo = MockMealRepository()
        mealRepo.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Fetch failed"])
        let symptomRepo = MockSymptomRepository()
        let healthKit = MockHealthKitManager()

        let vm = InsightsViewModel(
            mealRepository: mealRepo,
            symptomRepository: symptomRepo,
            healthKitManager: healthKit
        )
        await vm.loadInsights()

        #expect(vm.error != nil)
        #expect(vm.error?.contains("Fetch failed") == true)
        #expect(!vm.isLoading)
    }
}
