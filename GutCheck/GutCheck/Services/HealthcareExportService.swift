//
//  HealthcareExportService.swift
//  GutCheck
//
//  Service for exporting health data in formats suitable for healthcare professionals.
//  Generates comprehensive reports that can be shared with doctors, nutritionists,
//  and other healthcare providers to support medical decision-making.
//
//  Created by Mark Conley on 8/11/25.
//

import Foundation
import PDFKit
import UIKit

// MARK: - Export Formats

enum ExportFormat {
    case pdf
    case csv
    case json
    case summary
}

// MARK: - Export Options

struct ExportOptions {
    var dateRange: ClosedRange<Date>
    var includePrivateData: Bool
    var includeNutritionData: Bool
    var includeSymptomData: Bool
    var includeMedicationData: Bool
    var includeMealData: Bool
    var format: ExportFormat
    var anonymizeData: Bool
    
    static let `default` = ExportOptions(
        dateRange: Calendar.current.date(byAdding: .month, value: -3, to: Date())!...Date(),
        includePrivateData: false,
        includeNutritionData: true,
        includeSymptomData: true,
        includeMedicationData: true,
        includeMealData: true,
        format: .pdf,
        anonymizeData: true
    )
}

// MARK: - Healthcare Export Service

class HealthcareExportService: ObservableObject {
    static let shared = HealthcareExportService()
    
    private let mealRepository = MealRepository.shared
    private let symptomRepository = SymptomRepository.shared
    private let localStorageService = LocalStorageService.shared
    
    @Published var isExporting = false
    @Published var exportProgress: Double = 0.0
    
    private init() {}
    
    // MARK: - Main Export Function
    
    func exportHealthData(options: ExportOptions = .default) async throws -> Data {
        await MainActor.run { 
            isExporting = true
            exportProgress = 0.0
        }
        
        defer {
            Task { @MainActor in
                isExporting = false
                exportProgress = 0.0
            }
        }
        
        // Collect data based on options
        let exportData = try await collectExportData(options: options)
        
        // Update progress
        await MainActor.run { exportProgress = 0.5 }
        
        // Generate export based on format
        let exportResult: Data
        switch options.format {
        case .pdf:
            exportResult = try await generatePDFReport(data: exportData, options: options)
        case .csv:
            exportResult = try await generateCSVReport(data: exportData, options: options)
        case .json:
            exportResult = try await generateJSONReport(data: exportData, options: options)
        case .summary:
            exportResult = try await generateSummaryReport(data: exportData, options: options)
        }
        
        await MainActor.run { exportProgress = 1.0 }
        
        return exportResult
    }
    
    // MARK: - Data Collection
    
    private func collectExportData(options: ExportOptions) async throws -> HealthcareExportData {
        guard let userId = AuthenticationManager.shared.currentUserId else {
            throw ExportError.noAuthenticatedUser
        }
        
        var exportData = HealthcareExportData()
        
        // Collect meals
        if options.includeMealData {
            let meals = try await mealRepository.fetchMealsForDateRange(
                startDate: options.dateRange.lowerBound,
                endDate: options.dateRange.upperBound,
                userId: userId
            )
            exportData.meals = meals
        }
        
        // Collect symptoms
        if options.includeSymptomData {
            let symptoms = try await symptomRepository.fetchSymptomsForDateRange(
                startDate: options.dateRange.lowerBound,
                endDate: options.dateRange.upperBound,
                userId: userId
            )
            exportData.symptoms = symptoms
        }
        
        // Collect medication data (from local storage)
        if options.includeMedicationData {
            let medications = try await localStorageService.queryPrivateData(
                type: MedicationRecord.self,
                query: "medication"
            )
            exportData.medications = medications
        }
        
        // Collect nutrition insights
        if options.includeNutritionData {
            exportData.nutritionInsights = try await generateNutritionInsights(meals: exportData.meals)
        }
        
        // Generate health patterns
        exportData.healthPatterns = try await generateHealthPatterns(
            meals: exportData.meals,
            symptoms: exportData.symptoms
        )
        
        return exportData
    }
    
    // MARK: - Report Generation
    
    private func generatePDFReport(data: HealthcareExportData, options: ExportOptions) async throws -> Data {
        // Create PDF data using UIGraphicsPDFRenderer instead of PDFDocument
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter size
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let pdfData = renderer.pdfData { context in
            // Create title page
            createTitlePageContent(context: context, data: data, options: options)
            
            // Create summary page
            context.beginPage()
            createSummaryPageContent(context: context, data: data, options: options)
            
            // Create detailed data pages
            if options.includeMealData {
                context.beginPage()
                createMealDataPageContent(context: context, data: data, options: options)
            }
            
            if options.includeSymptomData {
                context.beginPage()
                createSymptomDataPageContent(context: context, data: data, options: options)
            }
            
            if options.includeMedicationData {
                context.beginPage()
                createMedicationDataPageContent(context: context, data: data, options: options)
            }
            
            // Create insights page
            context.beginPage()
            createInsightsPageContent(context: context, data: data, options: options)
        }
        
        return pdfData
    }
    
    private func generateCSVReport(data: HealthcareExportData, options: ExportOptions) async throws -> Data {
        var csvContent = "Date,Type,Details,Notes\n"
        
        // Add meals
        if options.includeMealData {
            for meal in data.meals {
                let date = DateFormatter.exportDateFormatter.string(from: meal.date)
                let details = meal.foodItems.map { $0.name }.joined(separator: "; ")
                let notes = meal.notes ?? ""
                csvContent += "\(date),Meal,\(details),\(notes)\n"
            }
        }
        
        // Add symptoms
        if options.includeSymptomData {
            for symptom in data.symptoms {
                let date = DateFormatter.exportDateFormatter.string(from: symptom.date)
                let details = "\(symptom.stoolType.rawValue) - Pain: \(symptom.painLevel.rawValue)"
                let notes = symptom.notes ?? ""
                csvContent += "\(date),Symptom,\(details),\(notes)\n"
            }
        }
        
        // Add medications
        if options.includeMedicationData {
            for medication in data.medications {
                let date = DateFormatter.exportDateFormatter.string(from: medication.startDate)
                let details = "\(medication.name) - \(medication.dosage)"
                let notes = medication.notes ?? ""
                csvContent += "\(date),Medication,\(details),\(notes)\n"
            }
        }
        
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func generateJSONReport(data: HealthcareExportData, options: ExportOptions) async throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        let exportData = HealthcareExportData(
            meals: options.includeMealData ? data.meals : [],
            symptoms: options.includeSymptomData ? data.symptoms : [],
            medications: options.includeMedicationData ? data.medications : [],
            nutritionInsights: options.includeNutritionData ? data.nutritionInsights : [],
            healthPatterns: data.healthPatterns
        )
        
        return try encoder.encode(exportData)
    }
    
    private func generateSummaryReport(data: HealthcareExportData, options: ExportOptions) async throws -> Data {
        let summary = HealthcareSummary(
            totalMeals: data.meals.count,
            totalSymptoms: data.symptoms.count,
            totalMedications: data.medications.count,
            dateRange: options.dateRange,
            keyInsights: data.healthPatterns.map { $0.description },
            recommendations: generateRecommendations(from: data)
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try encoder.encode(summary)
    }
    
    // MARK: - Helper Methods
    
    private func generateNutritionInsights(meals: [Meal]) async throws -> [NutritionInsight] {
        var insights: [NutritionInsight] = []
        
        // Calculate average daily calories
        let dailyCalories = Dictionary(grouping: meals) { meal in
            Calendar.current.startOfDay(for: meal.date)
        }
        
        var dailyCaloriesMap: [Date: Int] = [:]
        for (date, mealsForDate) in dailyCalories {
            var totalCalories = 0
            for meal in mealsForDate {
                for foodItem in meal.foodItems {
                    totalCalories += foodItem.nutrition.calories ?? 0
                }
            }
            dailyCaloriesMap[date] = totalCalories
        }
        
        let totalCalories = dailyCaloriesMap.values.reduce(0, +)
        let avgCalories = totalCalories / max(dailyCaloriesMap.count, 1)
        insights.append(NutritionInsight(
            type: .dailyCalories,
            value: Double(avgCalories),
            description: "Average daily calorie intake: \(Int(avgCalories)) calories"
        ))
        
        // Identify common food triggers
        let foodSymptomCorrelations = try await analyzeFoodSymptomCorrelations(meals: meals)
        insights.append(contentsOf: foodSymptomCorrelations)
        
        return insights
    }
    
    private func generateHealthPatterns(meals: [Meal], symptoms: [Symptom]) async throws -> [HealthcarePattern] {
        var patterns: [HealthcarePattern] = []
        
        // Time-based patterns
        let mealTimes = meals.map { Calendar.current.component(.hour, from: $0.date) }
        let commonMealHours = Dictionary(grouping: mealTimes, by: { $0 })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
            .prefix(3)
        
        if let mostCommonHour = commonMealHours.first {
            patterns.append(HealthcarePattern(
                type: .mealTiming,
                description: "Most common meal time: \(mostCommonHour.key):00",
                frequency: mostCommonHour.value,
                severity: .moderate
            ))
        }
        
        // Symptom patterns
        let symptomTypes = symptoms.map { $0.stoolType }
        let mostCommonSymptom = Dictionary(grouping: symptomTypes, by: { $0 })
            .mapValues { $0.count }
            .max { $0.value < $1.value }
        
        if let commonSymptom = mostCommonSymptom {
            patterns.append(HealthcarePattern(
                type: .symptomFrequency,
                description: "Most common symptom: \(commonSymptom.key.rawValue)",
                frequency: commonSymptom.value,
                severity: .moderate
            ))
        }
        
        return patterns
    }
    
    private func analyzeFoodSymptomCorrelations(meals: [Meal]) async throws -> [NutritionInsight] {
        // This would implement correlation analysis between food intake and symptoms
        // For now, return basic insights
        return [
            NutritionInsight(
                type: .foodTrigger,
                value: 0,
                description: "Food-symptom correlation analysis available in detailed report"
            )
        ]
    }
    
    private func generateRecommendations(from data: HealthcareExportData) -> [String] {
        var recommendations: [String] = []
        
        // Meal timing recommendations
        if data.meals.count > 0 {
            let mealTimes = data.meals.map { $0.date }
            let intervals = zip(mealTimes, mealTimes.dropFirst()).map { 
                $0.1.timeIntervalSince($0.0) / 3600 
            }
            
            if let avgInterval = intervals.isEmpty ? nil : intervals.reduce(0, +) / Double(intervals.count) {
                if avgInterval < 2 {
                    recommendations.append("Consider spacing meals further apart (current average: \(String(format: "%.1f", avgInterval)) hours)")
                }
            }
        }
        
        // Symptom-based recommendations
        let severeSymptoms = data.symptoms.filter { $0.painLevel == .severe || $0.urgencyLevel == .urgent }
        if severeSymptoms.count > 0 {
            recommendations.append("Monitor severe symptoms closely - consider consulting healthcare provider")
        }
        
        // Medication recommendations
        if data.medications.count > 0 {
            recommendations.append("Review medication timing and potential food interactions")
        }
        
        return recommendations
    }
    
    // MARK: - PDF Page Creation
    
    private func createTitlePageContent(context: UIGraphicsPDFRendererContext, data: HealthcareExportData, options: ExportOptions) {
        let pageRect = context.pdfContextBounds
        
        // Draw background gradient effect
        let gradientRect = CGRect(x: 0, y: 0, width: pageRect.width, height: pageRect.height)
        let context = context.cgContext
        
        // Create subtle background pattern
        context.setFillColor(UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0).cgColor)
        context.fill(gradientRect)
        
        // Draw decorative header bar
        let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 80)
        context.setFillColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor)
        context.fill(headerRect)
        
        // App logo/icon placeholder (you can replace this with actual logo)
        let logoRect = CGRect(x: 50, y: 20, width: 40, height: 40)
        context.setFillColor(UIColor.white.cgColor)
        context.fillEllipse(in: logoRect)
        
        // Main title with better typography
        let titleFont = UIFont.boldSystemFont(ofSize: 32)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.white
        ]
        let titleString = "GutCheck"
        titleString.draw(at: CGPoint(x: 110, y: 25), withAttributes: titleAttributes)
        
        // Subtitle in header
        let subtitleFont = UIFont.systemFont(ofSize: 18)
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: subtitleFont,
            .foregroundColor: UIColor.white.withAlphaComponent(0.9)
        ]
        let subtitleString = "Health Report"
        subtitleString.draw(at: CGPoint(x: 110, y: 50), withAttributes: subtitleAttributes)
        
        // Main content area
        let contentY: CGFloat = 120
        
        // Report title
        let reportTitleFont = UIFont.boldSystemFont(ofSize: 28)
        let reportTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: reportTitleFont,
            .foregroundColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        ]
        let reportTitleString = "Comprehensive Health Data Export"
        let reportTitleSize = reportTitleString.size(withAttributes: reportTitleAttributes)
        let reportTitleRect = CGRect(x: (pageRect.width - reportTitleSize.width) / 2, y: contentY, width: reportTitleSize.width, height: reportTitleSize.height)
        reportTitleString.draw(in: reportTitleRect, withAttributes: reportTitleAttributes)
        
        // Decorative line under title
        let lineY = contentY + reportTitleSize.height + 20
        context.setStrokeColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor)
        context.setLineWidth(3.0)
        context.move(to: CGPoint(x: 100, y: lineY))
        context.addLine(to: CGPoint(x: pageRect.width - 100, y: lineY))
        context.strokePath()
        
        // Date range in a styled box
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let startDate = dateFormatter.string(from: options.dateRange.lowerBound)
        let endDate = dateFormatter.string(from: options.dateRange.upperBound)
        
        let dateBoxY = lineY + 40
        let dateBoxRect = CGRect(x: 100, y: dateBoxY, width: pageRect.width - 200, height: 60)
        
        // Draw date box background
        context.setFillColor(UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0).cgColor)
        context.fill(dateBoxRect)
        
        // Draw date box border
        context.setStrokeColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor)
        context.setLineWidth(1.0)
        context.stroke(dateBoxRect)
        
        // Date text
        let dateFont = UIFont.systemFont(ofSize: 16)
        let dateAttributes: [NSAttributedString.Key: Any] = [
            .font: dateFont,
            .foregroundColor: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        ]
        
        let dateLabelString = "Report Period"
        dateLabelString.draw(at: CGPoint(x: 120, y: dateBoxY + 10), withAttributes: dateAttributes)
        
        let dateString = "\(startDate) - \(endDate)"
        dateString.draw(at: CGPoint(x: 120, y: dateBoxY + 30), withAttributes: dateAttributes)
        
        // Generated timestamp
        let generatedY = dateBoxY + 80
        let generatedString = "Generated: \(DateFormatter().string(from: Date()))"
        let generatedSize = generatedString.size(withAttributes: dateAttributes)
        generatedString.draw(at: CGPoint(x: (pageRect.width - generatedSize.width) / 2, y: generatedY), withAttributes: dateAttributes)
        
        // Footer with additional info
        let footerY = pageRect.height - 100
        let footerFont = UIFont.systemFont(ofSize: 12)
        let footerAttributes: [NSAttributedString.Key: Any] = [
            .font: footerFont,
            .foregroundColor: UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        ]
        
        let footerString = "This report contains sensitive health information. Please handle with care."
        let footerSize = footerString.size(withAttributes: footerAttributes)
        footerString.draw(at: CGPoint(x: (pageRect.width - footerSize.width) / 2, y: footerY), withAttributes: footerAttributes)
    }
    
    private func createSummaryPageContent(context: UIGraphicsPDFRendererContext, data: HealthcareExportData, options: ExportOptions) {
        let pageRect = context.pdfContextBounds
        let context = context.cgContext
        
        // Page header with accent color
        let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 60)
        context.setFillColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor)
        context.fill(headerRect)
        
        // Page title
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.white
        ]
        let titleString = "Executive Summary"
        titleString.draw(at: CGPoint(x: 50, y: 20), withAttributes: titleAttributes)
        
        // Content area
        var yPosition: CGFloat = 80
        
        // Summary statistics in styled boxes
        let stats = [
            ("Total Meals", "\(data.meals.count)", "🍽️"),
            ("Total Symptoms", "\(data.symptoms.count)", "🏥"),
            ("Total Medications", "\(data.medications.count)", "💊"),
            ("Report Period", "\(DateFormatter.exportDateFormatter.string(from: options.dateRange.lowerBound)) - \(DateFormatter.exportDateFormatter.string(from: options.dateRange.upperBound))", "📅")
        ]
        
        let boxWidth: CGFloat = (pageRect.width - 120) / 2
        let boxHeight: CGFloat = 80
        
        for (index, stat) in stats.enumerated() {
            let row = index / 2
            let col = index % 2
            let x = 50 + CGFloat(col) * (boxWidth + 20)
            let y = yPosition + CGFloat(row) * (boxHeight + 20)
            
            let boxRect = CGRect(x: x, y: y, width: boxWidth, height: boxHeight)
            
            // Box background with subtle shadow effect
            context.setFillColor(UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0).cgColor)
            context.fill(boxRect)
            
            // Box border
            context.setStrokeColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 0.3).cgColor)
            context.setLineWidth(1.0)
            context.stroke(boxRect)
            
            // Icon
            let iconFont = UIFont.systemFont(ofSize: 24)
            let iconAttributes: [NSAttributedString.Key: Any] = [
                .font: iconFont,
                .foregroundColor: UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
            ]
            stat.2.draw(at: CGPoint(x: x + 10, y: y + 10), withAttributes: iconAttributes)
            
            // Label
            let labelFont = UIFont.systemFont(ofSize: 12)
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: labelFont,
                .foregroundColor: UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
            ]
            stat.0.draw(at: CGPoint(x: x + 40, y: y + 15), withAttributes: labelAttributes)
            
            // Value
            let valueFont = UIFont.boldSystemFont(ofSize: 18)
            let valueAttributes: [NSAttributedString.Key: Any] = [
                .font: valueFont,
                .foregroundColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
            ]
            stat.1.draw(at: CGPoint(x: x + 40, y: y + 35), withAttributes: valueAttributes)
        }
        
        yPosition += CGFloat((stats.count + 1) / 2) * (boxHeight + 20) + 40
        
        // Key insights section
        let insightsTitleFont = UIFont.boldSystemFont(ofSize: 20)
        let insightsTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: insightsTitleFont,
            .foregroundColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        ]
        "Key Insights".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: insightsTitleAttributes)
        
        // Decorative line
        yPosition += 30
        context.setStrokeColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor)
        context.setLineWidth(2.0)
        context.move(to: CGPoint(x: 50, y: yPosition))
        context.addLine(to: CGPoint(x: 200, y: yPosition))
        context.strokePath()
        
        yPosition += 20
        
        // Insights content
        let insightsFont = UIFont.systemFont(ofSize: 14)
        let insightsAttributes: [NSAttributedString.Key: Any] = [
            .font: insightsFont,
            .foregroundColor: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        ]
        
        if data.nutritionInsights.isEmpty {
            "No nutrition insights available for this period.".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: insightsAttributes)
            yPosition += 25
        } else {
            for insight in data.nutritionInsights.prefix(5) {
                let insightText = "• \(insight.description)"
                insightText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: insightsAttributes)
                yPosition += 20
            }
        }
        
        // Health patterns section
        yPosition += 20
        "Health Patterns".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: insightsTitleAttributes)
        
        // Decorative line
        yPosition += 30
        context.setStrokeColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor)
        context.setLineWidth(2.0)
        context.move(to: CGPoint(x: 50, y: yPosition))
        context.addLine(to: CGPoint(x: 200, y: yPosition))
        context.strokePath()
        
        yPosition += 20
        
        if data.healthPatterns.isEmpty {
            "No health patterns identified for this period.".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: insightsAttributes)
        } else {
            for pattern in data.healthPatterns.prefix(5) {
                let patternText = "• \(pattern.type.rawValue): \(pattern.description)"
                patternText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: insightsAttributes)
                yPosition += 20
            }
        }
    }
    
    private func createMealDataPageContent(context: UIGraphicsPDFRendererContext, data: HealthcareExportData, options: ExportOptions) {
        let pageRect = context.pdfContextBounds
        let context = context.cgContext
        
        // Page header with accent color
        let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 60)
        context.setFillColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor)
        context.fill(headerRect)
        
        // Page title with icon
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.white
        ]
        let titleString = "🍽️ Meal Data"
        titleString.draw(at: CGPoint(x: 50, y: 20), withAttributes: titleAttributes)
        
        // Content area
        var yPosition: CGFloat = 80
        
        // Summary box at top
        let summaryBoxRect = CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: 60)
        context.setFillColor(UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0).cgColor)
        context.fill(summaryBoxRect)
        context.setStrokeColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 0.3).cgColor)
        context.setLineWidth(1.0)
        context.stroke(summaryBoxRect)
        
        let summaryFont = UIFont.systemFont(ofSize: 14)
        let summaryAttributes: [NSAttributedString.Key: Any] = [
            .font: summaryFont,
            .foregroundColor: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        ]
        
        let summaryText = "Total Meals: \(data.meals.count) • Showing first 20 meals with detailed nutrition information"
        summaryText.draw(at: CGPoint(x: 70, y: yPosition + 20), withAttributes: summaryAttributes)
        
        yPosition += 80
        
        // Meal data in styled cards
        let dataFont = UIFont.systemFont(ofSize: 12)
        let dataAttributes: [NSAttributedString.Key: Any] = [
            .font: dataFont,
            .foregroundColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        ]
        
        let mealTitleFont = UIFont.boldSystemFont(ofSize: 14)
        let mealTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: mealTitleFont,
            .foregroundColor: UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
        ]
        
        let nutritionFont = UIFont.systemFont(ofSize: 11)
        let nutritionAttributes: [NSAttributedString.Key: Any] = [
            .font: nutritionFont,
            .foregroundColor: UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        ]
        
        for meal in data.meals.prefix(20) { // Limit to first 20 meals to fit on page
            let dateString = DateFormatter.exportDateFormatter.string(from: meal.date)
            
            // Meal card background
            let cardHeight: CGFloat = 40 + CGFloat(min(meal.foodItems.count, 3)) * 30
            let cardRect = CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: cardHeight)
            
            // Card background with subtle border
            context.setFillColor(UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1.0).cgColor)
            context.fill(cardRect)
            context.setStrokeColor(UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor)
            context.setLineWidth(0.5)
            context.stroke(cardRect)
            
            // Meal header
            let mealInfo = "\(dateString) - \(meal.type.rawValue.capitalized)"
            mealInfo.draw(at: CGPoint(x: 70, y: yPosition + 15), withAttributes: mealTitleAttributes)
            
            yPosition += 40
            
            // Food items
            for foodItem in meal.foodItems.prefix(3) { // Limit food items per meal
                let foodText = "• \(foodItem.name) (\(foodItem.quantity))"
                foodText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: dataAttributes)
                yPosition += 20
                
                if let calories = foodItem.nutrition.calories {
                    let nutritionText = "  Calories: \(calories) | Protein: \(foodItem.nutrition.protein ?? 0)g | Carbs: \(foodItem.nutrition.carbs ?? 0)g | Fat: \(foodItem.nutrition.fat ?? 0)g"
                    nutritionText.draw(at: CGPoint(x: 90, y: yPosition), withAttributes: nutritionAttributes)
                    yPosition += 15
                }
            }
            yPosition += 15 // Spacing between meals
        }
        
        if data.meals.count > 20 {
            let moreText = "... and \(data.meals.count - 20) more meals"
            let moreAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 12),
                .foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
            ]
            moreText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: moreAttributes)
        }
    }
    
    private func createSymptomDataPageContent(context: UIGraphicsPDFRendererContext, data: HealthcareExportData, options: ExportOptions) {
        let pageRect = context.pdfContextBounds
        let context = context.cgContext
        
        // Page header with accent color
        let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 60)
        context.setFillColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor)
        context.fill(headerRect)
        
        // Page title with icon
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.white
        ]
        let titleString = "🏥 Symptom Data"
        titleString.draw(at: CGPoint(x: 50, y: 20), withAttributes: titleAttributes)
        
        // Content area
        var yPosition: CGFloat = 80
        
        // Summary box at top
        let summaryBoxRect = CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: 60)
        context.setFillColor(UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0).cgColor)
        context.fill(summaryBoxRect)
        context.setStrokeColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 0.3).cgColor)
        context.setLineWidth(1.0)
        context.stroke(summaryBoxRect)
        
        let summaryFont = UIFont.systemFont(ofSize: 14)
        let summaryAttributes: [NSAttributedString.Key: Any] = [
            .font: summaryFont,
            .foregroundColor: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        ]
        
        let summaryText = "Total Symptoms: \(data.symptoms.count) • Showing first 25 symptoms with severity and notes"
        summaryText.draw(at: CGPoint(x: 70, y: yPosition + 20), withAttributes: summaryAttributes)
        
        yPosition += 80
        
        // Symptom data in styled cards
        
        let symptomTitleFont = UIFont.boldSystemFont(ofSize: 14)
        let symptomTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: symptomTitleFont,
            .foregroundColor: UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
        ]
        
        let detailFont = UIFont.systemFont(ofSize: 11)
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: detailFont,
            .foregroundColor: UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        ]
        
        for symptom in data.symptoms.prefix(25) { // Limit to first 25 symptoms
            let dateString = DateFormatter.exportDateFormatter.string(from: symptom.date)
            
            // Calculate card height based on content
            var cardHeight: CGFloat = 40 // Base height for symptom header
            cardHeight += 20 // Pain level
            if let notes = symptom.notes, !notes.isEmpty { cardHeight += 20 }
            
            let cardRect = CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: cardHeight)
            
            // Card background with subtle border
            context.setFillColor(UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1.0).cgColor)
            context.fill(cardRect)
            context.setStrokeColor(UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor)
            context.setLineWidth(0.5)
            context.stroke(cardRect)
            
            // Symptom header
            let symptomInfo = "\(dateString) - \(symptom.stoolType.rawValue)"
            symptomInfo.draw(at: CGPoint(x: 70, y: yPosition + 15), withAttributes: symptomTitleAttributes)
            
            yPosition += 40
            
            // Pain level
            let severityText = "Pain Level: \(symptom.painLevel.rawValue)"
            severityText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: detailAttributes)
            yPosition += 20
            
            // Notes
            if let notes = symptom.notes, !notes.isEmpty {
                let notesText = "Notes: \(notes)"
                notesText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: detailAttributes)
                yPosition += 20
            }
            
            yPosition += 15 // Spacing between symptoms
        }
        
        if data.symptoms.count > 25 {
            let moreText = "... and \(data.symptoms.count - 25) more symptoms"
            let moreAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 12),
                .foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
            ]
            moreText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: moreAttributes)
        }
    }
    
    private func createMedicationDataPageContent(context: UIGraphicsPDFRendererContext, data: HealthcareExportData, options: ExportOptions) {
        let pageRect = context.pdfContextBounds
        let context = context.cgContext
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        // Page header with accent color
        let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 60)
        context.setFillColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor)
        context.fill(headerRect)
        
        // Page title with icon
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.white
        ]
        let titleString = "💊 Medication Data"
        titleString.draw(at: CGPoint(x: 50, y: 20), withAttributes: titleAttributes)
        
        // Content area
        var yPosition: CGFloat = 80
        
        // Summary box at top
        let summaryBoxRect = CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: 60)
        context.setFillColor(UIColor(red: 0.98, green: 0.98, blue: 1.0, alpha: 1.0).cgColor)
        context.fill(summaryBoxRect)
        context.setStrokeColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 0.3).cgColor)
        context.setLineWidth(1.0)
        context.stroke(summaryBoxRect)
        
        let summaryFont = UIFont.systemFont(ofSize: 14)
        let summaryAttributes: [NSAttributedString.Key: Any] = [
            .font: summaryFont,
            .foregroundColor: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        ]
        
        let summaryText = "Total Medications: \(data.medications.count) • Showing first 30 medications with dosage and notes"
        summaryText.draw(at: CGPoint(x: 70, y: yPosition + 20), withAttributes: summaryAttributes)
        
        yPosition += 80
        
        // Medication data in styled cards
        
        let medicationTitleFont = UIFont.boldSystemFont(ofSize: 14)
        let medicationTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: medicationTitleFont,
            .foregroundColor: UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0)
        ]
        
        let detailFont = UIFont.systemFont(ofSize: 11)
        let detailAttributes: [NSAttributedString.Key: Any] = [
            .font: detailFont,
            .foregroundColor: UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        ]
        
        for medication in data.medications.prefix(30) { // Limit to first 30 medications
            let startDateString = dateFormatter.string(from: medication.startDate)
            
            // Calculate card height based on content
            var cardHeight: CGFloat = 40 // Base height for medication header
            cardHeight += 20 // Start date
            if let notes = medication.notes, !notes.isEmpty { cardHeight += 20 }
            
            let cardRect = CGRect(x: 50, y: yPosition, width: pageRect.width - 100, height: cardHeight)
            
            // Card background with subtle border
            context.setFillColor(UIColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1.0).cgColor)
            context.fill(cardRect)
            context.setStrokeColor(UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0).cgColor)
            context.setLineWidth(0.5)
            context.stroke(cardRect)
            
            // Medication header
            let medInfo = "\(medication.name) - \(medication.dosage)"
            medInfo.draw(at: CGPoint(x: 70, y: yPosition + 15), withAttributes: medicationTitleAttributes)
            
            yPosition += 40
            
            // Start date
            let dateText = "Started: \(startDateString)"
            dateText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: detailAttributes)
            yPosition += 20
            
            // Notes
            if let notes = medication.notes, !notes.isEmpty {
                let notesText = "Notes: \(notes)"
                notesText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: detailAttributes)
                yPosition += 20
            }
            
            yPosition += 15 // Spacing between medications
        }
        
        if data.medications.count > 30 {
            let moreText = "... and \(data.medications.count - 30) more medications"
            let moreAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.italicSystemFont(ofSize: 12),
                .foregroundColor: UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
            ]
            moreText.draw(at: CGPoint(x: 50, y: yPosition), withAttributes: moreAttributes)
        }
    }
    
    private func createInsightsPageContent(context: UIGraphicsPDFRendererContext, data: HealthcareExportData, options: ExportOptions) {
        let pageRect = context.pdfContextBounds
        let context = context.cgContext
        
        // Page header with accent color
        let headerRect = CGRect(x: 0, y: 0, width: pageRect.width, height: 60)
        context.setFillColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor)
        context.fill(headerRect)
        
        // Page title with icon
        let titleFont = UIFont.boldSystemFont(ofSize: 24)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: UIColor.white
        ]
        let titleString = "🔍 Health Insights & Patterns"
        titleString.draw(at: CGPoint(x: 50, y: 20), withAttributes: titleAttributes)
        
        // Content area
        var yPosition: CGFloat = 80
        
        // Nutrition insights section
        let sectionTitleFont = UIFont.boldSystemFont(ofSize: 20)
        let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: sectionTitleFont,
            .foregroundColor: UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        ]
        
        "Nutrition Insights".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionTitleAttributes)
        
        // Decorative line
        yPosition += 30
        context.setStrokeColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor)
        context.setLineWidth(2.0)
        context.move(to: CGPoint(x: 50, y: yPosition))
        context.addLine(to: CGPoint(x: 250, y: yPosition))
        context.strokePath()
        
        yPosition += 20
        
        // Insights content
        let dataFont = UIFont.systemFont(ofSize: 12)
        let dataAttributes: [NSAttributedString.Key: Any] = [
            .font: dataFont,
            .foregroundColor: UIColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0)
        ]
        
        if data.nutritionInsights.isEmpty {
            "No nutrition insights available for this period.".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: dataAttributes)
            yPosition += 25
        } else {
            for insight in data.nutritionInsights.prefix(10) {
                let insightText = "• \(insight.description)"
                insightText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: dataAttributes)
                yPosition += 20
            }
        }
        
        yPosition += 30
        
        // Health patterns section
        "Health Patterns".draw(at: CGPoint(x: 50, y: yPosition), withAttributes: sectionTitleAttributes)
        
        // Decorative line
        yPosition += 30
        context.setStrokeColor(UIColor(red: 0.2, green: 0.6, blue: 0.9, alpha: 1.0).cgColor)
        context.setLineWidth(2.0)
        context.move(to: CGPoint(x: 50, y: yPosition))
        context.addLine(to: CGPoint(x: 250, y: yPosition))
        context.strokePath()
        
        yPosition += 20
        
        if data.healthPatterns.isEmpty {
            "No health patterns identified for this period.".draw(at: CGPoint(x: 70, y: yPosition), withAttributes: dataAttributes)
        } else {
            for pattern in data.healthPatterns.prefix(10) {
                let patternText = "• \(pattern.type.rawValue): \(pattern.description)"
                patternText.draw(at: CGPoint(x: 70, y: yPosition), withAttributes: dataAttributes)
                yPosition += 20
            }
        }
    }
}

// MARK: - Data Models

struct HealthcareExportData: Encodable {
    var meals: [Meal] = []
    var symptoms: [Symptom] = []
    var medications: [MedicationRecord] = []
    var nutritionInsights: [NutritionInsight] = []
    var healthPatterns: [HealthcarePattern] = []
}

struct HealthcareSummary: Encodable {
    let totalMeals: Int
    let totalSymptoms: Int
    let totalMedications: Int
    let dateRange: ClosedRange<Date>
    let keyInsights: [String]
    let recommendations: [String]
}

struct NutritionInsight: Encodable {
    enum InsightType: String, Encodable {
        case dailyCalories
        case foodTrigger
        case nutrientDeficiency
        case foodIntolerance
    }
    
    let type: InsightType
    let value: Double
    let description: String
}

struct HealthcarePattern: Encodable {
    enum PatternType: String, Encodable {
        case mealTiming
        case symptomFrequency
        case foodTrigger
        case medicationInteraction
    }
    
    let type: PatternType
    let description: String
    let frequency: Int
    let severity: PainLevel
}

// MARK: - Errors

enum ExportError: LocalizedError {
    case noAuthenticatedUser
    case pdfGenerationFailed
    case dataCollectionFailed
    
    var errorDescription: String? {
        switch self {
        case .noAuthenticatedUser:
            return "No authenticated user found"
        case .pdfGenerationFailed:
            return "Failed to generate PDF report"
        case .dataCollectionFailed:
            return "Failed to collect export data"
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let exportDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Repository Extensions

extension MealRepository {
    func fetchMealsForDateRange(startDate: Date, endDate: Date, userId: String) async throws -> [Meal] {
        var allMeals: [Meal] = []
        
        // Fetch from local encrypted storage (private meals)
        do {
            let localMeals = try await UnifiedDataService.shared.query(Meal.self) { _ in
                return firestore.collection(collectionName)
            }
            
            // Filter local meals by date range
            let filteredLocalMeals = localMeals.filter { meal in
                meal.date >= startDate && meal.date <= endDate
            }
            allMeals.append(contentsOf: filteredLocalMeals)
        } catch {
            print("⚠️ Local meal query failed: \(error)")
        }
        
        // Fetch from Firestore (public meals)
        let firestoreMeals = try await query { query in
            query
                .whereField("createdBy", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: startDate)
                .whereField("date", isLessThanOrEqualTo: endDate)
                .order(by: "date", descending: false)
        }
        allMeals.append(contentsOf: firestoreMeals)
        
        // Sort all meals by date
        return allMeals.sorted { $0.date < $1.date }
    }
}

extension SymptomRepository {
    func fetchSymptomsForDateRange(startDate: Date, endDate: Date, userId: String) async throws -> [Symptom] {
        var allSymptoms: [Symptom] = []
        
        // Fetch from local encrypted storage (private symptoms)
        do {
            let localSymptoms = try await UnifiedDataService.shared.query(Symptom.self) { _ in
                return firestore.collection(collectionName)
            }
            
            // Filter local symptoms by date range
            let filteredLocalSymptoms = localSymptoms.filter { symptom in
                symptom.date >= startDate && symptom.date <= endDate
            }
            allSymptoms.append(contentsOf: filteredLocalSymptoms)
        } catch {
            print("⚠️ Local symptom query failed: \(error)")
        }
        
        // Fetch from Firestore (public symptoms)
        let firestoreSymptoms = try await query { query in
            query
                .whereField("createdBy", isEqualTo: userId)
                .whereField("date", isGreaterThanOrEqualTo: startDate)
                .whereField("date", isLessThanOrEqualTo: endDate)
                .order(by: "date", descending: false)
        }
        allSymptoms.append(contentsOf: firestoreSymptoms)
        
        // Sort all symptoms by date
        return allSymptoms.sorted { $0.date < $1.date }
    }
}

extension LocalStorageService {
    func queryPrivateData<T: Codable>(type: T.Type, query: String) async throws -> [T] {
        // Implementation would query local encrypted storage
        // For now, return empty array
        return []
    }
}
