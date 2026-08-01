import SwiftUI

struct SymptomExplorerView: View {
    @State private var viewModel = SymptomExplorerViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    ProgressView("Loading symptoms…")
                        .padding(.top, 40)
                } else if viewModel.recentSymptoms.isEmpty {
                    noSymptomsState
                } else {
                    symptomPickerSection

                    if let symptom = viewModel.selectedSymptom {
                        selectedSymptomCard(symptom)
                    }

                    if viewModel.isLoadingMeals {
                        ProgressView()
                    } else if viewModel.suspectedMeals.isEmpty && viewModel.selectedSymptom != nil {
                        emptyMealsState
                    } else {
                        suspectedMealsSection
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Symptom Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.symptomExplorerView)
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Symptom Picker

    private var symptomPickerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Select Symptom", systemImage: "heart.text.clipboard")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            Picker("Symptom", selection: Binding(
                get: { viewModel.selectedSymptom },
                set: { newValue in
                    if let symptom = newValue {
                        viewModel.selectSymptom(symptom)
                    }
                }
            )) {
                ForEach(viewModel.recentSymptoms) { symptom in
                    Text(viewModel.symptomLabel(for: symptom))
                        .tag(Optional(symptom))
                }
            }
            .pickerStyle(.menu)
            .padding(12)
            .background(ColorTheme.surface)
            .clipShape(.rect(cornerRadius: 12))
            .accessibilityIdentifier(AccessibilityIdentifiers.Insights.symptomExplorerPicker)
        }
    }

    // MARK: - Selected Symptom Card

    private func selectedSymptomCard(_ symptom: Symptom) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Symptom Details", systemImage: "info.circle.fill")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            HStack(spacing: 16) {
                symptomDetailItem(
                    icon: "calendar",
                    label: "Date",
                    value: formattedDate(symptom.date)
                )

                symptomDetailItem(
                    icon: "clock",
                    label: "Time",
                    value: formattedTime(symptom.date)
                )
            }

            HStack(spacing: 16) {
                symptomDetailItem(
                    icon: "bolt.fill",
                    label: "Pain",
                    value: painLabel(symptom.painLevel),
                    color: painColor(symptom.painLevel)
                )

                symptomDetailItem(
                    icon: "exclamationmark.triangle.fill",
                    label: "Urgency",
                    value: urgencyLabel(symptom.urgencyLevel),
                    color: urgencyColor(symptom.urgencyLevel)
                )

                symptomDetailItem(
                    icon: "chart.bar.fill",
                    label: "Bristol",
                    value: "Type \(symptom.stoolType.rawValue)"
                )
            }

            if let notes = symptom.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                    Text(notes)
                        .typography(Typography.subheadline)
                        .foregroundStyle(ColorTheme.primaryText)
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    private func symptomDetailItem(
        icon: String,
        label: String,
        value: String,
        color: Color = ColorTheme.primaryText
    ) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.accent)
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            Text(label)
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Suspected Meals

    private var suspectedMealsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Suspected Meals", systemImage: "fork.knife.circle.fill")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            Text("Meals eaten 6-24 hours before this symptom, ranked by trigger likelihood")
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)

            ForEach(Array(viewModel.suspectedMeals.enumerated()), id: \.element.id) { index, suspected in
                suspectedMealCard(suspected, index: index)
            }
        }
    }

    private func suspectedMealCard(_ suspected: SuspectedMeal, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: score badge, meal name, type, time gap
            HStack(spacing: 12) {
                // Trigger likelihood score badge
                ZStack {
                    Circle()
                        .fill(scoreColor(suspected.triggerLikelihood).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Text("\(suspected.triggerLikelihood)")
                        .font(.subheadline.bold().monospacedDigit())
                        .foregroundStyle(scoreColor(suspected.triggerLikelihood))
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(suspected.meal.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(ColorTheme.primaryText)
                            .lineLimit(1)

                        mealTypeBadge(suspected.meal.type)
                    }

                    Text(suspected.timeBeforeFormatted)
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }

                Spacer()
            }

            // Suspected food items
            if !suspected.suspectedFoods.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(suspected.suspectedFoods) { food in
                        suspectedFoodRow(food)
                    }
                }
            } else {
                Text("No specific trigger compounds identified")
                    .typography(Typography.caption)
                    .foregroundStyle(ColorTheme.tertiaryText)
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.suspectedMealCard(index))
    }

    private func suspectedFoodRow(_ food: SuspectedFood) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(food.foodItem.name)
                    .typography(Typography.subheadline)
                    .foregroundStyle(ColorTheme.primaryText)

                Spacer()

                Text("\(food.triggerScore)%")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(scoreColor(food.triggerScore))
            }

            if !food.compoundRisks.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(food.compoundRisks, id: \.self) { compound in
                            Text(compound)
                                .typography(Typography.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(ColorTheme.warning.opacity(0.15))
                                .foregroundStyle(ColorTheme.warning)
                                .clipShape(.rect(cornerRadius: 8))
                        }
                    }
                }
            }

            Text(food.reason)
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
                .lineLimit(2)
        }
        .padding(8)
        .background(ColorTheme.background.opacity(0.5))
        .clipShape(.rect(cornerRadius: 8))
    }

    // MARK: - Empty States

    private var noSymptomsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.text.clipboard")
                .typography(Typography.largeTitle)
                .foregroundStyle(ColorTheme.secondaryText)

            Text("No Significant Symptoms")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            Text("Log symptoms with pain, urgency, or abnormal stool types to use the Symptom Explorer.")
                .typography(Typography.subheadline)
                .foregroundStyle(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.symptomExplorerEmptyState)
    }

    private var emptyMealsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .typography(Typography.title)
                .foregroundStyle(ColorTheme.secondaryText)

            Text("No Meals Found")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            Text("No meals were logged 6-24 hours before this symptom.")
                .typography(Typography.subheadline)
                .foregroundStyle(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .accessibilityIdentifier(AccessibilityIdentifiers.Insights.symptomExplorerEmptyState)
    }

    // MARK: - Helpers

    private func mealTypeBadge(_ type: MealType) -> some View {
        Text(type.rawValue)
            .typography(Typography.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(mealTypeColor(type).opacity(0.2))
            .foregroundStyle(mealTypeColor(type))
            .clipShape(.rect(cornerRadius: 8))
    }

    private func mealTypeColor(_ type: MealType) -> Color {
        switch type {
        case .breakfast: return .orange
        case .lunch: return .green
        case .dinner: return .blue
        case .snack: return .purple
        case .drink: return .cyan
        }
    }

    private func scoreColor(_ score: Int) -> Color {
        if score >= 70 { return .red }
        if score >= 40 { return .orange }
        return .yellow
    }

    private func painLabel(_ level: PainLevel) -> String {
        switch level {
        case .none: return "None"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }

    private func painColor(_ level: PainLevel) -> Color {
        switch level {
        case .none: return ColorTheme.primaryText
        case .mild: return .yellow
        case .moderate: return .orange
        case .severe: return .red
        }
    }

    private func urgencyLabel(_ level: UrgencyLevel) -> String {
        switch level {
        case .none: return "None"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .urgent: return "Urgent"
        }
    }

    private func urgencyColor(_ level: UrgencyLevel) -> Color {
        switch level {
        case .none: return ColorTheme.primaryText
        case .mild: return .yellow
        case .moderate: return .orange
        case .urgent: return .red
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SymptomExplorerView()
            .environment(LocalUserService.shared)
            .environment(AppRouter.shared)
    }
}
