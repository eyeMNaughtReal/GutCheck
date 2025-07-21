//
//  LogSymptomView.swift
//  GutCheck
//
//  Refactored symptom logging view using modular ViewModels and components
//  Updated for professional medical application design
//

import SwiftUI

struct BristolScaleSelectionView: View {
    @Binding var selectedStoolType: StoolType?

    // Bristol type info with clinical descriptions
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
            Text("Bristol Stool Scale")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)

            // Professional grid with subtle styling
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(bristolInfo, id: \.type) { info in
                    Button(action: {
                        selectedStoolType = info.type
                    }) {
                        VStack(spacing: 4) {
                            Text("\(info.type.rawValue)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(selectedStoolType == info.type ? .white : bristolTextColor(for: info.type))
                            
                            Text(info.summary)
                                .font(.caption)
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
                    .accessibilityLabel("Type \(info.type.rawValue): \(info.summary), \(info.description)")
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }

    // Professional medical color scheme
    private func bristolColor(for type: StoolType) -> Color {
        switch type {
        case .type4:
            return Color(red: 0.2, green: 0.6, blue: 0.4) // Muted green
        case .type3, .type5:
            return Color(red: 0.8, green: 0.6, blue: 0.2) // Muted amber
        default:
            return Color(red: 0.7, green: 0.3, blue: 0.3) // Muted red
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
            Text("Pain Level")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)

            // Professional numeric scale
            VStack(spacing: 12) {
                HStack(spacing: 0) {
                    ForEach(0..<labels.count, id: \.self) { i in
                        Button(action: {
                            selectedPainLevel = i
                        }) {
                            VStack(spacing: 4) {
                                // Numeric indicator
                                Text("\(i)")
                                    .font(.title2)
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
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedPainLevel == i ? ColorTheme.primaryText : ColorTheme.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Description for selected level
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
            return Color(red: 0.3, green: 0.7, blue: 0.3) // Green
        case 1:
            return Color(red: 0.6, green: 0.8, blue: 0.2) // Light green
        case 2:
            return Color(red: 0.9, green: 0.7, blue: 0.1) // Yellow
        case 3:
            return Color(red: 0.9, green: 0.5, blue: 0.2) // Orange
        case 4:
            return Color(red: 0.8, green: 0.2, blue: 0.2) // Red
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
            Text("Urgency Level")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)

            HStack(spacing: 8) {
                ForEach(urgencyLevels, id: \.0) { (level, label) in
                    Button(action: {
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
                                .font(.caption)
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
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], spacing: 8) {
                ForEach(allTags, id: \.self) { tag in
                    Button(action: {
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }) {
                        Text(tag.capitalized)
                            .font(.caption)
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
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
}

struct LogSymptomView: View {
    @EnvironmentObject var authService: AuthService
    @State private var coordinator = LogSymptomViewModel()
    @State private var showProfileSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date & Time
                    dateTimeSection
                    
                    // Bristol Stool Scale
                    BristolScaleSelectionView(selectedStoolType: $coordinator.selectedStoolType)
                    
                    // Pain Level
                    PainLevelSliderView(selectedPainLevel: $coordinator.selectedPainLevel)
                    
                    // Urgency Level
                    UrgencyLevelSelectionView(selectedUrgencyLevel: $coordinator.selectedUrgencyLevel)
                    
                    // Tag selection
                    TagSelectionView(selectedTags: $coordinator.selectedTags)
                    
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileAvatarButton {
                        showProfileSheet = true
                    }
                }
            }
            .sheet(isPresented: $showProfileSheet) {
                if let currentUser = authService.currentUser {
                    UserProfileView(user: currentUser)
                        .environmentObject(authService)
                }
            }
            .alert("Symptom Saved", isPresented: $coordinator.showingSuccessAlert) {
                Button("OK") { }
            } message: {
                Text("Your symptom has been successfully logged.")
            }
            .alert("Error", isPresented: $coordinator.showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(coordinator.errorMessage)
            }
        }
    }
    
    // MARK: - View Components
    
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date & Time")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)
            
            DatePicker(
                "Symptom Date",
                selection: $coordinator.symptomDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .accentColor(ColorTheme.primary)
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)
            
            TextEditor(text: $coordinator.notes)
                .frame(minHeight: 100)
                .padding(12)
                .background(ColorTheme.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorTheme.border.opacity(0.3), lineWidth: 1)
                )
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // Save button
            Button(action: {
                coordinator.saveSymptom()
            }) {
                HStack(spacing: 8) {
                    if coordinator.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                    }
                    
                    Text(coordinator.isSaving ? "Saving..." : "Save Symptom")
                        .font(.headline)
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
            
            HStack(spacing: 12) {
                // Clear button
                Button(action: {
                    coordinator.resetForm()
                }) {
                    Text("Clear")
                        .font(.subheadline)
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
                
                // Remind me later button
                Button(action: {
                    coordinator.remindMeLater()
                }) {
                    Text("Remind Later")
                        .font(.subheadline)
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
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
}

// MARK: - Component Stubs

#if DEBUG
#Preview {
    LogSymptomView()
        .environmentObject(AuthService())
}
#endif
