//
//  MedicationListView.swift
//  GutCheck
//
//  Displays the user's active and past medications, with the ability
//  to add new entries manually and delete existing ones.
//

import SwiftUI

struct MedicationListView: View {
    @StateObject private var viewModel = MedicationViewModel()

    // MARK: - Body

    var body: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.allMedications.isEmpty {
                emptyStateView
            } else {
                medicationList
            }
        }
        .navigationTitle("My Medications")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showingAddMedication = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add medication")
            }
        }
        .sheet(isPresented: $viewModel.showingAddMedication) {
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
        .refreshable { await viewModel.loadMedications() }
        .task { await viewModel.loadMedications() }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        ProgressView("Loading medications…")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var medicationList: some View {
        List {
            // ── Active ────────────────────────────────────────────────
            if !viewModel.activeMedications.isEmpty {
                Section(header: Text("Current")) {
                    ForEach(viewModel.activeMedications) { med in
                        MedicationRowView(medication: med)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                deleteButton(for: med)
                            }
                    }
                }
            }

            // ── Past ──────────────────────────────────────────────────
            if !viewModel.inactiveMedications.isEmpty {
                Section(header: Text("Past Medications")) {
                    ForEach(viewModel.inactiveMedications) { med in
                        MedicationRowView(medication: med)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                deleteButton(for: med)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pills.circle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No Medications Yet")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Add your current medications to track dosages and timing, and help GutCheck surface insights about how they affect your gut health.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                viewModel.showingAddMedication = true
            } label: {
                Label("Add Medication", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityLabel("Add your first medication")
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func deleteButton(for medication: MedicationRecord) -> some View {
        Button(role: .destructive) {
            viewModel.confirmDelete(medication)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Medication Row

private struct MedicationRowView: View {
    let medication: MedicationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Name + active badge
            HStack(alignment: .firstTextBaseline) {
                Text(medication.name)
                    .font(.headline)
                Spacer()
                if medication.isActive {
                    Text("Active")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.12), in: Capsule())
                }
            }

            // Dosage + frequency
            HStack(spacing: 4) {
                if medication.dosage.amount > 0 {
                    Text(formattedDosage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("·")
                        .foregroundColor(.tertiary)
                }
                Text(medication.dosage.frequency.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Source + start date
            HStack(spacing: 4) {
                Image(systemName: sourceIcon)
                    .font(.caption2)
                    .foregroundColor(.tertiary)
                Text(dateLabel)
                    .font(.caption)
                    .foregroundColor(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - Helpers

    private var formattedDosage: String {
        let amt = medication.dosage.amount
        if amt == amt.rounded() {
            return "\(Int(amt)) \(medication.dosage.unit)"
        } else {
            return "\(String(format: "%.1f", amt)) \(medication.dosage.unit)"
        }
    }

    private var sourceIcon: String {
        switch medication.source {
        case .healthKit: return "heart.fill"
        case .pharmacy:  return "cross.case.fill"
        case .doctor:    return "stethoscope"
        case .manual:    return "pencil"
        }
    }

    private var dateLabel: String {
        let started = medication.startDate.formatted(date: .abbreviated, time: .omitted)
        if let end = medication.endDate {
            return "Started \(started) · ended \(end.formatted(date: .abbreviated, time: .omitted))"
        }
        return "Started \(started)"
    }

    private var accessibilityDescription: String {
        var parts = [medication.name, medication.dosage.frequency.displayName]
        if medication.dosage.amount > 0 { parts.insert(formattedDosage, at: 1) }
        if medication.isActive { parts.append("Active") }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        MedicationListView()
    }
}
#endif
