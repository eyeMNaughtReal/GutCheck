import Foundation

// Quick test of the FoodSearchService
@MainActor
class TestSearchRunner {
    func testSearch() async {
        print("🧪 Testing FoodSearchService...")
        let service = FoodSearchService()
        await service.searchFoods(query: "Apple")
        print("🧪 Test completed. Results: \(service.results.count)")
        for result in service.results {
            print("🧪 - \(result.name) (\(result.brand ?? "No brand"))")
        }
    }
}

// Run the test
Task {
    let tester = TestSearchRunner()
    await tester.testSearch()
}
