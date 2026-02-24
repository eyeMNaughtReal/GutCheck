//
//  LogSymptomView.swift
//  GutCheck
//
//  Refactored symptom logging view using modular ViewModels and components
//  Updated for professional medical application design
//  Updated with Phase 2 Accessibility - February 23, 2026
//

import SwiftUI

// ...existing code...

struct BristolScaleSelectionView: View {
    @Binding var selectedStoolType: StoolType?
    private let bristolInfo: [(type: StoolType, summary: String, description: String)] = [
        (.type1, "Severe constipation", "Hard lumps"),
        (.type2, "Mild constipation", "Lumpy & sausage-like"),
        (.type3, "Borderline normal", "Sausage with cracks"),
        (.type4, "Ideal", "Smooth sausage"),
        (.type5, "Borderline normal", "Soft blobs"),
        (.type6, "Mild diarrhea", "Mushy consistency"),
        (.type7, "Diarrhea", "Watery liquid")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ...existing code...
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(Array(bristolInfo.enumerated()), id: \.element.type) { index, info in
                    Button(action: {
                        HapticManager.shared.bristolScaleSelected()
                        selectedStoolType = info.type
                    }) {
                        VStack(spacing: 4) {
                            Text("\(info.type.rawValue)")
                                .typography(Typography.title2)
                                .fontWeight(.bold)
                                .foregroundColor(selectedStoolType == info.type ? .white : bristolTextColor(for: info.type))
                            Text(info.summary)
                                .typography(Typography.caption)
                                .foregroundColor(selectedStoolType == info.type ? .white.opacity(0.9) : ColorTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            Text(info.description)
                                .font(.caption2)
                                .foregroundColor(selectedStoolType == info.type ? .white.opacity(0.8) : ColorTheme.secondaryText)
                                .multilineTextAlignment(.center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(height: 85)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedStoolType == info.type ? bristolColor(for: info.type) : ColorTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedStoolType == info.type ? bristolColor(for: info.type) : ColorTheme.border.opacity(0.3), lineWidth: selectedStoolType == info.type ? 2 : 1)
                        )
                    }
                    .accessibleSelectable(
                        label: AccessibilityText.bristolScale(
                            type: info.type.rawValue,
                            summary: "\(info.summary), \(info.description)",
                            isSelected: selectedStoolType == info.type
                        ),
                        isSelected: selectedStoolType == info.type
                    )
                    .accessibilityHint("Tap to select this Bristol type")
                    .accessibilityIdentifier(AccessibilityIdentifiers.SymptomLogger.bristolType(info.type.rawValue))
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
    private func bristolColor(for type: StoolType) -> Color {
        switch type {
        case .type4:
            return Color(red: 0.2, green: 0.6, blue: 0.4)
        case .type3, .type5:
            return Color(red: 0.8, green: 0.6, blue: 0.2)
        default:
            return Color(red: 0.7, green: 0.3, blue: 0.3)
        }
    }
    private func bristolTextColor(for type: StoolType) -> Color {
        switch type {
        case .type4:
            return Color(red: 0.15, green: 0.5, blue: 0.35)
        case .type3, .type5:
            return Color(red: 0.7, green: 0.5, blue: 0.1)
        default:
            return Color(red: 0.6, green: 0.2, blue: 0.2)
        }
    }
}

struct PainLevelSliderView: View {
    @Binding var selectedPainLevel: Int
    private let labels = ["None", "Mild", "Moderate", "Severe", "Extreme"]
    private let descriptions = [
        "No pain",
        "Slight discomfort",
        "Noticeable pain",
        "Significant pain",
        "Unbearable pain"
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ...existing code...
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    ForEach(0..<labels.count, id: \ .self) { i in
                        Button(action: {
                            HapticManager.shared.selection()
                            selectedPainLevel = i
                        }) {
                            VStack(spacing: 4) {
                                Text("\(i)")
                                    .typography(Typography.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedPainLevel == i ? .white : painColor(for: i))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(selectedPainLevel == i ? painColor(for: i) : ColorTheme.cardBackground)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(painColor(for: i), lineWidth: selectedPainLevel == i ? 2 : 1)
                                    )
                                Text(labels[i])
                                    .typography(Typography.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedPainLevel == i ? ColorTheme.primaryText : ColorTheme.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(PlainButtonStyle())
                        .accessibleSelectable(
                            label: AccessibilityText.painLevel(
                                level: i,
                                description: "\(labels[i]): \(descriptions[i])",
                                isSelected: selectedPainLevel == i
                            ),
                            isSelected: selectedPainLevel == i
                        )
                        .accessibilityHint("Tap to select pain level \(i)")
                        .accessibilityIdentifier(AccessibilityIdentifiers.SymptomLogger.painLevel(i))
                    }
                }
                if selectedPainLevel < descriptions.count {
                    Text(descriptions[selectedPainLevel])
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
    private func painColor(for level: Int) -> Color {
        switch level {
        case 0:
            return Color(red: 0.3, green: 0.7, blue: 0.3)
        case 1:
            return Color(red: 0.6, green: 0.8, blue: 0.2)
        case 2:
            return Color(red: 0.9, green: 0.7, blue: 0.1)
        case 3:
            return Color(red: 0.9, green: 0.5, blue: 0.2)
        case 4:
            return Color(red: 0.8, green: 0.2, blue: 0.2)
        default:
            return ColorTheme.secondaryText
        }
    }
}

struct UrgencyLevelSelectionView: View {
    @Binding var selectedUrgencyLevel: UrgencyLevel

    private let urgencyLevels: [(UrgencyLevel, String)] = [
        (.none, "None"),
        (.mild, "Mild"),
        (.moderate, "Moderate"),
        (.urgent, "Urgent")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ...existing code...
            HStack(spacing: 8) {
                ForEach(urgencyLevels, id: \.0) { (level, label) in
                    Button(action: {
                        HapticManager.shared.selection()
                        selectedUrgencyLevel = level
                    }) {
                        VStack(spacing: 8) {
                            // Color indicator
                            Circle()
                                .fill(urgencyColor(for: level))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(selectedUrgencyLevel == level ? urgencyColor(for: level).opacity(0.3) : Color.clear, lineWidth: 4)
                                        .scaleEffect(1.3)
                                )
                            
                            Text(label)
                                .typography(Typography.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedUrgencyLevel == level ? ColorTheme.primaryText : ColorTheme.secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedUrgencyLevel == level ? ColorTheme.accent.opacity(0.05) : Color.clear)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibleSelectable(
                        label: "Urgency level: \(label)",
                        isSelected: selectedUrgencyLevel == level
                    )
                    .accessibilityHint("Tap to select \(label) urgency")
                    .accessibilityIdentifier(AccessibilityIdentifiers.SymptomLogger.urgencyLevel(label))
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
    
    private func urgencyColor(for level: UrgencyLevel) -> Color {
        switch level {
        case .none:
            return Color(red: 0.3, green: 0.7, blue: 0.3) // Green
        case .mild:
            return Color(red: 0.9, green: 0.8, blue: 0.2) // Yellow
        case .moderate:
            return Color(red: 0.9, green: 0.6, blue: 0.2) // Orange
        case .urgent:
            return Color(red: 0.8, green: 0.3, blue: 0.3) // Red
        }
    }
}

struct TagSelectionView: View {
    @Binding var selectedTags: Set<String>

    private let allTags: [String] = ["pain", "urgency", "blood", "mucus", "cramping", "bloating", "constipation", "diarrhea", "normal"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .typography(Typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                ForEach(allTags, id: \.self) { tag in
                    Button(action: {
                        HapticManager.shared.selection()
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }) {
                        Text(tag.capitalized)
                            .typography(Typography.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .foregroundColor(selectedTags.contains(tag) ? .white : ColorTheme.secondaryText)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedTags.contains(tag) ? ColorTheme.accent : ColorTheme.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(selectedTags.contains(tag) ? ColorTheme.accent : ColorTheme.border.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibleSelectable(
                        label: tag.capitalized,
                        isSelected: selectedTags.contains(tag)
                    )
                    .accessibilityHint("Tap to toggle \(tag) tag")
                    .accessibilityIdentifier(AccessibilityIdentifiers.SymptomLogger.tag(tag))
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
}

struct LogSymptomView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var coordinator = LogSymptomViewModel()
    @State private var showProfileSheet = false
    @State private var infoTypeToShow: SymptomInfoType? = nil
    @State private var showingDatePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Symptom Time
                    symptomTimeSection

                    // Bristol Stool Scale
                    SectionHeader(title: "Bristol Stool Scale") {
                        infoTypeToShow = .bristol
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.SymptomLogger.bristolScaleSection)
                    BristolScaleSelectionView(selectedStoolType: $coordinator.selectedStoolType)

                    // Pain Level
                    SectionHeader(title: "Pain Level") {
                        infoTypeToShow = .pain
                    }
                    .accessibilityIdentifier(AccessibilityIdentifiers.SymptomLogger.painLevelSection)
                    PainLevelSliderView(selectedPainLevel: $coordinator.selectedPainLevel)

                    // Urgency Level
                    SectionHeader(title: "Urgency Level") {
                        infoTypeToShow = .urgency
                    }
                    UrgencyLevelSelectionView(selectedUrgencyLevel: $coordinator.selectedUrgencyLevel)

                    // Tag selection
                    TagSelectionView(selectedTags: $coordinator.selectedTags)
                        .accessibilityIdentifier(AccessibilityIdentifiers.SymptomLogger.tagsSection)

                    // Notes
                    notesSection

                    // Action buttons
                    actionButtonsSection
                }
                .padding()
            }
            .background(ColorTheme.background)
            .navigationTitle("Log Symptoms")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $infoTypeToShow) { infoType in
                SymptomInfoViews(infoType: infoType)
            }
            .sheet(isPresented: $showingDatePicker) {
                datePickerSheet
            }
            .alert("Symptom Saved", isPresented: $coordinator.showingSuccessAlert) {
                Button("OK") { 
                    dismiss()
                }
            } message: {
                Text("Your symptom has been successfully logged.")
            }
            .alert("Error", isPresented: $coordinator.showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(coordinator.errorMessage ?? "An unknown error occurred.")
            }
        }
    }
// Section header with info button
struct SectionHeader: View {
    let title: String
    let onInfo: () -> Void
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .typography(Typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)
                .accessibleHeader(title)
            Button(action: {
                HapticManager.shared.light()
                onInfo()
            }) {
                Image(systemName: "info.circle")
                    .font(.title3)
                    .foregroundColor(ColorTheme.primary)
            }
            .accessibleButton(
                label: "Information about \(title)",
                hint: "Tap to learn more about \(title)"
            )
            Spacer()
        }
        .padding(.bottom, 2)
    }
}
// ...existing code...
    
    // MARK: - View Components
    
    private var symptomTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptom Time")
                .typography(Typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)
            Button(action: {
                HapticManager.shared.light()
                showingDatePicker = true
            }) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(ColorTheme.primary)
                        .accessibleDecorative()
                    Text(coordinator.symptomDate.formattedDateTime)
                        .typography(Typography.body)
                        .foregroundColor(ColorTheme.primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.surface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(ColorTheme.border, lineWidth: 1)
                )
            }
            .accessibleButton(
                label: "Symptom date and time: \(coordinator.symptomDate.formattedDateTime)",
                hint: "Tap to change when this symptom occurred"
            )
            .accessibilityIdentifier(AccessibilityIdentifiers.SymptomLogger.dateTimeButton)
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .typography(Typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)
            
            TextEditor(text: $coordinator.notes)
                .typography(Typography.body)
                .frame(minHeight: 100)
                .padding(12)
                .background(ColorTheme.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorTheme.border.opacity(0.3), lineWidth: 1)
                )
                .accessibleFormField(label: "Notes")
                .accessibilityHint("Add any additional details about your symptoms")
                .accessibilityIdentifier(AccessibilityIdentifiers.SymptomLogger.notesField)
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Save button
            Button(action: {
                HapticManager.shared.dataSaved()
                coordinator.saveSymptom()
                AccessibilityAnnouncement.announce("Symptom saved successfully")
            }) {
                HStack(spacing: 8) {
                    if coordinator.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                            .accessibleDecorative()
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .accessibleDecorative()
                    }
                    
                    Text(coordinator.isSaving ? "Saving..." : "Save Symptom")
                        .typography(Typography.button)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(coordinator.isFormValid ? ColorTheme.primary : ColorTheme.disabled)
                )
            }
            .disabled(!coordinator.isFormValid || coordinator.isSaving)
            .accessibleButton(
                label: coordinator.isSaving ? "Saving symptom" : "Save Symptom",
                hint: coordinator.isFormValid 
                    ? "Tap to save your symptom log"
                    : "Complete Bristol Scale selection to enable saving"
            )
            .accessibilityIdentifier(AccessibilityIdentifiers.SymptomLogger.saveButton)
            
            HStack(spacing: 12) {
                // Clear button
                Button(action: {
                    HapticManager.shared.light()
                    coordinator.resetForm()
                    AccessibilityAnnouncement.announce("Form cleared")
                }) {
                    Text("Clear")
                        .typography(Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ColorTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ColorTheme.cardBackground)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ColorTheme.border.opacity(0.3), lineWidth: 1)
                        )
                }
                .disabled(!coordinator.hasChanges)
                .accessibleButton(
                    label: "Clear",
                    hint: coordinator.hasChanges 
                        ? "Clear all entered symptom information"
                        : "No changes to clear"
                )
                
                // Remind me later button
                Button(action: {
                    HapticManager.shared.light()
                    coordinator.remindMeLater()
                    AccessibilityAnnouncement.announce("Reminder set")
                }) {
                    Text("Remind Later")
                        .typography(Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ColorTheme.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ColorTheme.primary.opacity(0.05))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ColorTheme.primary.opacity(0.3), lineWidth: 1)
                        )
                }
                .accessibleButton(
                    label: "Remind me later",
                    hint: "Set a reminder to log symptoms later"
                )
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }

    private var datePickerSheet: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date and Time",
                    selection: $coordinator.symptomDate,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .accentColor(ColorTheme.primary)
                .padding()
                .accessibleFormField(
                    label: "Symptom date and time",
                    value: coordinator.symptomDate.formatted(date: .abbreviated, time: .shortened)
                )
                .accessibilityHint("Choose when this symptom occurred")
                
                Spacer()
                
                Button("Done") {
                    HapticManager.shared.light()
                    AccessibilityAnnouncement.announce("Date and time updated")
                    showingDatePicker = false
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .accessibleButton(
                    label: "Done",
                    hint: "Confirm the selected date and time"
                )
            }
            .background(ColorTheme.surface)
            .navigationTitle("Symptom Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        HapticManager.shared.light()
                        showingDatePicker = false
                    }
                    .accessibleButton(
                        label: "Cancel",
                        hint: "Discard changes and close"
                    )
                }
            }
        }
    }
}

// MARK: - Component Stubs

#if DEBUG
#Preview {
    LogSymptomView()
        .environmentObject(AuthService())
}
#endif
