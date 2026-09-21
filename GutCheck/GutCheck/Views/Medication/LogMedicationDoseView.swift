//
//  LogMedicationDoseView.swift
//  GutCheck
//
//  Quick-log screen: pick a medication from your active list,
//  confirm the time taken, and save the dose record.
//

import SwiftUI

struct LogMedicationDoseView: View {
    @State private var viewModel = LogMedicationDoseViewModel()
    @Environment(\.dismiss) private var dismiss

    /// Presents medication entry straight from the empty state.
    @State private var showingAddMedication = false

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
            .scrollContentBackground(.hidden)
            .background(ColorTheme.background)
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
            // Reloads on save, so adding a medication replaces the empty state
            // with the form in place rather than making someone dismiss this
            // screen and open it again.
            .sheet(isPresented: $showingAddMedication) {
                AddMedicationView {
                    Task { await viewModel.loadActiveMedications() }
                }
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
                    in: ...Date.now,
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
                            .typography(Typography.body)
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

    /// Empty state for when there is nothing to log against.
    ///
    /// `ContentUnavailableView` rather than a hand-built stack: it supplies the
    /// platform's own metrics, spacing and Dynamic Type behaviour, which the
    /// previous version approximated with a fixed `.padding(.horizontal, 32)`
    /// and a hardcoded 56pt glyph.
    ///
    /// The old copy read "Settings → Health Data → My Medications". There is no
    /// "Health Data" level in Settings — the real row sits under Medications —
    /// so anyone following it went hunting for a screen that does not exist,
    /// made worse by Settings having a plausible-looking "Healthcare" section.
    /// That instruction is not corrected here, it is gone: the action is offered
    /// directly, which leaves no path to describe and none to get wrong.
    ///
    /// The old "Dismiss" button is gone too. It sat where the useful action
    /// belongs, and Cancel in the toolbar already dismisses, as does swiping
    /// down — three ways out and none forward.
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Active Medications", systemImage: "pills")
        } description: {
            Text("Add a medication before logging a dose.")
        } actions: {
            Button("Add Medication") {
                showingAddMedication = true
            }
            .buttonStyle(.borderedProminent)
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
                    Button("Log Dose") { viewModel.saveDose() }
                        .fontWeight(.semibold)
                        .disabled(!viewModel.isFormValid)
                }
            }
        }
    }

    // MARK: - Helpers

    private func formattedAmount(_ amount: Double) -> String {
        amount == amount.rounded() ? "\(Int(amount))" : amount.formatted(.number.precision(.fractionLength(1)))
    }
}

// MARK: - Medication Picker Row

private struct MedicationPickerRow: View {
    let medication: MedicationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(medication.name)
                .typography(Typography.body)
            if medication.dosage.amount > 0 {
                Text("\(formattedAmount(medication.dosage.amount)) \(medication.dosage.unit) · \(medication.dosage.frequency.displayName)")
                    .typography(Typography.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(medication.dosage.frequency.displayName)
                    .typography(Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    private func formattedAmount(_ amount: Double) -> String {
        amount == amount.rounded() ? "\(Int(amount))" : amount.formatted(.number.precision(.fractionLength(1)))
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    LogMedicationDoseView()
}
#endif
