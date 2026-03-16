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
                    description: "Short sleep (\(sleepHours.formatted(.number.precision(.fractionLength(1))))h) correlates with symptoms",
                    evidence: [
                        "Sleep duration: \(sleepHours.formatted(.number.precision(.fractionLength(1)))) hours",
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
                    "Average daily fiber: \(averageDailyFiber.formatted(.number.precision(.fractionLength(1))))g",
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
        let recentMeals = meals.filter { $0.date > Date.now.addingTimeInterval(-7 * 24 * 3600) }
        
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
    
    // MARK: - Trigger Pattern Analysis

    /// Produces rich TriggerPattern objects with composite scoring, severity prediction,
    /// ingredient decomposition, and natural language summary insights.
    func analyzeTriggerPatterns(meals: [Meal], symptoms: [Symptom]) async -> [TriggerPattern] {
        // Build per-food correlation data using 2-8 hour window
        var foodCorrelations: [String: (
            meals: [Meal],
            correlatedSymptoms: [Symptom],
            onsetDelays: [TimeInterval],
            foodItems: [FoodItem]
        )] = [:]

        // Count total occurrences of each food across all meals
        var foodTotalOccurrences: [String: Int] = [:]
        for meal in meals {
            for item in meal.foodItems {
                let key = item.name.lowercased().trimmingCharacters(in: .whitespaces)
                foodTotalOccurrences[key, default: 0] += 1
            }
        }

        for meal in meals {
            // Find symptoms in 2-8 hour window after this meal
            let relevantSymptoms = symptoms.filter { symptom in
                guard symptom.painLevel != .none || symptom.urgencyLevel != .none
                        || symptom.stoolType == .type1 || symptom.stoolType == .type2
                        || symptom.stoolType == .type6 || symptom.stoolType == .type7 else {
                    return false
                }
                let delay = symptom.date.timeIntervalSince(meal.date)
                return delay >= 7200 && delay <= 28800
            }

            guard !relevantSymptoms.isEmpty else { continue }

            for item in meal.foodItems {
                let key = item.name.lowercased().trimmingCharacters(in: .whitespaces)
                var entry = foodCorrelations[key] ?? (meals: [], correlatedSymptoms: [], onsetDelays: [], foodItems: [])
                entry.meals.append(meal)
                entry.correlatedSymptoms.append(contentsOf: relevantSymptoms)
                for symptom in relevantSymptoms {
                    entry.onsetDelays.append(symptom.date.timeIntervalSince(meal.date))
                }
                if entry.foodItems.isEmpty || entry.foodItems.first?.name != item.name {
                    entry.foodItems.append(item)
                }
                foodCorrelations[key] = entry
            }
        }

        // Build TriggerPattern for each food with sufficient data
        var patterns: [TriggerPattern] = []

        for (key, data) in foodCorrelations {
            let triggeringCount = data.meals.count
            let totalCount = foodTotalOccurrences[key] ?? triggeringCount
            guard triggeringCount >= 2 else { continue }

            let displayName = data.foodItems.first?.name ?? key
            let ingredients = data.foodItems.first?.ingredients ?? []

            // Compute components
            let correlationStrength = computeCorrelationStrength(
                triggeringCount: triggeringCount,
                totalCount: totalCount,
                symptomCount: data.correlatedSymptoms.count
            )
            let severityAvg = computeSeverityAverage(symptoms: data.correlatedSymptoms)
            let recurrenceRate = Double(triggeringCount) / Double(max(1, totalCount))
            let compoundRisk = computeCompoundRiskScore(foodName: displayName, ingredients: ingredients)

            let score = computeTriggerScore(
                correlation: correlationStrength,
                severity: severityAvg,
                recurrence: recurrenceRate,
                compound: compoundRisk
            )

            let prediction = predictSeverity(correlatedSymptoms: data.correlatedSymptoms)
            let timing = computeTimingProfile(onsetDelays: data.onsetDelays)
            let ingredientBreakdown = decomposeIngredients(
                foodName: displayName,
                ingredients: ingredients,
                allMeals: meals,
                correlatedSymptoms: data.correlatedSymptoms
            )
            let summaries = generateSummaryInsights(
                foodName: displayName,
                symptoms: data.correlatedSymptoms,
                timing: timing,
                score: score
            )
            let symptomLabels = buildSymptomLabels(from: data.correlatedSymptoms)
            let recommendations = buildTriggerRecommendations(
                foodName: displayName,
                score: score,
                prediction: prediction,
                ingredients: ingredientBreakdown
            )

            let sortedDates = data.meals.map(\.date).sorted()
            let trend: TrendDirection = {
                let midpoint = sortedDates.count / 2
                guard midpoint > 0 else { return .stable }
                let recentCount = sortedDates.suffix(midpoint).count
                let earlyCount = sortedDates.prefix(midpoint).count
                if recentCount > earlyCount { return .worsening }
                if recentCount < earlyCount { return .improving }
                return .stable
            }()

            patterns.append(TriggerPattern(
                id: UUID(),
                foodName: displayName,
                triggerScore: score,
                severityPrediction: prediction,
                ingredientBreakdown: ingredientBreakdown,
                timingProfile: timing,
                summaryInsights: summaries,
                associatedSymptomLabels: symptomLabels,
                totalObservations: totalCount,
                triggeringObservations: triggeringCount,
                recommendations: recommendations,
                lastOccurrence: sortedDates.last ?? .now,
                firstOccurrence: sortedDates.first ?? .now,
                trendDirection: trend
            ))
        }

        return patterns.sorted { $0.triggerScore.overall > $1.triggerScore.overall }
            .prefix(20).map { $0 }
    }

    // MARK: - Trigger Score Computation

    private func computeTriggerScore(
        correlation: Double,
        severity: Double,
        recurrence: Double,
        compound: Double
    ) -> TriggerScore {
        let overall = Int(
            (correlation * 0.35 + severity * 0.25 + recurrence * 0.25 + compound * 0.15) * 100
        )
        return TriggerScore(
            overall: min(100, max(0, overall)),
            correlationComponent: correlation,
            severityComponent: severity,
            recurrenceComponent: recurrence,
            compoundRiskComponent: compound
        )
    }

    private func computeCorrelationStrength(triggeringCount: Int, totalCount: Int, symptomCount: Int) -> Double {
        let baseRate = Double(triggeringCount) / Double(max(1, totalCount))
        let symptomFactor = min(1.0, Double(symptomCount) / 10.0)
        return min(1.0, baseRate * 0.7 + symptomFactor * 0.3)
    }

    private func computeSeverityAverage(symptoms: [Symptom]) -> Double {
        guard !symptoms.isEmpty else { return 0 }
        let total = symptoms.reduce(0.0) { sum, symptom in
            let painScore = Double(symptom.painLevel.rawValue) / 3.0 * 0.5
            let urgencyScore = Double(symptom.urgencyLevel.rawValue) / 3.0 * 0.3
            let stoolScore: Double = {
                switch symptom.stoolType {
                case .type1, .type2, .type6, .type7: return 0.2
                default: return 0.0
                }
            }()
            return sum + painScore + urgencyScore + stoolScore
        }
        return total / Double(symptoms.count)
    }

    private func computeCompoundRiskScore(foodName: String, ingredients: [String]) -> Double {
        let compounds = FoodCompoundDatabase.shared.getCompoundsForFood(name: foodName, ingredients: ingredients)
        guard !compounds.isEmpty else { return 0 }
        let highCount = compounds.filter { $0.severity == .high }.count
        let medCount = compounds.filter { $0.severity == .medium }.count
        return min(1.0, Double(highCount) * 0.3 + Double(medCount) * 0.15)
    }

    // MARK: - Severity Prediction

    private func predictSeverity(correlatedSymptoms: [Symptom]) -> SeverityPrediction {
        guard !correlatedSymptoms.isEmpty else {
            return SeverityPrediction(
                mostLikelyPainLevel: .none,
                mostLikelyUrgencyLevel: .none,
                painDistribution: [:],
                urgencyDistribution: [:],
                stoolRisk: .normal,
                confidence: 0
            )
        }

        let total = Double(correlatedSymptoms.count)

        // Pain distribution
        var painCounts: [PainLevel: Int] = [:]
        var urgencyCounts: [UrgencyLevel: Int] = [:]
        var constipationCount = 0
        var looseCount = 0

        for symptom in correlatedSymptoms {
            painCounts[symptom.painLevel, default: 0] += 1
            urgencyCounts[symptom.urgencyLevel, default: 0] += 1
            switch symptom.stoolType {
            case .type1, .type2: constipationCount += 1
            case .type6, .type7: looseCount += 1
            default: break
            }
        }

        let painDist = painCounts.mapValues { Double($0) / total }
        let urgencyDist = urgencyCounts.mapValues { Double($0) / total }

        let modePain = painCounts.max(by: { $0.value < $1.value })?.key ?? .none
        let modeUrgency = urgencyCounts.max(by: { $0.value < $1.value })?.key ?? .none

        let modeCount = max(painCounts[modePain] ?? 0, urgencyCounts[modeUrgency] ?? 0)
        let confidence = Double(modeCount) / total

        let stoolRisk: StoolRiskLevel = {
            if constipationCount > 0 && looseCount > 0 { return .mixed }
            if constipationCount > looseCount { return .constipation }
            if looseCount > constipationCount { return .loose }
            return .normal
        }()

        return SeverityPrediction(
            mostLikelyPainLevel: modePain,
            mostLikelyUrgencyLevel: modeUrgency,
            painDistribution: painDist,
            urgencyDistribution: urgencyDist,
            stoolRisk: stoolRisk,
            confidence: confidence
        )
    }

    // MARK: - Ingredient Decomposition

    private func decomposeIngredients(
        foodName: String,
        ingredients: [String],
        allMeals: [Meal],
        correlatedSymptoms: [Symptom]
    ) -> [IngredientTriggerBreakdown] {
        let db = FoodCompoundDatabase.shared
        let compounds = db.getCompoundsForFood(name: foodName, ingredients: ingredients)

        guard !compounds.isEmpty else { return [] }

        // For each compound, check how many correlated symptoms match
        return compounds.map { compound in
            IngredientTriggerBreakdown(
                id: UUID(),
                ingredientName: compound.name,
                compoundName: compound.name,
                compoundCategory: compound.category.rawValue,
                correlationScore: min(1.0, Double(correlatedSymptoms.count) / 10.0 + 0.2),
                severity: compound.severity,
                occurrenceCount: correlatedSymptoms.count
            )
        }
        .sorted { $0.correlationScore > $1.correlationScore }
    }

    // MARK: - Timing Profile

    private func computeTimingProfile(onsetDelays: [TimeInterval]) -> TimingProfile {
        guard !onsetDelays.isEmpty else {
            return TimingProfile(averageOnsetHours: 0, medianOnsetHours: 0, minOnsetHours: 0, maxOnsetHours: 0)
        }

        let hoursArray = onsetDelays.map { $0 / 3600.0 }.sorted()
        let avg = hoursArray.reduce(0, +) / Double(hoursArray.count)
        let median: Double = {
            let mid = hoursArray.count / 2
            if hoursArray.count.isMultiple(of: 2) {
                return (hoursArray[mid - 1] + hoursArray[mid]) / 2.0
            } else {
                return hoursArray[mid]
            }
        }()

        return TimingProfile(
            averageOnsetHours: avg,
            medianOnsetHours: median,
            minOnsetHours: hoursArray.first ?? 0,
            maxOnsetHours: hoursArray.last ?? 0
        )
    }

    // MARK: - Summary Insight Generation

    private func generateSummaryInsights(
        foodName: String,
        symptoms: [Symptom],
        timing: TimingProfile,
        score: TriggerScore
    ) -> [TriggerSummaryInsight] {
        var insights: [TriggerSummaryInsight] = []
        let total = symptoms.count

        // Severity pattern
        let severePain = symptoms.filter { $0.painLevel == .severe }.count
        let moderatePain = symptoms.filter { $0.painLevel == .moderate }.count
        let significantPain = severePain + moderatePain

        if significantPain > total / 2 {
            let pct = Int(Double(significantPain) / Double(total) * 100)
            let severityLabel = severePain > moderatePain ? "severe" : "moderate-severe"
            insights.append(TriggerSummaryInsight(
                id: UUID(),
                headline: "\(foodName) frequently leads to \(severityLabel) pain",
                detail: "In \(significantPain) of \(total) instances (\(pct)%), \(foodName) was followed by \(severityLabel) pain within \(String(format: "%.1f", timing.averageOnsetHours)) hours.",
                dataPoints: total,
                confidence: score.correlationComponent
            ))
        }

        // Timing pattern
        if timing.averageOnsetHours > 0 {
            insights.append(TriggerSummaryInsight(
                id: UUID(),
                headline: "Symptoms typically appear \(String(format: "%.1f", timing.averageOnsetHours))h after \(foodName)",
                detail: "Onset ranges from \(String(format: "%.1f", timing.minOnsetHours)) to \(String(format: "%.1f", timing.maxOnsetHours)) hours, with a median of \(String(format: "%.1f", timing.medianOnsetHours)) hours.",
                dataPoints: total,
                confidence: score.correlationComponent
            ))
        }

        // Urgency pattern
        let urgentCount = symptoms.filter { $0.urgencyLevel == .urgent || $0.urgencyLevel == .moderate }.count
        if urgentCount > total / 3 {
            let pct = Int(Double(urgentCount) / Double(total) * 100)
            insights.append(TriggerSummaryInsight(
                id: UUID(),
                headline: "\(foodName) often causes urgent bowel movements",
                detail: "\(pct)% of instances involved moderate or high urgency.",
                dataPoints: total,
                confidence: score.correlationComponent
            ))
        }

        // Stool pattern
        let looseCount = symptoms.filter { $0.stoolType == .type6 || $0.stoolType == .type7 }.count
        if looseCount > total / 3 {
            let pct = Int(Double(looseCount) / Double(total) * 100)
            insights.append(TriggerSummaryInsight(
                id: UUID(),
                headline: "\(foodName) is associated with loose stools",
                detail: "\(pct)% of correlated symptoms involved Bristol type 6-7 stool.",
                dataPoints: total,
                confidence: score.correlationComponent
            ))
        }

        return insights
    }

    // MARK: - Trigger Pattern Helpers

    private func buildSymptomLabels(from symptoms: [Symptom]) -> [String] {
        var labels = Set<String>()
        for symptom in symptoms {
            switch symptom.painLevel {
            case .mild: labels.insert("Mild Pain")
            case .moderate: labels.insert("Moderate Pain")
            case .severe: labels.insert("Severe Pain")
            case .none: break
            }
            switch symptom.urgencyLevel {
            case .mild: labels.insert("Mild Urgency")
            case .moderate: labels.insert("Moderate Urgency")
            case .urgent: labels.insert("High Urgency")
            case .none: break
            }
            switch symptom.stoolType {
            case .type1, .type2: labels.insert("Constipation")
            case .type6, .type7: labels.insert("Loose Stool")
            default: break
            }
        }
        return labels.sorted()
    }

    private func buildTriggerRecommendations(
        foodName: String,
        score: TriggerScore,
        prediction: SeverityPrediction,
        ingredients: [IngredientTriggerBreakdown]
    ) -> [String] {
        var recs: [String] = []

        if score.overall >= 60 {
            recs.append("Consider eliminating \(foodName) for 2-4 weeks")
        } else {
            recs.append("Monitor \(foodName) intake and track symptoms")
        }

        if prediction.mostLikelyPainLevel == .severe || prediction.mostLikelyPainLevel == .moderate {
            recs.append("Consult a healthcare professional about \(foodName) sensitivity")
        }

        let highRiskIngredients = ingredients.filter { $0.severity == .high }
        if !highRiskIngredients.isEmpty {
            let names = highRiskIngredients.prefix(2).map(\.ingredientName).joined(separator: ", ")
            recs.append("High-risk compounds detected: \(names)")
        }

        recs.append("Reintroduce gradually to confirm sensitivity")

        return recs
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
