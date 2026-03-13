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
            .background(ColorTheme.background)

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
                                    .fill(ColorTheme.cardBackground)
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
        .background(ColorTheme.background)
        .navigationTitle("Meds")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ProfileAvatarButton(user: authService.currentUser) {
                    router.showProfile()
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink(destination: MedicationListView()) {
                    Image(systemName: "list.bullet")
                        .accessibilityLabel("Manage medications")
                }
            }
        }
        .task {
            await viewModel.loadDoses()
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

            // Section title + Log Dose button on the same row
            HStack {
                Text("Medications")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(ColorTheme.primaryText)
                Spacer()
                Button {
                    HapticManager.shared.medium()
                    onLogDose()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.subheadline.weight(.semibold))
                        Text("Log Dose")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(minWidth: 148)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange, in: Capsule())
                    .foregroundStyle(.white)
                }
                .accessibleButton(label: "Log Dose", hint: "Tap to log a medication dose")
            }
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
                    .foregroundStyle(ColorTheme.primaryText)
                Spacer()
            }

            if doses.isEmpty {
                Text("Log a dose to see your daily medication summary.")
                    .font(.subheadline)
                    .foregroundStyle(ColorTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Dose count — prominent
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(doses.count)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(ColorTheme.primaryText)
                    Text("dose\(doses.count == 1 ? "" : "s") taken")
                        .font(.subheadline)
                        .foregroundStyle(ColorTheme.secondaryText)
                    Spacer()
                }

                // Medication name pills
                if !uniqueMedNames.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(uniqueMedNames, id: \.self) { name in
                                MedNamePill(name: name)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(ColorTheme.cardBackground)
                .shadow(color: ColorTheme.shadowColor, radius: 3, x: 0, y: 1)
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
                .font(.caption)
                .foregroundStyle(.purple)
            Text(name)
                .font(.caption)
                .foregroundStyle(ColorTheme.primaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.purple.opacity(0.12))
        .clipShape(.rect(cornerRadius: 8))
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
                : dose.dosageAmount.formatted(.number.precision(.fractionLength(1)))
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
                    .foregroundStyle(.purple)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(dose.medicationName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(ColorTheme.primaryText)
                    Spacer()
                    Text(formattedTime)
                        .font(.system(size: 15))
                        .foregroundStyle(ColorTheme.secondaryText)
                }

                Text(dosageText)
                    .font(.system(size: 15))
                    .foregroundStyle(ColorTheme.secondaryText)

                if let notes = dose.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 14))
                        .foregroundStyle(ColorTheme.secondaryText)
                        .lineLimit(2)
                }
            }

            // Checkmark
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(.green)
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
    @Published var selectedDate = Date.now
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
