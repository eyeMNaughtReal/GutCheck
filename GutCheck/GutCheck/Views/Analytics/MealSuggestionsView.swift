//
//  MealSuggestionsView.swift
//  GutCheck
//
//  Detail view for safe meal suggestions based on historical data analysis.
//

import SwiftUI

struct MealSuggestionsView: View {
    let suggestions: [MealSuggestion]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerCard
                suggestionsSection
                tipsCard
            }
            .padding()
        }
        .navigationTitle("Safe Meal Ideas")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.mealSuggestionsView)
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "leaf.circle.fill")
                    .font(.title2)
                    .foregroundStyle(ColorTheme.success)

                Text("Safe Meal Ideas")
                    .font(.title2.bold())
                    .foregroundStyle(ColorTheme.primaryText)

                Spacer()

                Text("\(suggestions.count)")
                    .font(.title2.bold())
                    .foregroundStyle(ColorTheme.success)
            }

            Text("Based on your 30-day meal and symptom history")
                .font(.subheadline)
                .foregroundStyle(ColorTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    // MARK: - Suggestions

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Recommended Meals", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(ColorTheme.primaryText)

            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                suggestionRow(suggestion, index: index)
            }
        }
    }

    private func suggestionRow(_ suggestion: MealSuggestion, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Safety score badge
                ZStack {
                    Circle()
                        .fill(suggestion.safetyColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text("\(suggestion.safetyScore)")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(suggestion.safetyColor)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.mealName)
                        .font(.subheadline.bold())
                        .foregroundStyle(ColorTheme.primaryText)

                    HStack(spacing: 8) {
                        Label(suggestion.mealType.rawValue.capitalized, systemImage: mealTypeIcon(suggestion.mealType))
                            .font(.caption)
                            .foregroundStyle(ColorTheme.secondaryText)

                        Text("\(suggestion.timesEaten)x eaten")
                            .font(.caption)
                            .foregroundStyle(ColorTheme.secondaryText)
                    }
                }

                Spacer()
            }

            // Food items as pills
            if !suggestion.foodItems.isEmpty {
                foodItemPills(suggestion.foodItems)
            }

            // Reasoning
            Label(suggestion.reasoning, systemImage: "info.circle")
                .font(.caption)
                .foregroundStyle(ColorTheme.accent)

            // Last eaten
            Text("Last eaten: \(formattedDate(suggestion.lastEaten))")
                .font(.caption2)
                .foregroundStyle(ColorTheme.secondaryText)
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.mealSuggestionRow(index))
    }

    private func foodItemPills(_ items: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption2)
                        .foregroundStyle(ColorTheme.primaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ColorTheme.accent.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Tips

    private var tipsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("How This Works", systemImage: "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(ColorTheme.primaryText)

            tipRow(
                icon: "shield.checkered",
                text: "Meals with known trigger foods (score 60+) are excluded"
            )
            tipRow(
                icon: "chart.bar.fill",
                text: "Safety scores are based on your personal symptom correlations"
            )
            tipRow(
                icon: "arrow.triangle.2.circlepath",
                text: "Recently eaten meals are scored lower to encourage variety"
            )
            tipRow(
                icon: "clock.fill",
                text: "Meals eaten 3+ times without symptoms get a confidence boost"
            )
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private func tipRow(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.subheadline)
            .foregroundStyle(ColorTheme.secondaryText)
    }

    // MARK: - Helpers

    private func mealTypeIcon(_ type: MealType) -> String {
        switch type {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "carrot.fill"
        case .drink: return "cup.and.saucer.fill"
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        MealSuggestionsView(suggestions: [
            MealSuggestion(
                id: UUID(),
                mealName: "Grilled Chicken Salad",
                mealType: .lunch,
                foodItems: ["Grilled Chicken", "Mixed Greens", "Olive Oil Dressing"],
                safetyScore: 95,
                timesEaten: 5,
                lastEaten: Calendar.current.date(byAdding: .day, value: -4, to: .now)!,
                reasoning: "No symptom correlations detected across 5 meals"
            ),
            MealSuggestion(
                id: UUID(),
                mealName: "Oatmeal with Berries",
                mealType: .breakfast,
                foodItems: ["Oatmeal", "Blueberries", "Honey"],
                safetyScore: 88,
                timesEaten: 8,
                lastEaten: Calendar.current.date(byAdding: .day, value: -1, to: .now)!,
                reasoning: "All items have low trigger scores"
            ),
            MealSuggestion(
                id: UUID(),
                mealName: "Rice and Vegetables",
                mealType: .dinner,
                foodItems: ["White Rice", "Steamed Broccoli", "Carrots"],
                safetyScore: 72,
                timesEaten: 3,
                lastEaten: Calendar.current.date(byAdding: .day, value: -2, to: .now)!,
                reasoning: "Most items are well-tolerated based on your history"
            )
        ])
    }
}
