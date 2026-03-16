import Testing
import Foundation
@testable import GutCheck

@MainActor
struct MealDetailViewModelTests {

    // MARK: - Test Helpers

    private func makeMeal(
        id: String = "meal-1",
        name: String = "Test Lunch",
        date: Date = Date.now,
        type: MealType = .lunch,
        source: MealSource = .manual,
        foodItems: [FoodItem] = [],
        notes: String? = "Some notes"
    ) -> Meal {
        Meal(id: id, name: name, date: date, type: type, source: source, foodItems: foodItems, notes: notes)
    }

    private func makeFoodItem(id: String = UUID().uuidString, name: String = "Apple") -> FoodItem {
        FoodItem(id: id, name: name, quantity: "1 serving")
    }

    // MARK: - Initialization

    @Test("Init with Meal sets properties correctly")
    func initWithMeal() {
        let meal = makeMeal(notes: "Tasty")
        let repo = MockMealRepository()
        let vm = MealDetailViewModel(meal: meal, mealRepository: repo)

        #expect(vm.meal.id == "meal-1")
        #expect(vm.meal.name == "Test Lunch")
        #expect(vm.mealId == "meal-1")
        #expect(vm.notes == "Tasty")
        #expect(!vm.isLoading)
        #expect(!vm.isEditing)
    }

    @Test("Init with meal ID sets loading state and empty meal")
    func initWithMealId() {
        let repo = MockMealRepository()
        let vm = MealDetailViewModel(mealId: "meal-99", mealRepository: repo)

        #expect(vm.mealId == "meal-99")
        #expect(vm.isLoading)
        #expect(vm.meal.name == "Loading...")
    }

    // MARK: - Load Meal

    @Test("loadMeal success updates meal and notes")
    func loadMealSuccess() async {
        let repo = MockMealRepository()
        let expected = makeMeal(id: "meal-99", name: "Loaded Meal", notes: "Loaded notes")
        repo.mealToReturn = expected

        let vm = MealDetailViewModel(mealId: "meal-99", mealRepository: repo)
        await vm.loadMeal()

        #expect(vm.meal.name == "Loaded Meal")
        #expect(vm.notes == "Loaded notes")
        #expect(!vm.isLoading)
        #expect(repo.fetchCallCount == 1)
    }

    @Test("loadMeal with nil mealId does nothing")
    func loadMealNilId() async {
        let meal = makeMeal()
        let repo = MockMealRepository()
        let vm = MealDetailViewModel(meal: meal, mealRepository: repo)

        await vm.loadMeal()

        #expect(repo.fetchCallCount == 0)
    }

    @Test("loadMeal not found sets error")
    func loadMealNotFound() async {
        let repo = MockMealRepository()
        repo.mealToReturn = nil

        let vm = MealDetailViewModel(mealId: "missing", mealRepository: repo)
        await vm.loadMeal()

        #expect(vm.showingErrorAlert)
        #expect(vm.errorMessage == "Could not find the meal")
        #expect(!vm.isLoading)
    }

    @Test("loadMeal error sets error message")
    func loadMealError() async {
        let repo = MockMealRepository()
        repo.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network failure"])

        let vm = MealDetailViewModel(mealId: "meal-1", mealRepository: repo)
        await vm.loadMeal()

        #expect(vm.showingErrorAlert)
        #expect(vm.errorMessage.contains("Network failure"))
        #expect(!vm.isLoading)
    }

    // MARK: - Save Meal

    @Test("saveMeal success saves to repo and returns true")
    func saveMealSuccess() async {
        let meal = makeMeal()
        let repo = MockMealRepository()
        let vm = MealDetailViewModel(meal: meal, mealRepository: repo)
        vm.isEditing = true

        let result = await vm.saveMeal()

        #expect(result)
        #expect(!vm.isEditing)
        #expect(!vm.isSaving)
        #expect(repo.savedMeals.count == 1)
        #expect(repo.savedMeals.first?.id == "meal-1")
    }

    @Test("saveMeal error returns false and sets error")
    func saveMealError() async {
        let meal = makeMeal()
        let repo = MockMealRepository()
        repo.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Save failed"])
        let vm = MealDetailViewModel(meal: meal, mealRepository: repo)

        let result = await vm.saveMeal()

        #expect(!result)
        #expect(vm.showingErrorAlert)
        #expect(vm.errorMessage.contains("Save failed"))
        #expect(!vm.isSaving)
    }

    @Test("saveMeal updates notes before saving")
    func saveMealUpdatesNotes() async {
        let meal = makeMeal(notes: nil)
        let repo = MockMealRepository()
        let vm = MealDetailViewModel(meal: meal, mealRepository: repo)
        vm.notes = "New notes"

        _ = await vm.saveMeal()

        #expect(repo.savedMeals.first?.notes == "New notes")
    }

    // MARK: - Delete Meal

    @Test("deleteMeal success calls repo delete and returns true")
    func deleteMealSuccess() async {
        let meal = makeMeal(id: "delete-me")
        let repo = MockMealRepository()
        let vm = MealDetailViewModel(meal: meal, mealRepository: repo)

        let result = await vm.deleteMeal()

        #expect(result)
        #expect(repo.deletedIds == ["delete-me"])
    }

    @Test("deleteMeal error returns false and sets error")
    func deleteMealError() async {
        let meal = makeMeal()
        let repo = MockMealRepository()
        repo.errorToThrow = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
        let vm = MealDetailViewModel(meal: meal, mealRepository: repo)

        let result = await vm.deleteMeal()

        #expect(!result)
        #expect(vm.showingErrorAlert)
        #expect(vm.errorMessage.contains("Delete failed"))
    }

    // MARK: - Update Notes

    @Test("updateNotes sets notes on meal")
    func updateNotesSetsNotes() {
        let meal = makeMeal(notes: nil)
        let repo = MockMealRepository()
        let vm = MealDetailViewModel(meal: meal, mealRepository: repo)

        vm.notes = "Hello world"
        vm.updateNotes()
        #expect(vm.meal.notes == "Hello world")
    }

    @Test("updateNotes with empty string sets nil")
    func updateNotesEmptySetsNil() {
        let meal = makeMeal(notes: "Old notes")
        let repo = MockMealRepository()
        let vm = MealDetailViewModel(meal: meal, mealRepository: repo)

        vm.notes = ""
        vm.updateNotes()
        #expect(vm.meal.notes == nil)
    }

    // MARK: - Food Item Operations

    @Test("updateFoodItem replaces matching item by id")
    func updateFoodItemReplacesById() {
        let item = makeFoodItem(id: "item-1", name: "Apple")
        let meal = makeMeal(foodItems: [item])
        let repo = MockMealRepository()
        let vm = MealDetailViewModel(meal: meal, mealRepository: repo)

        var updated = item
        updated.name = "Banana"
        vm.updateFoodItem(updated)

        #expect(vm.meal.foodItems.count == 1)
        #expect(vm.meal.foodItems.first?.name == "Banana")
    }

    @Test("removeFoodItem removes matching item by id")
    func removeFoodItemRemovesById() {
        let item1 = makeFoodItem(id: "item-1", name: "Apple")
        let item2 = makeFoodItem(id: "item-2", name: "Banana")
        let meal = makeMeal(foodItems: [item1, item2])
        let repo = MockMealRepository()
        let vm = MealDetailViewModel(meal: meal, mealRepository: repo)

        vm.removeFoodItem(item1)

        #expect(vm.meal.foodItems.count == 1)
        #expect(vm.meal.foodItems.first?.name == "Banana")
    }

    // MARK: - Computed Properties

    @Test("sourceDescription returns correct string for each source",
          arguments: [
            (MealSource.manual, "Manual Entry"),
            (MealSource.barcode, "Barcode Scan"),
            (MealSource.lidar, "LiDAR Scan"),
            (MealSource.ai, "AI Recognition")
          ])
    func sourceDescription(source: MealSource, expected: String) {
        let meal = makeMeal(source: source)
        let repo = MockMealRepository()
        let vm = MealDetailViewModel(meal: meal, mealRepository: repo)

        #expect(vm.sourceDescription == expected)
    }
}
