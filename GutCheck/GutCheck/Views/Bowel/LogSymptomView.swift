//
//  LogSymptomView.swift
//  GutCheck
//
//  Enhanced UI with improved Bristol Scale, Pain Slider, and Info screens
//

import SwiftUI

struct LogSymptomView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showProfileSheet = false

    @State private var selectedDate = Date()
    @State private var selectedStoolType: Int? = nil
    @State private var selectedPainLevel: Double = 0
    @State private var selectedUrgency: Int? = nil
    @State private var selectedTags: Set<String> = []
    @State private var notes: String = ""
    @State private var showBristolInfo = false
    @State private var showPainInfo = false
    @State private var showUrgencyInfo = false

    // Example tags
    let allTags = ["After Meal", "Stress", "Exercise", "Travel", "New Food", "Medication"]
    let urgencyLevels = ["None", "Mild", "Moderate", "Severe", "Emergency"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Date & Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date & Time")
                            .font(.headline)
                        DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                            .labelsHidden()
                    }

                    // Bristol Stool Scale
                    bristolStoolSection

                    // Pain Level
                    painLevelSection

                    // Urgency Level
                    urgencyLevelSection

                    // Tag selection
                    tagSelectionSection

                    // Notes
                    notesSection

                    // Action buttons
                    actionButtonsSection
                }
                .padding()
            }
            .navigationTitle("Log Symptoms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileAvatarButton {
                        showProfileSheet = true
                    }
                }
            }
            .sheet(isPresented: $showProfileSheet) {
                if let currentUser = authService.currentUser {
                    UserProfileView(user: currentUser)
                }
            }
            // Info modals
            .sheet(isPresented: $showBristolInfo) {
                BristolStoolInfoView()
            }
            .sheet(isPresented: $showPainInfo) {
                PainLevelInfoView()
            }
            .sheet(isPresented: $showUrgencyInfo) {
                UrgencyLevelInfoView()
            }
        }
    }
    
    // MARK: - View Components
    
    private var bristolStoolSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Bristol Stool Scale")
                    .font(.headline)
                Button(action: { showBristolInfo = true }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(ColorTheme.primary)
                }
                Spacer()
            }
            // Show description if type is selected
            if let selectedType = selectedStoolType {
                Text(bristolDescription(for: selectedType))
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primaryText)
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            // Bristol scale selection (1-7)
            HStack(spacing: 8) {
                ForEach(1...7, id: \.self) { type in
                    Button(action: {
                        selectedStoolType = type
                    }) {
                        Text("\(type)")
                            .font(.headline)
                            .frame(width: 36, height: 36)
                            .background(selectedStoolType == type ? ColorTheme.primary : ColorTheme.surface)
                            .foregroundColor(selectedStoolType == type ? .white : ColorTheme.primaryText)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(ColorTheme.primary, lineWidth: selectedStoolType == type ? 2 : 1)
                            )
                    }
                    .accessibilityLabel("Bristol type \(type)")
                }
            }
        }
    }
    
    // MARK: - Section Stubs (replace with real implementations as needed)
    private var painLevelSection: some View {
        Text("[Pain Level Section]")
    }

    private var urgencyLevelSection: some View {
        Text("[Urgency Level Section]")
    }

    private var tagSelectionSection: some View {
        Text("[Tag Selection Section]")
    }

    private var notesSection: some View {
        Text("[Notes Section]")
    }

    private var actionButtonsSection: some View {
        Text("[Action Buttons Section]")
    }

    private func bristolDescription(for type: Int) -> String {
        // Stub implementation, replace with real description logic if needed
        "Description for Bristol type \(type)"
    }

    // MARK: - Actions
    private func saveSymptom() {
        print("Saving symptom...")
        print("Stool Type: \(selectedStoolType ?? 0)")
        print("Pain Level: \(Int(selectedPainLevel))")
        print("Urgency: \(selectedUrgency ?? 0)")
        print("Tags: \(selectedTags)")
        print("Notes: \(notes)")
    }

    private func cancelAction() {
        selectedStoolType = nil
        selectedPainLevel = 0
        selectedUrgency = nil
        selectedTags.removeAll()
        notes = ""
    }

    private func remindMeLaterAction() {
        print("Remind me later...")
    }
}
