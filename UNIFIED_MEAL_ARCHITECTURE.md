# Unified Meal Architecture - Design Proposal

## 🎯 Problem Statement

Currently, the app has **three different patterns** for adding food items to meals:

1. **MealBuilder Singleton**: `MealBuilder.shared.addFoodItem(foodItem)`
2. **Callback-Based**: `onAdd: (FoodItem) -> Void` passed through views
3. **Direct Manipulation**: `viewModel.foodItems.append(selectedFood)`

This leads to:
- ❌ Inconsistent behavior across features
- ❌ Navigation bugs (modals not dismissing properly)
- ❌ Difficult maintenance and testing
- ❌ State synchronization issues

## ✅ Proposed Unified Solution

### **Single Source of Truth: MealBuilderService**

Create a centralized service that handles all meal building operations:

```swift
// Services/MealBuilderService.swift
@MainActor
class MealBuilderService: ObservableObject {
    static let shared = MealBuilderService()
    
    @Published var currentMeal: [FoodItem] = []
    @Published var mealType: MealType = .lunch
    @Published var mealDate: Date = Date()
    @Published var mealName: String = ""
    @Published var notes: String = ""
    
    private init() {}
    
    // MARK: - Core Operations
    func addFoodItem(_ item: FoodItem) {
        currentMeal.append(item)
    }
    
    func removeFoodItem(_ item: FoodItem) {
        currentMeal.removeAll { $0.id == item.id }
    }
    
    func updateFoodItem(_ item: FoodItem) {
        if let index = currentMeal.firstIndex(where: { $0.id == item.id }) {
            currentMeal[index] = item
        }
    }
    
    func clearMeal() {
        currentMeal.removeAll()
        mealName = ""
        notes = ""
        mealDate = Date()
    }
    
    // MARK: - Save Operations
    func saveMeal() async throws -> Meal {
        // Create and save meal using MealRepository
        // Return saved meal for navigation
    }
}
```

### **Unified "Add to Meal" Protocol**

Every feature that adds food items implements the same pattern:

```swift
// Protocol for any view that can add food items
protocol FoodItemAddable {
    func addToMeal(_ foodItem: FoodItem)
}

// Default implementation
extension FoodItemAddable {
    func addToMeal(_ foodItem: FoodItem) {
        MealBuilderService.shared.addFoodItem(foodItem)
        // Handle navigation/dismissal consistently
    }
}
```

## 🏗️ Implementation Strategy

### **Phase 1: Core Service**
1. Create `MealBuilderService.swift`
2. Replace `MealBuilder` singleton with new service
3. Update all ViewModels to use service

### **Phase 2: Standardize View Patterns**
1. Update `EnhancedFoodItemDetailView` to use service directly
2. Standardize modal dismissal behavior
3. Update all "Add to Meal" buttons to use same pattern

### **Phase 3: Navigation Consistency**
1. Standardize how modals dismiss after adding items
2. Ensure consistent navigation flow across all features
3. Add uniform loading states and error handling

## 📁 File Changes Required

### **New Files:**
- `Services/MealBuilderService.swift` - Central meal building service
- `Protocols/FoodItemAddable.swift` - Protocol for consistent behavior

### **Updated Files:**
- `ViewModels/Meal/BarcodeScannerViewModel.swift` - Use service
- `ViewModels/Meal/FoodSearchViewModel.swift` - Use service  
- `Views/Components/EnhancedFoodItemDetailView.swift` - Use service directly
- `Views/Meal/SmartFoodScannerView.swift` - Use service
- `Views/Meal/MealLoggingOptionsView.swift` - Use service
- All meal-related ViewModels and Views

## 🎯 Benefits

### **Consistency**
- ✅ Same "add to meal" behavior everywhere
- ✅ Predictable navigation patterns
- ✅ Uniform error handling

### **Maintainability**
- ✅ Single place to modify meal building logic
- ✅ Easier testing with centralized state
- ✅ Clear separation of concerns

### **User Experience**
- ✅ Consistent modal dismissal behavior
- ✅ Reliable navigation flows
- ✅ Predictable app behavior

### **Developer Experience**
- ✅ Clear pattern to follow for new features
- ✅ Less duplicated code
- ✅ Easier debugging

## 🚀 Migration Plan

1. **Create MealBuilderService** - New centralized service
2. **Update ViewModels** - Replace MealBuilder usage with service
3. **Standardize Views** - Update all "Add to Meal" implementations
4. **Test Navigation** - Verify consistent modal dismissal
5. **Remove Old Code** - Clean up MealBuilder singleton

This unified approach ensures that whether a user scans a barcode, searches for food, or uses LiDAR enhancement, the "add to meal" experience is **identical and reliable**.

---

**Next Step**: Implement `MealBuilderService` and begin migration to unified pattern.
