//
//  LogMedicationDoseView.swift
//  GutCheck
//
//  Quick-log screen: pick a medication from your active list,
//  confirm the time taken, and save the dose record.
//

import SwiftUI

struct LogMedicationDoseView: View {
    @StateObject private var viewModel = LogMedicationDoseViewModel()
    @Environment(\.dismiss) private var dismiss

    var onSave: (() -> Void)?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.availableMedications.isEmpty {
                    emptyStateView
                } else {
                    logForm
                }
            }
            .navigationTitle("Log Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .alert("Dose Logged!", isPresented: $viewModel.showingSuccessAlert) {
                Button("Done") {
                    onSave?()
                    dismiss()
                }
            } message: {
                if let med = viewModel.selectedMedication {
                    Text("\(med.name) logged at \(viewModel.dateTaken.formatted(date: .omitted, time: .shortened)).")
                }
            }
            .alert("Error", isPresented: $viewModel.showingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.loadingState.errorMessage ?? "An error occurred. Please try again.")
            }
        }
        .task { await viewModel.loadActiveMedications() }
    }

    // MARK: - Form

    private var logForm: some View {
        Form {
            // ── Medication picker ─────────────────────────────────────
            Section(header: Text("Which medication?")) {
                Picker("Medication", selection: $viewModel.selectedMedication) {
                    ForEach(viewModel.availableMedications) { med in
                        MedicationPickerRow(medication: med).tag(Optional(med))
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            // ── Dosage summary (read-only, derived from selected med) ─
            if let med = viewModel.selectedMedication, med.dosage.amount > 0 {
                Section(header: Text("Dose")) {
                    HStack {
                        Label("Amount", systemImage: "pills")
                        Spacer()
                        Text("\(formattedAmount(med.dosage.amount)) \(med.dosage.unit)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Schedule", systemImage: "repeat")
                        Spacer()
                        Text(med.dosage.frequency.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // ── When taken ────────────────────────────────────────────
            Section(header: Text("When did you take it?")) {
                DatePicker(
                    "Date & Time",
                    selection: $viewModel.dateTaken,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.compact)
            }

            // ── Notes ─────────────────────────────────────────────────
            Section(header: Text("Notes (Optional)")) {
                ZStack(alignment: .topLeading) {
                    if viewModel.notes.isEmpty {
                        Text("e.g. Took with food, felt nauseous after…")
                            .foregroundStyle(.tertiary)
                            .font(.body)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $viewModel.notes)
                        .frame(minHeight: 72)
                }
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        ProgressView("Loading medications…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pills.circle")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("No Active Medications")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add your medications in Settings → Health Data → My Medications before logging a dose.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Dismiss") { dismiss() }
                .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Group {
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    Button("Log Dose") { viewModel.saveDose() }
                        .fontWeight(.semibold)
                        .disabled(!viewModel.isFormValid)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formattedAmount(_ amount: Double) -> String {
        amount == amount.rounded() ? "\(Int(amount))" : String(format: "%.1f", amount)
    }
}

// MARK: - Medication Picker Row

private struct MedicationPickerRow: View {
    let medication: MedicationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(medication.name)
                .font(.body)
            if medication.dosage.amount > 0 {
                Text("\(formattedAmount(medication.dosage.amount)) \(medication.dosage.unit) · \(medication.dosage.frequency.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(medication.dosage.frequency.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func formattedAmount(_ amount: Double) -> String {
        amount == amount.rounded() ? "\(Int(amount))" : String(format: "%.1f", amount)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    LogMedicationDoseView()
}
#endif
