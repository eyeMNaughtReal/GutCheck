//
//  MedicationsView.swift
//  GutCheck
//
//  Root view for the Medications tab.
//  Shows today's logged doses, active medication list, and a Log Dose CTA.
//

import SwiftUI

struct MedicationsView: View {
    @StateObject private var listVM     = MedicationViewModel()
    @State private var todayDoses:       [MedicationDoseLog] = []
    @State private var isLoadingDoses    = false
    @State private var showingLogDose    = false
    @State private var showingAddMed     = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                logDoseBanner
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
                Button { showingAddMed = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add medication")
            }
        }
        .sheet(isPresented: $showingLogDose) {
            LogMedicationDoseView { Task { await loadTodayDoses() } }
        }
        .sheet(isPresented: $showingAddMed) {
            AddMedicationView { Task { await listVM.loadMedications() } }
        }
        .confirmationDialog(
            "Delete \"\(listVM.medicationToDelete?.name ?? "this medication")\"?",
            isPresented: $listVM.showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                guard let med = listVM.medicationToDelete else { return }
                Task { await listVM.deleteMedication(med) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the medication from your records.")
        }
        .alert("Error", isPresented: $listVM.showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(listVM.loadingState.errorMessage ?? "An error occurred.")
        }
        .task {
            await listVM.loadMedications()
            await loadTodayDoses()
        }
        .refreshable {
            await listVM.loadMedications()
            await loadTodayDoses()
        }
    }

    // MARK: - Log Dose Banner

    private var logDoseBanner: some View {
        Button { showingLogDose = true } label: {
            HStack {
                Image(systemName: "pills.fill").font(.title2)
                Text("Log a Dose").font(.headline)
                Spacer()
                Image(systemName: "chevron.right").font(.subheadline).foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.purple.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(Color.purple)
        }
        .accessibilityLabel("Log a medication dose")
        .accessibilityHint("Tap to record that you took a medication")
    }

    // MARK: - Today's Doses

    @ViewBuilder
    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Today's Doses", systemImage: "clock").font(.headline)

            if isLoadingDoses {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else if todayDoses.isEmpty {
                infoCard(icon: "clock.badge.questionmark", text: "No doses logged today")
            } else {
                cardList(todayDoses.map { dose in
                    AnyView(DoseRowView(dose: dose))
                })
            }
        }
    }

    // MARK: - My Medications

    @ViewBuilder
    private var myMedicationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("My Medications", systemImage: "list.bullet").font(.headline)

            if listVM.isLoading {
                ProgressView().frame(maxWidth: .infinity).padding()
            } else if listVM.activeMedications.isEmpty {
                infoCard(icon: "pills", text: "No medications added yet")
            } else {
                cardList(listVM.activeMedications.map { med in
                    AnyView(MedCatalogRow(medication: med)
                        .contextMenu {
                            Button(role: .destructive) { listVM.confirmDelete(med) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        })
                })
            }

            NavigationLink(destination: MedicationListView()) {
                Text("Manage all medications…")
                    .font(.subheadline).foregroundStyle(Color.purple)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    // MARK: - Shared Helpers

    private func infoCard(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(.tertiary)
            Text(text).font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
    }

    private func cardList(_ rows: [AnyView]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                row
                if idx < rows.count - 1 { Divider().padding(.leading, 16) }
            }
        }
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 14))
    }

    private func loadTodayDoses() async {
        guard let userId = AuthenticationManager.shared.currentUserId else { return }
        isLoadingDoses = true
        todayDoses = (try? await MedicationDoseRepository.shared.fetchDosesForDate(Date(), userId: userId)) ?? []
        isLoadingDoses = false
    }
}

// MARK: - Row Views

private struct DoseRowView: View {
    let dose: MedicationDoseLog
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.green).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(dose.medicationName).font(.subheadline).fontWeight(.medium)
                HStack(spacing: 4) {
                    if dose.dosageAmount > 0 {
                        Text(formattedDose).font(.caption).foregroundStyle(.secondary)
                        Text("·").foregroundStyle(.tertiary)
                    }
                    Text(dose.dateTaken.formatted(date: .omitted, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private var formattedDose: String {
        let a = dose.dosageAmount
        return "\(a == a.rounded() ? "\(Int(a))" : String(format: "%.1f", a)) \(dose.dosageUnit)"
    }
}

private struct MedCatalogRow: View {
    let medication: MedicationRecord
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pills.fill").foregroundStyle(Color.purple).font(.title3).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name).font(.subheadline).fontWeight(.medium)
                HStack(spacing: 4) {
                    if medication.dosage.amount > 0 {
                        Text(formattedDosage).font(.caption).foregroundStyle(.secondary)
                        Text("·").foregroundStyle(.tertiary)
                    }
                    Text(medication.dosage.frequency.displayName)
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    private var formattedDosage: String {
        let a = medication.dosage.amount
        return "\(a == a.rounded() ? "\(Int(a))" : String(format: "%.1f", a)) \(medication.dosage.unit)"
    }
}
