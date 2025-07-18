// MARK: - Component Stubs

#if DEBUG
#Preview {
    LogSymptomView()
        .environmentObject(AuthService())
}
#endif

struct BristolScaleSelectionView: View {
    @Binding var selectedStoolType: StoolType?
    var body: some View {
        Text("[Bristol Scale Selection]")
    }
}

struct PainLevelSliderView: View {
    @Binding var selectedPainLevel: Int
    var body: some View {
        Text("[Pain Level Slider]")
    }
}

struct UrgencyLevelSelectionView: View {
    @Binding var selectedUrgencyLevel: UrgencyLevel
    var body: some View {
        Text("[Urgency Level Selection]")
    }
}

struct TagSelectionView: View {
    @Binding var selectedTags: Set<String>
    var body: some View {
        Text("[Tag Selection]")
    }
}
//
//  LogSymptomView.swift
//  GutCheck
//
//  Refactored symptom logging view using modular ViewModels and components
//

import SwiftUI

struct LogSymptomView: View {
    @EnvironmentObject var authService: AuthService
    @State private var coordinator = LogSymptomViewModel()
    @State private var showProfileSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
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
            .navigationTitle("Log Symptoms")
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Date & Time")
                .font(.headline)
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            TextEditor(text: $coordinator.notes)
                .frame(minHeight: 100)
                .padding(8)
                .background(ColorTheme.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(ColorTheme.border, lineWidth: 1)
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
                HStack {
                    if coordinator.isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                    }
                    
                    Text(coordinator.isSaving ? "Saving..." : "Save Symptom")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
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
                        .foregroundColor(ColorTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ColorTheme.border, lineWidth: 1)
                        )
                }
                .disabled(!coordinator.hasChanges)
                
                // Remind me later button
                Button(action: {
                    coordinator.remindMeLater()
                }) {
                    Text("Remind Me Later")
                        .font(.subheadline)
                        .foregroundColor(ColorTheme.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ColorTheme.primary, lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
}

#Preview {
    LogSymptomView()
        .environmentObject(AuthService())
}
