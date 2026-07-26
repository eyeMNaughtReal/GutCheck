//
//  AddMedicationView.swift
//  GutCheck
//
//  Form for adding a new medication record.
//

import SwiftUI

struct AddMedicationView: View {
    @State private var viewModel = AddMedicationViewModel()
    @Environment(\.dismiss) private var dismiss

    /// Called after a successful save so the parent list can refresh.
    var onSave: (() -> Void)?

    /// Existing record to edit. Nil adds a new medication.
    private let medicationToEdit: MedicationRecord?

    init(medication: MedicationRecord? = nil, onSave: (() -> Void)? = nil) {
        self.medicationToEdit = medication
        self.onSave = onSave
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                dosageSection
                datesSection
                statusSection
                notesSection
            }
            .scrollContentBackground(.hidden)
            .background(ColorTheme.background)
            .navigationTitle(viewModel.isEditing ? "Edit Medication" : "Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .task {
                // Populate once; re-running would discard in-progress edits.
                if let medicationToEdit, !viewModel.isEditing {
                    viewModel.load(medicationToEdit)
                }
            }
            .alert(viewModel.isEditing ? "Medication Updated" : "Medication Added",
                   isPresented: $viewModel.showingSuccessAlert) {
                Button("Done") {
                    onSave?()
                    dismiss()
                }
            } message: {
                Text(viewModel.isEditing
                     ? "\(viewModel.name) has been updated."
                     : "\(viewModel.name) has been saved to your medications.")
            }
            .alert("Error", isPresented: $viewModel.showingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.loadingState.errorMessage ?? "An error occurred. Please try again.")
            }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section(header: Text("Medication Name")) {
            TextField("e.g. Omeprazole, Metronidazole", text: $viewModel.name)
                .textContentType(.none)
                .autocorrectionDisabled()
                .accessibilityLabel("Medication name")
        }
    }

    private var dosageSection: some View {
        Section(header: Text("Dosage")) {
            HStack {
                TextField("Amount", text: $viewModel.dosageAmount)
                    .keyboardType(.decimalPad)
                    .frame(minWidth: 60)
                    .accessibilityLabel("Dosage amount")

                Divider()

                Picker("Unit", selection: $viewModel.dosageUnit) {
                    ForEach(dosageUnits, id: \.self) { unit in
                        Text(unit).tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("Dosage unit: \(viewModel.dosageUnit)")
            }

            Picker("Frequency", selection: $viewModel.frequency) {
                ForEach(MedicationFrequency.allCases, id: \.self) { freq in
                    Text(freq.displayName).tag(freq)
                }
            }
            .accessibilityLabel("Frequency: \(viewModel.frequency.displayName)")
        }
    }

    private var datesSection: some View {
        Section(header: Text("Dates")) {
            DatePicker(
                "Start Date",
                selection: $viewModel.startDate,
                displayedComponents: .date
            )

            Toggle("Set End Date", isOn: $viewModel.hasEndDate)

            if viewModel.hasEndDate {
                DatePicker(
                    "End Date",
                    selection: $viewModel.endDate,
                    in: viewModel.startDate...,
                    displayedComponents: .date
                )
            }
        }
    }

    private var statusSection: some View {
        Section {
            Toggle(isOn: $viewModel.isActive) {
                Label("Currently Taking", systemImage: "checkmark.seal")
            }
        } footer: {
            Text("Uncheck if this is a past medication you want to track.")
        }
    }

    private var notesSection: some View {
        Section(header: Text("Notes (Optional)")) {
            ZStack(alignment: .topLeading) {
                if viewModel.notes.isEmpty {
                    Text("e.g. Take with food, prescribed by Dr. Smith…")
                        .foregroundStyle(.secondary)
                        .typography(Typography.body)
                        .padding(.top, 8)
                        .padding(.leading, 4)
                        .allowsHitTesting(false)
                }
                TextEditor(text: $viewModel.notes)
                    .frame(minHeight: 80)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Group {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button("Save") { viewModel.saveMedication() }
                        .fontWeight(.semibold)
                        .disabled(!viewModel.isFormValid)
                }
            }
        }
    }

    // MARK: - Constants

    private let dosageUnits = ["mg", "mcg", "g", "ml", "IU", "tablet", "capsule", "drop", "patch"]
}

// MARK: - Preview

#if DEBUG
#Preview {
    AddMedicationView()
}
#endif
