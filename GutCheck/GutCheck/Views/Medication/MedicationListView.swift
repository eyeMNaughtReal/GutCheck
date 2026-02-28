//
//  MedicationListView.swift
//  GutCheck
//
//  Full medication catalog — add, view, and delete medications.
//  Accessible from Settings and from the Meds tab's "Manage" link.
//

import SwiftUI

struct MedicationListView: View {
    @StateObject private var viewModel = MedicationViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading…").frame(maxWidth: .infinity, maxHeight: .infinity)
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
                Button { viewModel.showingAddMedication = true } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add medication")
            }
        }
        .sheet(isPresented: $viewModel.showingAddMedication) {
            AddMedicationView { Task { await viewModel.loadMedications() } }
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

    // MARK: - List

    private var medicationList: some View {
        List {
            if !viewModel.activeMedications.isEmpty {
                Section("Current") {
                    ForEach(viewModel.activeMedications) { med in
                        MedicationRowView(medication: med)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                deleteButton(for: med)
                            }
                    }
                }
            }
            if !viewModel.inactiveMedications.isEmpty {
                Section("Past Medications") {
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

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "pills.circle")
                .font(.system(size: 64)).foregroundStyle(.secondary)
            Text("No Medications Yet")
                .font(.title2).fontWeight(.semibold)
            Text("Add your current medications to track dosages, timing, and their effect on your gut health.")
                .font(.subheadline).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 32)
            Button {
                viewModel.showingAddMedication = true
            } label: {
                Label("Add Medication", systemImage: "plus.circle.fill").font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding().frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func deleteButton(for med: MedicationRecord) -> some View {
        Button(role: .destructive) { viewModel.confirmDelete(med) } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

// MARK: - Row

struct MedicationRowView: View {
    let medication: MedicationRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(medication.name).font(.headline)
                Spacer()
                if medication.isActive {
                    Text("Active")
                        .font(.caption2).fontWeight(.semibold).foregroundStyle(.green)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.green.opacity(0.12), in: Capsule())
                }
            }
            HStack(spacing: 4) {
                if medication.dosage.amount > 0 {
                    Text(formattedDosage)
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("·").foregroundStyle(.tertiary)
                }
                Text(medication.dosage.frequency.displayName)
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Text("Started \(medication.startDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var formattedDosage: String {
        let a = medication.dosage.amount
        return "\(a == a.rounded() ? "\(Int(a))" : String(format: "%.1f", a)) \(medication.dosage.unit)"
    }
}
