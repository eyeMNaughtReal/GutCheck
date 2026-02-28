//
//  LogMedicationDoseView.swift
//  GutCheck
//
//  Quick-log screen: pick a medication, confirm the time, save the dose.
//

import SwiftUI

struct LogMedicationDoseView: View {
    @StateObject private var viewModel = LogMedicationDoseViewModel()
    @Environment(\.dismiss) private var dismiss
    var onSave: (() -> Void)?

    init(onSave: (() -> Void)? = nil) { self.onSave = onSave }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading medications…").frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.availableMedications.isEmpty {
                    emptyStateView
                } else {
                    logForm
                }
            }
            .navigationTitle("Log Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Group {
                        if viewModel.isSaving { ProgressView() }
                        else {
                            Button("Log Dose") { viewModel.saveDose() }
                                .fontWeight(.semibold)
                                .disabled(!viewModel.isFormValid)
                        }
                    }
                }
            }
            .alert("Dose Logged!", isPresented: $viewModel.showingSuccessAlert) {
                Button("Done") { onSave?(); dismiss() }
            } message: {
                if let med = viewModel.selectedMedication {
                    Text("\(med.name) logged at \(viewModel.dateTaken.formatted(date: .omitted, time: .shortened)).")
                }
            }
            .alert("Error", isPresented: $viewModel.showingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.loadingState.errorMessage ?? "An error occurred.")
            }
        }
        .task { await viewModel.loadActiveMedications() }
    }

    // MARK: - Form

    private var logForm: some View {
        Form {
            Section(header: Text("Which medication?")) {
                Picker("Medication", selection: $viewModel.selectedMedication) {
                    ForEach(viewModel.availableMedications) { med in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(med.name).font(.body)
                            Text(doseLabel(med)).font(.caption).foregroundStyle(.secondary)
                        }
                        .tag(Optional(med))
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            if let med = viewModel.selectedMedication, med.dosage.amount > 0 {
                Section(header: Text("Dose")) {
                    LabeledContent("Amount") {
                        Text("\(formattedAmt(med.dosage.amount)) \(med.dosage.unit)")
                    }
                    LabeledContent("Schedule") {
                        Text(med.dosage.frequency.displayName)
                    }
                }
            }

            Section(header: Text("When did you take it?")) {
                DatePicker("Date & Time",
                           selection: $viewModel.dateTaken,
                           in: ...Date(),
                           displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
            }

            Section(header: Text("Notes (Optional)")) {
                ZStack(alignment: .topLeading) {
                    if viewModel.notes.isEmpty {
                        Text("e.g. Took with food, felt nauseous after…")
                            .foregroundStyle(.tertiary).font(.body)
                            .padding(.top, 8).padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $viewModel.notes).frame(minHeight: 72)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pills.circle")
                .font(.system(size: 56)).foregroundStyle(.secondary)
            Text("No Active Medications")
                .font(.title2).fontWeight(.semibold)
            Text("Add your medications in Settings → Medications before logging a dose.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Button("Dismiss") { dismiss() }.buttonStyle(.bordered)
        }
        .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func doseLabel(_ med: MedicationRecord) -> String {
        med.dosage.amount > 0
            ? "\(formattedAmt(med.dosage.amount)) \(med.dosage.unit) · \(med.dosage.frequency.displayName)"
            : med.dosage.frequency.displayName
    }

    private func formattedAmt(_ a: Double) -> String {
        a == a.rounded() ? "\(Int(a))" : String(format: "%.1f", a)
    }
}
