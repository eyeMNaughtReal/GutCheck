import Foundation
import SwiftUI

// Simple test to verify search functionality
struct SearchTestView: View {
    @StateObject private var searchService = FoodSearchService()
    @StateObject private var viewModel = FoodSearchViewModel()
    @State private var testResults: [NutritionixFood] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Search Test")
                .font(.title)
            
            Button("Test Search with Apple") {
                Task {
                    await testSearch()
                }
            }
            .buttonStyle(.borderedProminent)
            
            if isLoading {
                ProgressView("Searching...")
            }
            
            if !errorMessage.isEmpty {
                Text("Error: \(errorMessage)")
                    .foregroundStyle(.red)
            }
            
            Text("Results: \(testResults.count)")
            
            ForEach(testResults, id: \.id) { result in
                VStack(alignment: .leading) {
                    Text(result.name)
                        .font(.headline)
                    Text("Brand: \(result.brand ?? "No brand")")
                    Text("Calories: \(result.calories ?? 0, specifier: "%.1f")")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func testSearch() async {
        print("🔍 Starting search test...")
        isLoading = true
        errorMessage = ""
        testResults = []
        
        print("🔍 Calling searchFoods with query: 'apple'")
        await searchService.searchFoods(query: "apple")
        
        await MainActor.run {
            print("🔍 Search completed with \(searchService.results.count) results")
            self.testResults = searchService.results
            self.isLoading = false
        }
    }
}

#Preview {
    SearchTestView()
}
