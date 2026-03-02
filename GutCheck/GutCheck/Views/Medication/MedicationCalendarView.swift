//
//  MedicationCalendarView.swift
//  GutCheck
//
//  Calendar-style view for the Meds tab — mirrors CalendarView for Meals and Symptoms.
//  Shows a week selector, daily medication summary card, a Log Dose CTA, and per-dose rows.
//

import SwiftUI

// MARK: - Main View

struct MedicationCalendarView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var refreshManager: RefreshManager
    @StateObject private var viewModel = MedicationCalendarViewModel()
    @State private var showingLogDose        = false
    @State private var showingAddMedication  = false

    var body: some View {
        VStack(spacing: 0) {
            // Week Selector
            WeekSelector(selectedDate: $viewModel.selectedDate) { date in
                viewModel.selectedDate = date
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            // Content List
            List {
                // ── Medications static header ──
                CalendarMedicationsSectionHeader(viewModel: viewModel) {
                    showingLogDose = true
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)

                // ── Individual dose rows ──
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 100)
                        .accessibilityLabel("Loading medications")
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                } else if viewModel.doses.isEmpty {
                    EmptyStateCard(
                        icon: "pills.fill",
                        title: "No doses logged",
                        message: "Tap Log Dose above to record a medication"
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                } else {
                    ForEach(Array(viewModel.doses.enumerated()), id: \.element.id) { _, dose in
                        DoseCalendarRow(dose: dose)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 4)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    HapticManager.shared.warning()
                                    Task { await viewModel.deleteDose(dose.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }

                    Color.clear.frame(height: 16)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Meds")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ProfileAvatarButton(user: authService.currentUser) {
                    router.showProfile()
                }
            }
            ToolbarItem(placement: .navigationBarLeading) {
                NavigationLink(destination: MedicationListView()) {
                    Image(systemName: "list.bullet")
                        .accessibilityLabel("Manage medications")
                }
            }
        }
        .onAppear {
            Task { await viewModel.loadDoses() }
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
            Task { await viewModel.loadDoses() }
        }
        .onChange(of: refreshManager.refreshToken) { _, _ in
            Task { await viewModel.loadDoses() }
        }
        .refreshable {
            await viewModel.loadDoses()
        }
        .sheet(isPresented: $showingLogDose) {
            LogMedicationDoseView {
                Task { await viewModel.loadDoses() }
            }
        }
        .sheet(isPresented: $showingAddMedication) {
            AddMedicationView { }
        }
    }
}

// MARK: - Medications Section Header

struct CalendarMedicationsSectionHeader: View {
    @ObservedObject var viewModel: MedicationCalendarViewModel
    let onLogDose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Daily summary card
            DailyMedicationCard(doses: viewModel.doses)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)

            // Log Dose inline button
            Button {
                HapticManager.shared.medium()
                onLogDose()
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Log Dose")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(Color.purple)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .accessibleButton(label: "Log Dose", hint: "Tap to log a medication dose")

            // Section header label
            Text("Medications")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 12)
        }
    }
}

// MARK: - Daily Medication Card

struct DailyMedicationCard: View {
    let doses: [MedicationDoseLog]

    private var uniqueMedNames: [String] {
        Array(Set(doses.map(\.medicationName))).sorted()
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Daily Medications")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }

            if doses.isEmpty {
                Text("Log a dose to see your daily medication summary.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Dose count — prominent
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(doses.count)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("dose\(doses.count == 1 ? "" : "s") taken")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                // Medication name pills
                if !uniqueMedNames.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(uniqueMedNames, id: \.self) { name in
                                MedNamePill(name: name)
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(doses.isEmpty
            ? "Daily medication summary — no doses logged"
            : "Daily medication summary: \(doses.count) dose\(doses.count == 1 ? "" : "s") taken."
        )
    }
}

private struct MedNamePill: View {
    let name: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "pills.fill")
                .font(.caption2)
                .foregroundColor(.purple)
            Text(name)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.purple.opacity(0.12))
        .cornerRadius(8)
    }
}

// MARK: - Dose Row

struct DoseCalendarRow: View {
    let dose: MedicationDoseLog

    private var formattedTime: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: dose.dateTaken)
    }

    private var dosageText: String {
        if dose.dosageAmount > 0 {
            let amtStr = dose.dosageAmount.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(dose.dosageAmount))
                : String(format: "%.1f", dose.dosageAmount)
            return "\(amtStr) \(dose.dosageUnit)"
        }
        return dose.dosageUnit
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 48, height: 48)
                Image(systemName: "pills.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.purple)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(dose.medicationName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    Text(formattedTime)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }

                Text(dosageText)
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)

                if let notes = dose.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
        }
        .padding(16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dose.medicationName), \(dosageText), taken at \(formattedTime)")
    }
}

// MARK: - ViewModel

@MainActor
class MedicationCalendarViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var doses: [MedicationDoseLog] = []
    @Published var isLoading = false

    private let doseRepo: MedicationDoseRepository

    init(doseRepo: MedicationDoseRepository = .shared) {
        self.doseRepo = doseRepo
    }

    func loadDoses() async {
        guard let userId = AuthenticationManager.shared.currentUserId else {
            doses = []; return
        }
        isLoading = true
        do {
            let loaded = try await doseRepo.fetchDosesForDate(selectedDate, userId: userId)
            doses = loaded.sorted { $0.dateTaken < $1.dateTaken }
        } catch {
            print("❌ MedicationCalendarView: Error loading doses: \(error)")
            doses = []
        }
        isLoading = false
    }

    func deleteDose(_ doseId: String) async {
        do {
            try await doseRepo.delete(id: doseId)
            doses.removeAll { $0.id == doseId }
            DataSyncManager.shared.triggerRefreshAfterSave(operation: "Dose delete", dataType: .dashboard)
            AccessibilityAnnouncement.announce("Dose deleted")
        } catch {
            print("❌ MedicationCalendarView: Error deleting dose: \(error)")
            AccessibilityAnnouncement.announce("Failed to delete dose")
        }
    }
}

// MARK: - Preview
#Preview {
    MedicationCalendarView()
        .environmentObject(AuthService())
        .environmentObject(AppRouter.shared)
        .environmentObject(RefreshManager.shared)
}
