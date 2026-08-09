import Foundation

// MARK: - Nutrition Info
struct NutritionInfo: Codable, Hashable, Equatable {
    var calories: Int? = nil
    var protein: Double? = nil     // grams
    var carbs: Double? = nil       // grams
    var fat: Double? = nil         // grams
    var fiber: Double? = nil       // grams
    var sugar: Double? = nil       // grams
    var sodium: Double? = nil      // milligrams
}

// MARK: - Food Input Source
enum FoodInputSource: String, Codable {
    case manual
    case barcode
    case lidar
    case ai
}

// MARK: - Food Item
struct FoodItem: Identifiable, Codable, Hashable, Equatable {
    var nutritionDetails: [String: String] = [:]
    var id: String = UUID().uuidString
    var name: String
    var quantity: String                  // e.g., "1 cup", "3 oz"
    var estimatedWeightInGrams: Double?  // Optional for LiDAR or estimation
    var ingredients: [String] = []       // Optional parsed or entered
    var allergens: [String] = []         // e.g., ["dairy", "gluten"]
    var nutrition: NutritionInfo = NutritionInfo()
    var source: FoodInputSource = .manual
    var barcodeValue: String? = nil      // If scanned via barcode
    var isUserEdited: Bool = false       // Indicates manual override

    // MARK: - Serving size
    //
    // All three are optional so that meals written before serving selection
    // existed still decode: the synthesised decoder skips a missing optional
    // but throws on a missing non-optional, and `foodItems` is stored as a
    // JSON blob inside `StoredMeal`.

    /// Portions this food can be logged as, as offered by the search source.
    var servingOptions: [ServingOption]? = nil

    /// The portion `nutrition` and `nutritionDetails` currently describe.
    /// `nil` for items that predate serving selection or come from a source
    /// that named no portion at all.
    var selectedServing: ServingOption? = nil

    /// How many of `selectedServing` this item is. Kept as its own field
    /// rather than being read back out of `quantity`, which is display text.
    var servingCount: Double? = nil

    init(
        id: String = UUID().uuidString,
        name: String,
        quantity: String,
        estimatedWeightInGrams: Double? = nil,
        ingredients: [String] = [],
        allergens: [String] = [],
        nutrition: NutritionInfo = NutritionInfo(),
        source: FoodInputSource = .manual,
        barcodeValue: String? = nil,
        isUserEdited: Bool = false,
        nutritionDetails: [String: String] = [:],
        servingOptions: [ServingOption]? = nil,
        selectedServing: ServingOption? = nil,
        servingCount: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.estimatedWeightInGrams = estimatedWeightInGrams
        self.ingredients = ingredients
        self.allergens = allergens
        self.nutrition = nutrition
        self.source = source
        self.barcodeValue = barcodeValue
        self.isUserEdited = isUserEdited
        self.nutritionDetails = nutritionDetails
        self.servingOptions = servingOptions
        self.selectedServing = selectedServing
        self.servingCount = servingCount
    }

    /// The weight `nutrition` currently describes, when it is known.
    var servingGrams: Double? {
        guard let selectedServing else { return estimatedWeightInGrams }
        return selectedServing.gramWeight * (servingCount ?? 1)
    }
}
