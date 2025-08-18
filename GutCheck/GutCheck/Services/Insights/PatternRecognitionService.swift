import Foundation
import HealthKit

/// Service for analyzing patterns in health data to generate insights
class PatternRecognitionService {
    static let shared = PatternRecognitionService()
    
    private init() {}
    
    // MARK: - Main Analysis Methods
    
    /// Analyzes patterns across all data types for a given time range
    func analyzePatterns(
        meals: [Meal],
        symptoms: [Symptom],
        healthData: GutHealthData?,
        timeRange: DateInterval
    ) async -> PatternAnalysisResult {
        
        let foodTriggers = await analyzeFoodTriggers(meals: meals, symptoms: symptoms)
        let temporalPatterns = await analyzeTemporalPatterns(meals: meals, symptoms: symptoms)
        let lifestyleCorrelations = await analyzeLifestyleCorrelations(
            meals: meals,
            symptoms: symptoms,
            healthData: healthData
        )
        let nutritionTrends = await analyzeNutritionTrends(meals: meals)
        
        return PatternAnalysisResult(
            foodTriggers: foodTriggers,
            temporalPatterns: temporalPatterns,
            lifestyleCorrelations: lifestyleCorrelations,
            nutritionTrends: nutritionTrends,
            timeRange: timeRange
        )
    }
    
    // MARK: - Food Trigger Analysis
    
    private func analyzeFoodTriggers(meals: [Meal], symptoms: [Symptom]) async -> [FoodTriggerInsight] {
        var triggers: [FoodTriggerInsight] = []
        
        // Group symptoms by time to find meal-symptom correlations
        let symptomTimeMap = Dictionary(grouping: symptoms) { symptom in
            Calendar.current.startOfDay(for: symptom.date)
        }
        
        for meal in meals {
            let mealDate = Calendar.current.startOfDay(for: meal.date)
            let symptomsOnMealDay = symptomTimeMap[mealDate] ?? []
            
            // Look for symptoms within 2-8 hours after meal
            let relevantSymptoms = symptomsOnMealDay.filter { symptom in
                let timeDifference = symptom.date.timeIntervalSince(meal.date)
                return timeDifference >= 7200 && timeDifference <= 28800 // 2-8 hours
            }
            
            if !relevantSymptoms.isEmpty {
                // Analyze each food item in the meal
                for foodItem in meal.foodItems {
                    let trigger = await analyzeFoodItemTrigger(
                        foodItem: foodItem,
                        symptoms: relevantSymptoms,
                        meal: meal
                    )
                    
                    if let trigger = trigger {
                        // Check if we already have this trigger
                        if let existingIndex = triggers.firstIndex(where: { $0.foodName == trigger.foodName }) {
                            // Update existing trigger with more evidence
                            triggers[existingIndex] = triggers[existingIndex].withAdditionalEvidence(trigger)
                        } else {
                            triggers.append(trigger)
                        }
                    }
                }
            }
        }
        
        // Sort by confidence and return top triggers
        return triggers.sorted { $0.confidence > $1.confidence }
    }
    
    private func analyzeFoodItemTrigger(
        foodItem: FoodItem,
        symptoms: [Symptom],
        meal: Meal
    ) async -> FoodTriggerInsight? {
        
        // Calculate correlation strength
        let correlationScore = calculateSymptomCorrelation(foodItem: foodItem, symptoms: symptoms)
        
        // Only return triggers with meaningful correlation
        guard correlationScore > 0.3 else { return nil }
        
        // Analyze food compounds for additional insights
        let compounds = FoodCompoundDatabase.shared.analyzeIngredients([foodItem.name])
        let highRiskCompounds = compounds.filter { $0.severity == .high }
        
        let confidence = calculateTriggerConfidence(
            correlationScore: correlationScore,
            symptomCount: symptoms.count,
            compoundRisk: highRiskCompounds.count
        )
        
        let recommendations = generateTriggerRecommendations(
            foodItem: foodItem,
            symptoms: symptoms,
            compounds: compounds
        )
        
        return FoodTriggerInsight(
            foodName: foodItem.name,
            confidence: confidence,
            correlationScore: correlationScore,
            symptomCount: symptoms.count,
            timeWindow: "2-8 hours",
            highRiskCompounds: highRiskCompounds,
            recommendations: recommendations,
            lastOccurrence: meal.date
        )
    }
    
    // MARK: - Temporal Pattern Analysis
    
    private func analyzeTemporalPatterns(meals: [Meal], symptoms: [Symptom]) async -> [TemporalPatternInsight] {
        var patterns: [TemporalPatternInsight] = []
        
        // Time of day patterns
        let timePatterns = analyzeTimeOfDayPatterns(symptoms: symptoms)
        patterns.append(contentsOf: timePatterns)
        
        // Day of week patterns
        let dayPatterns = analyzeDayOfWeekPatterns(symptoms: symptoms)
        patterns.append(contentsOf: dayPatterns)
        
        // Meal timing patterns
        let mealTimingPatterns = analyzeMealTimingPatterns(meals: meals, symptoms: symptoms)
        patterns.append(contentsOf: mealTimingPatterns)
        
        return patterns.sorted { $0.confidence > $1.confidence }
    }
    
    private func analyzeTimeOfDayPatterns(symptoms: [Symptom]) -> [TemporalPatternInsight] {
        var patterns: [TemporalPatternInsight] = []
        
        // Group symptoms by hour of day
        let hourGroups = Dictionary(grouping: symptoms) { symptom in
            Calendar.current.component(.hour, from: symptom.date)
        }
        
        // Find peak symptom times
        let sortedHours = hourGroups.sorted { $0.value.count > $1.value.count }
        
        if let peakHour = sortedHours.first, peakHour.value.count >= 3 {
            let confidence = min(0.95, Double(peakHour.value.count) / Double(symptoms.count) + 0.3)
            
            patterns.append(TemporalPatternInsight(
                type: .timeOfDay,
                title: "Peak Symptom Time",
                description: "Symptoms are most frequent around \(peakHour.key):00",
                confidence: confidence,
                evidence: [
                    "\(peakHour.value.count) out of \(symptoms.count) symptoms occur at this time",
                    "Peak hour: \(peakHour.key):00"
                ],
                recommendations: [
                    "Monitor activities around \(peakHour.key):00",
                    "Consider meal timing adjustments",
                    "Check for environmental triggers"
                ]
            ))
        }
        
        return patterns
    }
    
    private func analyzeDayOfWeekPatterns(symptoms: [Symptom]) -> [TemporalPatternInsight] {
        var patterns: [TemporalPatternInsight] = []
        
        // Group symptoms by day of week
        let dayGroups = Dictionary(grouping: symptoms) { symptom in
            Calendar.current.component(.weekday, from: symptom.date)
        }
        
        // Find problematic days
        let sortedDays = dayGroups.sorted { $0.value.count > $1.value.count }
        
        if let worstDay = sortedDays.first, worstDay.value.count >= 2 {
            let dayName = Calendar.current.weekdaySymbols[worstDay.key - 1]
            let confidence = min(0.95, Double(worstDay.value.count) / Double(symptoms.count) + 0.2)
            
            patterns.append(TemporalPatternInsight(
                type: .dayOfWeek,
                title: "Problematic Day Pattern",
                description: "Symptoms are more frequent on \(dayName)s",
                confidence: confidence,
                evidence: [
                    "\(worstDay.value.count) symptoms on \(dayName)s",
                    "Day of week: \(dayName)"
                ],
                recommendations: [
                    "Plan meals carefully on \(dayName)s",
                    "Consider stress factors on this day",
                    "Monitor sleep quality the night before"
                ]
            ))
        }
        
        return patterns
    }
    
    private func analyzeMealTimingPatterns(meals: [Meal], symptoms: [Symptom]) -> [TemporalPatternInsight] {
        var patterns: [TemporalPatternInsight] = []
        
        // Analyze meal-to-symptom timing
        let mealSymptomPairs = findMealSymptomPairs(meals: meals, symptoms: symptoms)
        
        if mealSymptomPairs.count >= 3 {
            let averageDelay = mealSymptomPairs.map { $0.timeDelay }.reduce(0, +) / Double(mealSymptomPairs.count)
            let delayHours = Int(averageDelay / 3600)
            
            patterns.append(TemporalPatternInsight(
                type: .mealTiming,
                title: "Meal-Symptom Timing",
                description: "Symptoms typically occur \(delayHours) hours after meals",
                confidence: 0.8,
                evidence: [
                    "Average delay: \(delayHours) hours",
                    "Based on \(mealSymptomPairs.count) observations"
                ],
                recommendations: [
                    "Monitor symptoms \(delayHours) hours after eating",
                    "Consider meal size and composition",
                    "Track specific foods consumed"
                ]
            ))
        }
        
        return patterns
    }
    
    // MARK: - Lifestyle Correlation Analysis
    
    private func analyzeLifestyleCorrelations(
        meals: [Meal],
        symptoms: [Symptom],
        healthData: GutHealthData?
    ) async -> [LifestyleCorrelationInsight] {
        var correlations: [LifestyleCorrelationInsight] = []
        
        // Exercise correlations
        if let healthData = healthData {
            let exerciseCorrelations = analyzeExerciseCorrelations(
                symptoms: symptoms,
                stepData: healthData.stepCountData
            )
            correlations.append(contentsOf: exerciseCorrelations)
            
            // Sleep correlations
            let sleepCorrelations = analyzeSleepCorrelations(
                symptoms: symptoms,
                sleepData: healthData.sleepData
            )
            correlations.append(contentsOf: sleepCorrelations)
        }
        
        // Stress correlations (based on symptom timing and frequency)
        let stressCorrelations = analyzeStressCorrelations(symptoms: symptoms)
        correlations.append(contentsOf: stressCorrelations)
        
        return correlations.sorted { $0.confidence > $1.confidence }
    }
    
    private func analyzeExerciseCorrelations(
        symptoms: [Symptom],
        stepData: [HKSample]
    ) -> [LifestyleCorrelationInsight] {
        var correlations: [LifestyleCorrelationInsight] = []
        
        // Group symptoms by day and correlate with step count
        let symptomDays = Set(symptoms.map { Calendar.current.startOfDay(for: $0.date) })
        
        for symptomDay in symptomDays {
            let symptomsOnDay = symptoms.filter { Calendar.current.isDate($0.date, inSameDayAs: symptomDay) }
            
            // Analyze step count correlation with symptoms
            let stepsOnDay = stepData.filter { Calendar.current.isDate($0.startDate, inSameDayAs: symptomDay) }
            
            if !stepsOnDay.isEmpty {
                let totalSteps = stepsOnDay.compactMap { stepSample -> Double? in
                    guard let stepSample = stepSample as? HKQuantitySample else { return nil }
                    let stepCount = stepSample.quantity.doubleValue(for: .count())
                    return stepCount
                }.reduce(0, +)
                
                if totalSteps < 5000 {
                    correlations.append(LifestyleCorrelationInsight(
                        factor: "Exercise",
                        impact: .negative,
                        confidence: 0.75,
                        title: "Low Exercise Impact",
                        description: "Low step count (< 5,000 steps) on symptom days",
                        evidence: [
                            "Symptoms: \(symptomsOnDay.count)",
                            "Total steps on symptom day: \(Int(totalSteps))"
                        ],
                        recommendations: [
                            "Aim for 5,000+ steps daily",
                            "Try morning walks before meals",
                            "Consider moderate exercise 30+ minutes"
                        ]
                    ))
                }
            }
        }
        
        return correlations
    }
    
    private func analyzeSleepCorrelations(
        symptoms: [Symptom],
        sleepData: [HKSample]
    ) -> [LifestyleCorrelationInsight] {
        var correlations: [LifestyleCorrelationInsight] = []
        
        // Analyze sleep quality vs symptom frequency
        let sleepDays = Dictionary(grouping: sleepData) { sample in
            Calendar.current.startOfDay(for: sample.startDate)
        }
        
        for (sleepDay, sleepSamples) in sleepDays {
            let symptomsOnDay = symptoms.filter { Calendar.current.isDate($0.date, inSameDayAs: sleepDay) }
            
            // Calculate total sleep duration
            let totalSleep = sleepSamples.reduce(0) { total, sample in
                total + sample.endDate.timeIntervalSince(sample.startDate)
            }
            
            let sleepHours = totalSleep / 3600
            
            if sleepHours < 6 && symptomsOnDay.count > 0 {
                correlations.append(LifestyleCorrelationInsight(
                    factor: "Sleep",
                    impact: .negative,
                    confidence: 0.8,
                    title: "Sleep Deprivation Impact",
                    description: "Short sleep (\(String(format: "%.1f", sleepHours))h) correlates with symptoms",
                    evidence: [
                        "Sleep duration: \(String(format: "%.1f", sleepHours)) hours",
                        "Symptoms: \(symptomsOnDay.count)"
                    ],
                    recommendations: [
                        "Aim for 7-9 hours of sleep",
                        "Establish consistent sleep schedule",
                        "Avoid large meals before bedtime"
                    ]
                ))
            }
        }
        
        return correlations
    }
    
    private func analyzeStressCorrelations(symptoms: [Symptom]) -> [LifestyleCorrelationInsight] {
        var correlations: [LifestyleCorrelationInsight] = []
        
        // Analyze symptom clustering (multiple symptoms in short time = stress)
        let symptomDays = Dictionary(grouping: symptoms) { symptom in
            Calendar.current.startOfDay(for: symptom.date)
        }
        
        for (day, daySymptoms) in symptomDays {
            if daySymptoms.count >= 3 {
                // Multiple symptoms in one day might indicate stress
                correlations.append(LifestyleCorrelationInsight(
                    factor: "Stress",
                    impact: .negative,
                    confidence: 0.7,
                    title: "High Symptom Day",
                    description: "Multiple symptoms on \(daySymptoms.count) occasions",
                    evidence: [
                        "Symptoms: \(daySymptoms.count)",
                        "Date: \(DateFormatter.shortDate.string(from: day))"
                    ],
                    recommendations: [
                        "Practice stress management techniques",
                        "Consider meditation or deep breathing",
                        "Review recent life changes or stressors"
                    ]
                ))
            }
        }
        
        return correlations
    }
    
    // MARK: - Nutrition Trend Analysis
    
    private func analyzeNutritionTrends(meals: [Meal]) async -> [NutritionTrendInsight] {
        var trends: [NutritionTrendInsight] = []
        
        // Analyze fiber intake trends
        let fiberTrend = analyzeFiberTrend(meals: meals)
        if let fiberTrend = fiberTrend {
            trends.append(fiberTrend)
        }
        
        // Analyze hydration trends
        let hydrationTrend = analyzeHydrationTrend(meals: meals)
        if let hydrationTrend = hydrationTrend {
            trends.append(hydrationTrend)
        }
        
        // Analyze meal timing consistency
        let timingTrend = analyzeMealTimingConsistency(meals: meals)
        if let timingTrend = timingTrend {
            trends.append(timingTrend)
        }
        
        return trends.sorted { $0.confidence > $1.confidence }
    }
    
    private func analyzeFiberTrend(meals: [Meal]) -> NutritionTrendInsight? {
        let totalFiber = meals.reduce(0) { total, meal in
            total + (meal.foodItems.reduce(0) { mealTotal, food in
                mealTotal + (food.nutrition.fiber ?? 0)
            })
        }
        
        let averageDailyFiber = totalFiber / 7
        
        if averageDailyFiber < 25 {
            return NutritionTrendInsight(
                type: .fiber,
                title: "Low Fiber Intake",
                description: "Daily fiber intake below recommended levels",
                confidence: 0.9,
                currentValue: averageDailyFiber,
                targetValue: 25,
                unit: "g",
                evidence: [
                    "Average daily fiber: \(String(format: "%.1f", averageDailyFiber))g",
                    "Recommended: 25g+ daily"
                ],
                recommendations: [
                    "Add more fruits and vegetables",
                    "Choose whole grains over refined",
                    "Include legumes and nuts"
                ]
            )
        }
        
        return nil
    }
    
    private func analyzeHydrationTrend(meals: [Meal]) -> NutritionTrendInsight? {
        // For now, skip water analysis since NutritionInfo doesn't have water property
        // TODO: Add water tracking to NutritionInfo or use HealthKit water data
        return nil
    }
    
    private func analyzeMealTimingConsistency(meals: [Meal]) -> NutritionTrendInsight? {
        let recentMeals = meals.filter { $0.date > Date().addingTimeInterval(-7 * 24 * 3600) }
        
        let mealHours = recentMeals.map { Calendar.current.component(.hour, from: $0.date) }
        let mealCounts = Dictionary(grouping: mealHours, by: { $0 }).mapValues { $0.count }
        
        let mostCommonHour = mealCounts.max { $0.value < $1.value }
        
        if let commonHour = mostCommonHour, commonHour.value >= 4 {
            return NutritionTrendInsight(
                type: .mealTiming,
                title: "Meal Timing Pattern",
                description: "Most meals occur around \(commonHour.key):00",
                confidence: 0.8,
                currentValue: Double(commonHour.value),
                targetValue: 7,
                unit: "meals",
                evidence: [
                    "Most common meal time: \(commonHour.key):00",
                    "Frequency: \(commonHour.value) times this week"
                ],
                recommendations: [
                    "Consider spreading meals more evenly",
                    "Avoid large gaps between meals",
                    "Maintain consistent meal schedule"
                ]
            )
        }
        
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func calculateSymptomCorrelation(foodItem: FoodItem, symptoms: [Symptom]) -> Double {
        // Simple correlation based on symptom frequency and food consumption
        let totalSymptoms = symptoms.count
        let foodConsumptionFrequency = 1.0 // For now, assume 1 meal with this food
        
        // Basic correlation calculation
        return min(1.0, Double(totalSymptoms) * foodConsumptionFrequency / 10.0)
    }
    
    private func calculateTriggerConfidence(
        correlationScore: Double,
        symptomCount: Int,
        compoundRisk: Int
    ) -> Double {
        var confidence = correlationScore
        
        // Boost confidence with more symptoms
        if symptomCount >= 3 {
            confidence += 0.2
        } else if symptomCount >= 2 {
            confidence += 0.1
        }
        
        // Boost confidence with high-risk compounds
        if compoundRisk >= 2 {
            confidence += 0.15
        } else if compoundRisk >= 1 {
            confidence += 0.1
        }
        
        return min(0.95, confidence)
    }
    
    private func generateTriggerRecommendations(
        foodItem: FoodItem,
        symptoms: [Symptom],
        compounds: [FoodCompound]
    ) -> [String] {
        var recommendations: [String] = []
        
        // Basic recommendations
        recommendations.append("Eliminate \(foodItem.name) for 2-4 weeks")
        recommendations.append("Reintroduce gradually to test tolerance")
        
        // Compound-specific recommendations
        if compounds.contains(where: { $0.severity == .high }) {
            recommendations.append("Consider professional allergy testing")
            recommendations.append("Monitor for systemic reactions")
        }
        
        // Timing recommendations
        if symptoms.count >= 2 {
            recommendations.append("Track timing of symptoms after consumption")
            recommendations.append("Note portion sizes and combinations")
        }
        
        return recommendations
    }
    
    private func findMealSymptomPairs(meals: [Meal], symptoms: [Symptom]) -> [MealSymptomPair] {
        var pairs: [MealSymptomPair] = []
        
        for meal in meals {
            for symptom in symptoms {
                let timeDelay = symptom.date.timeIntervalSince(meal.date)
                
                // Only consider symptoms that occur 1-12 hours after meal
                if timeDelay >= 3600 && timeDelay <= 43200 {
                    pairs.append(MealSymptomPair(
                        meal: meal,
                        symptom: symptom,
                        timeDelay: timeDelay
                    ))
                }
            }
        }
        
        return pairs
    }
}

// MARK: - Supporting Types

struct PatternAnalysisResult {
    let foodTriggers: [FoodTriggerInsight]
    let temporalPatterns: [TemporalPatternInsight]
    let lifestyleCorrelations: [LifestyleCorrelationInsight]
    let nutritionTrends: [NutritionTrendInsight]
    let timeRange: DateInterval
}

struct FoodTriggerInsight: Identifiable {
    let id = UUID()
    let foodName: String
    let confidence: Double
    let correlationScore: Double
    let symptomCount: Int
    let timeWindow: String
    let highRiskCompounds: [FoodCompound]
    let recommendations: [String]
    let lastOccurrence: Date
    
    func withAdditionalEvidence(_ newTrigger: FoodTriggerInsight) -> FoodTriggerInsight {
        FoodTriggerInsight(
            foodName: foodName,
            confidence: min(0.95, confidence + 0.1),
            correlationScore: (correlationScore + newTrigger.correlationScore) / 2,
            symptomCount: symptomCount + newTrigger.symptomCount,
            timeWindow: timeWindow,
            highRiskCompounds: highRiskCompounds,
            recommendations: recommendations,
            lastOccurrence: max(lastOccurrence, newTrigger.lastOccurrence)
        )
    }
}

struct TemporalPatternInsight: Identifiable {
    let id = UUID()
    let type: TemporalPatternType
    let title: String
    let description: String
    let confidence: Double
    let evidence: [String]
    let recommendations: [String]
    
    enum TemporalPatternType: String, CaseIterable {
        case timeOfDay = "Time of Day"
        case dayOfWeek = "Day of Week"
        case mealTiming = "Meal Timing"
    }
}

struct LifestyleCorrelationInsight: Identifiable {
    let id = UUID()
    let factor: String
    let impact: CorrelationImpact
    let confidence: Double
    let title: String
    let description: String
    let evidence: [String]
    let recommendations: [String]
    
    enum CorrelationImpact {
        case positive
        case negative
        case neutral
    }
}

struct NutritionTrendInsight: Identifiable {
    let id = UUID()
    let type: NutritionTrendType
    let title: String
    let description: String
    let confidence: Double
    let currentValue: Double
    let targetValue: Double
    let unit: String
    let evidence: [String]
    let recommendations: [String]
    
    enum NutritionTrendType {
        case fiber
        case hydration
        case mealTiming
    }
}

struct MealSymptomPair {
    let meal: Meal
    let symptom: Symptom
    let timeDelay: TimeInterval
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}
