//
//  MedicationsView.swift
//  GutCheck
//
//  Root view for the Medications tab. Shows today's logged doses,
//  active medications, and quick access to log a new dose.
//

import SwiftUI

struct MedicationsView: View {
    @StateObject private var viewModel   = MedicationViewModel()
    @State private var showingLogDose    = false
    @State private var showingAddMed     = false
    @State private var todayDoses: [MedicationDoseLog] = []
    @State private var isLoadingDoses    = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                logDoseButton
                todaySection
                myMedicationsSection
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 100) // clear tab bar
        }
        .navigationTitle("Medications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddMed = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add medication")
            }
        }
        .sheet(isPresented: $showingLogDose) {
            LogMedicationDoseView {
                Task { await loadTodayDoses() }
            }
        }
        .sheet(isPresented: $showingAddMed) {
            AddMedicationView {
                Task { await viewModel.loadMedications() }
            }
        }
        .confirmationDialog(
            "Delete \"\(viewModel.medicationToDelete?.name ?? "this medication")\"?",
            isPresented: $viewModel.showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let med = viewModel.medicationToDelete else { return }
                Task { await viewModel.deleteMedication(med) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the medication from your records.")
        }
        .alert("Error", isPresented: $viewModel.showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.loadingState.errorMessage ?? "An error occurred.")
        }
        .task {
            await viewModel.loadMedications()
            await loadTodayDoses()
        }
        .refreshable {
            await viewModel.loadMedications()
            await loadTodayDoses()
        }
    }

    // MARK: - Log Dose Button

    private var logDoseButton: some View {
        Button {
            showingLogDose = true
        } label: {
            HStack {
                Image(systemName: "pills.fill")
                    .font(.title2)
                Text("Log a Dose")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            .foregroundColor(.purple)
        }
        .accessibilityLabel("Log a medication dose")
        .accessibilityHint("Tap to record that you took a medication")
    }

    // MARK: - Today's Doses

    @ViewBuilder
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "Today's Doses", systemImage: "clock")

            if isLoadingDoses {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if todayDoses.isEmpty {
                EmptyCard(
                    icon: "clock.badge.questionmark",
                    message: "No doses logged today"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(todayDoses) { dose in
                        DoseRowView(dose: dose)
                        if dose.id != todayDoses.last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    // MARK: - My Medications

    @ViewBuilder
    private var myMedicationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: "My Medications", systemImage: "list.bullet")

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if viewModel.activeMedications.isEmpty {
                EmptyCard(
                    icon: "pills",
                    message: "No medications added yet"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.activeMedications) { med in
                        MedCatalogRow(medication: med)
                            .contextMenu {
                                Button(role: .destructive) {
                                    viewModel.confirmDelete(med)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        if med.id != viewModel.activeMedications.last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
            }

            // Link to full catalog
            NavigationLink(destination: MedicationListView()) {
                Text("Manage all medications…")
                    .font(.subheadline)
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Load today's doses

    private func loadTodayDoses() async {
        guard let userId = AuthenticationManager.shared.currentUserId else { return }
        isLoadingDoses = true
        do {
            todayDoses = try await MedicationDoseRepository.shared.fetchDosesForDate(Date(), userId: userId)
        } catch {
            print("⚠️ MedicationsView: failed to load today's doses: \(error)")
        }
        isLoadingDoses = false
    }
}

// MARK: - Supporting Views

private struct SectionTitle: View {
    let title: String
    let systemImage: String
    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .foregroundColor(.primary)
    }
}

private struct EmptyCard: View {
    let icon: String
    let message: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct DoseRowView: View {
    let dose: MedicationDoseLog
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(dose.medicationName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    if dose.dosageAmount > 0 {
                        Text(formattedDose(dose))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                    }
                    Text(dose.dateTaken.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func formattedDose(_ dose: MedicationDoseLog) -> String {
        let amt = dose.dosageAmount
        let formatted = amt == amt.rounded() ? "\(Int(amt))" : String(format: "%.1f", amt)
        return "\(formatted) \(dose.dosageUnit)"
    }
}

private struct MedCatalogRow: View {
    let medication: MedicationRecord
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pills.fill")
                .foregroundColor(.purple)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                HStack(spacing: 4) {
                    if medication.dosage.amount > 0 {
                        Text(formattedDosage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("·")
                            .foregroundStyle(.tertiary)
                    }
                    Text(medication.dosage.frequency.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var formattedDosage: String {
        let amt = medication.dosage.amount
        let n   = amt == amt.rounded() ? "\(Int(amt))" : String(format: "%.1f", amt)
        return "\(n) \(medication.dosage.unit)"
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        MedicationsView()
    }
}
#endif
