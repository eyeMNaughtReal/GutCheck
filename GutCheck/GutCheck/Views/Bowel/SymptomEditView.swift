import SwiftUI

struct SymptomEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var editedSymptom: Symptom
    var onSave: (Symptom) -> Void
    var onComplete: (() -> Void)? = nil
    
    // State for UI components to match LogSymptomView
    @State private var selectedStoolType: StoolType?
    @State private var selectedPainLevel: Int = 0
    @State private var selectedUrgencyLevel: UrgencyLevel = .none
    @State private var notes: String = ""
    @State private var symptomDate: Date = Date()
    @State private var isSaving = false
    @State private var showingSuccessAlert = false

    init(symptom: Symptom, onSave: @escaping (Symptom) -> Void, onComplete: (() -> Void)? = nil) {
        _editedSymptom = State(initialValue: symptom)
        self.onSave = onSave
        self.onComplete = onComplete
        // Initialize UI state from symptom
        _selectedStoolType = State(initialValue: symptom.stoolType)
        _selectedPainLevel = State(initialValue: symptom.painLevel.intValue)
        _selectedUrgencyLevel = State(initialValue: symptom.urgencyLevel)
        _notes = State(initialValue: symptom.notes ?? "")
        _symptomDate = State(initialValue: symptom.date)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Symptom Time
                    symptomTimeSection

                    // Bristol Stool Scale
                    Text("Bristol Stool Scale")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTheme.primaryText)
                        .padding(.bottom, 2)
                    BristolScaleSelectionView(selectedStoolType: $selectedStoolType)

                    // Pain Level
                    Text("Pain Level")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTheme.primaryText)
                        .padding(.bottom, 2)
                    PainLevelSliderView(selectedPainLevel: $selectedPainLevel)

                    // Urgency Level
                    Text("Urgency Level")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(ColorTheme.primaryText)
                        .padding(.bottom, 2)
                    UrgencyLevelSelectionView(selectedUrgencyLevel: $selectedUrgencyLevel)

                    // Notes
                    notesSection

                    // Action buttons
                    actionButtonsSection
                }
                .padding()
            }
            .background(ColorTheme.background)
            .navigationTitle("Edit Symptom")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Symptom Updated", isPresented: $showingSuccessAlert) {
                Button("OK") { 
                    onComplete?()
                }
            } message: {
                Text("Your symptom has been successfully updated.")
            }
        }
    }
    
    // MARK: - View Components
    
    private var symptomTimeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Symptom Time")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.primaryText)
            DatePicker(
                "",
                selection: $symptomDate,
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
            
            TextEditor(text: $notes)
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
                saveChanges()
            }) {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                    }
                    
                    Text(isSaving ? "Saving..." : "Save Changes")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isFormValid ? ColorTheme.primary : ColorTheme.disabled)
                )
            }
            .disabled(!isFormValid || isSaving)
            
            // Cancel button
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
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
        }
        .padding()
        .background(ColorTheme.surface)
        .cornerRadius(12)
    }
    
    private var isFormValid: Bool {
        selectedStoolType != nil
    }
    
    private func saveChanges() {
        guard let stoolType = selectedStoolType else { return }
        
        isSaving = true
        
        // Update the symptom with new values
        var updatedSymptom = editedSymptom
        updatedSymptom.date = symptomDate
        updatedSymptom.stoolType = stoolType
        updatedSymptom.painLevel = PainLevel.fromInt(selectedPainLevel)
        updatedSymptom.urgencyLevel = selectedUrgencyLevel
        updatedSymptom.notes = notes.isEmpty ? nil : notes
        
        // Call the onSave closure which will handle the backend save
        onSave(updatedSymptom)
        
        // Show success feedback and reset state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isSaving = false
            showingSuccessAlert = true
        }
    }
}

// Extension to handle PainLevel conversion
extension PainLevel {
    var intValue: Int {
        switch self {
        case .none: return 0
        case .mild: return 1
        case .moderate: return 2
        case .severe: return 3
        }
    }
    
    static func fromInt(_ value: Int) -> PainLevel {
        switch value {
        case 0: return .none
        case 1: return .mild
        case 2: return .moderate
        case 3: return .severe
        default: return .none
        }
    }
}


// Preview with mock data
#Preview {
    SymptomEditView(
        symptom: Symptom(
            date: Date(),
            stoolType: .type4,
            painLevel: .moderate,
            urgencyLevel: .mild,
            notes: "Edit notes here",
            createdBy: "testUser"
        ),
        onSave: { _ in }
    )
}
