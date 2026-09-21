import Testing
import Foundation
@testable import GutCheck

/// Covers the bucketing behind the dashboard week-strip indicators.
///
/// The interesting logic isn't the fetching, it's assigning each record to a
/// day. That's the part that fails quietly — a record landing in the wrong
/// bucket shows a dot on the wrong day, which looks like working software.
@MainActor
struct WeekLogSummaryServiceTests {

    private let calendar = Calendar.current
    private let userId = "test-user"

    private func makeService(
        meals: [Meal] = [],
        symptoms: [Symptom] = [],
        doses: [MedicationDoseLog] = []
    ) -> (WeekLogSummaryService, MockMedicationDoseRepository) {
        let mealRepo = MockMealRepository()
        mealRepo.mealsToReturn = meals

        let symptomRepo = MockSymptomRepository()
        symptomRepo.symptomsToReturn = symptoms

        let doseRepo = MockMedicationDoseRepository()
        doseRepo.dosesToReturn = doses

        let service = WeekLogSummaryService(
            mealRepository: mealRepo,
            symptomRepository: symptomRepo,
            doseRepository: doseRepo
        )
        return (service, doseRepo)
    }

    private func day(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: .now))!
    }

    private var week: [Date] { (-3...3).map(day) }

    // MARK: - Shape of the result

    @Test("Every requested day is present, even with nothing logged")
    func allDaysPresentWhenEmpty() async {
        // Absent means "not fetched"; empty means "nothing logged". Callers
        // rely on that distinction, so a day must never simply be missing.
        let (service, _) = makeService()

        let result = await service.summaries(for: week, userId: userId)

        #expect(result.count == 7)
        // An explicit closure, not `allSatisfy(\.isEmpty)`: `allSatisfy` is
        // `rethrows`, and inside the #expect macro a key path passed as its
        // predicate reads as possibly-throwing and fails to compile.
        #expect(result.values.allSatisfy { $0.isEmpty })
    }

    @Test("Keys are normalised to the start of the day")
    func keysAreStartOfDay() async {
        // Callers look up with whatever Date they have, which is rarely
        // midnight.
        let (service, _) = makeService()

        let result = await service.summaries(for: week, userId: userId)

        for key in result.keys {
            #expect(key == calendar.startOfDay(for: key))
        }
    }

    @Test("Duplicate dates within the same day collapse to one entry")
    func duplicateDatesCollapse() async {
        let (service, _) = makeService()
        let noon = calendar.date(byAdding: .hour, value: 12, to: day(0))!
        let evening = calendar.date(byAdding: .hour, value: 20, to: day(0))!

        let result = await service.summaries(for: [day(0), noon, evening], userId: userId)

        #expect(result.count == 1)
    }

    // MARK: - Bucketing

    @Test("A meal marks only its own day")
    func mealMarksItsDay() async {
        let mealTime = calendar.date(byAdding: .hour, value: 9, to: day(-2))!
        let (service, _) = makeService(
            meals: [Meal(name: "Breakfast", date: mealTime, type: .breakfast, source: .manual, foodItems: [])]
        )

        let result = await service.summaries(for: week, userId: userId)

        #expect(result[day(-2)]?.hasMeal == true)
        #expect(result[day(-2)]?.hasSymptom == false)
        #expect(result[day(-1)]?.hasMeal == false)
    }

    @Test("A symptom marks only its own day")
    func symptomMarksItsDay() async {
        let time = calendar.date(byAdding: .hour, value: 15, to: day(-1))!
        let (service, _) = makeService(
            symptoms: [Symptom(date: time, stoolType: .type4, painLevel: .none, urgencyLevel: .none)]
        )

        let result = await service.summaries(for: week, userId: userId)

        #expect(result[day(-1)]?.hasSymptom == true)
        #expect(result[day(0)]?.hasSymptom == false)
    }

    @Test("A dose marks only its own day")
    func doseMarksItsDay() async {
        let time = calendar.date(byAdding: .hour, value: 8, to: day(0))!
        let (service, _) = makeService(
            doses: [MedicationDoseLog(
                medicationId: "m1", medicationName: "Omeprazole",
                dosageAmount: 20, dosageUnit: "mg", dateTaken: time
            )]
        )

        let result = await service.summaries(for: week, userId: userId)

        #expect(result[day(0)]?.hasMedication == true)
        #expect(result[day(0)]?.hasMeal == false)
    }

    @Test("Late-evening and just-after-midnight records land on different days")
    func dayBoundaryIsRespected() async {
        // The boundary case that a naive implementation gets wrong, and the
        // one nobody notices until a dot appears against the wrong date.
        let lateLastNight = calendar.date(byAdding: .minute, value: -5, to: day(0))!
        let justAfterMidnight = calendar.date(byAdding: .minute, value: 5, to: day(0))!

        let (service, _) = makeService(
            meals: [
                Meal(name: "Late snack", date: lateLastNight, type: .snack, source: .manual, foodItems: []),
                Meal(name: "Early breakfast", date: justAfterMidnight, type: .breakfast, source: .manual, foodItems: [])
            ]
        )

        let result = await service.summaries(for: week, userId: userId)

        #expect(result[day(-1)]?.hasMeal == true)
        #expect(result[day(0)]?.hasMeal == true)
    }

    @Test("All three categories can land on one day")
    func allThreeOnOneDay() async {
        let t = calendar.date(byAdding: .hour, value: 10, to: day(-1))!
        let (service, _) = makeService(
            meals: [Meal(name: "Lunch", date: t, type: .lunch, source: .manual, foodItems: [])],
            symptoms: [Symptom(date: t, stoolType: .type4, painLevel: .none, urgencyLevel: .none)],
            doses: [MedicationDoseLog(
                medicationId: "m1", medicationName: "Omeprazole",
                dosageAmount: 20, dosageUnit: "mg", dateTaken: t
            )]
        )

        let result = await service.summaries(for: week, userId: userId)

        #expect(result[day(-1)]?.isComplete == true)
    }

    // MARK: - Query count

    @Test("A week costs one dose query, not seven")
    func oneQueryPerRange() async {
        // The failure the issue called out: fetching per day makes the strip
        // issue 21 queries and it re-renders on every selection change.
        let (service, doseRepo) = makeService()

        _ = await service.summaries(for: week, userId: userId)

        #expect(doseRepo.rangeFetchCallCount == 1)
    }

    // MARK: - Failure

    @Test("A repository failure yields no summaries rather than throwing")
    func repositoryFailureIsSwallowed() async {
        // A missing indicator is a much better outcome than a dashboard that
        // refuses to render; the strip is fully usable without the dots.
        let mealRepo = MockMealRepository()
        mealRepo.errorToThrow = NSError(domain: "test", code: 1)

        let service = WeekLogSummaryService(
            mealRepository: mealRepo,
            symptomRepository: MockSymptomRepository(),
            doseRepository: MockMedicationDoseRepository()
        )

        let result = await service.summaries(for: week, userId: userId)

        #expect(result.isEmpty)
    }

    // MARK: - Day position

    @Test("Day position separates past, today and future")
    func dayPositionClassifies() {
        #expect(DayPosition(for: day(-1)) == .past)
        #expect(DayPosition(for: day(0)) == .today)
        #expect(DayPosition(for: day(1)) == .future)
    }

    @Test("Any time during today still counts as today")
    func todayIsWholeDay() {
        let earlyToday = calendar.date(byAdding: .minute, value: 1, to: day(0))!
        let lateToday = calendar.date(byAdding: .minute, value: -1, to: day(1))!

        #expect(DayPosition(for: earlyToday) == .today)
        #expect(DayPosition(for: lateToday) == .today)
    }
}
