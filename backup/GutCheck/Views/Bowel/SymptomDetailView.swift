//
//  SymptomDetailView.swift
//  GutCheck
//
//  Created by Mark Conley on 7/14/25.
//


//
//  SymptomDetailView.swift
//  GutCheck
//
//  Created on 7/14/25.
//

import SwiftUI

struct SymptomDetailView: View {
    let symptom: Symptom
    var onEdit: ((Symptom) -> Void)? = nil
    var onDelete: ((Symptom) -> Void)? = nil

    @State private var isEditing = false
    @State private var showDeleteAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Symptom Detail")
                    .font(.title)
                    .padding(.top)

                // Symptom information
                VStack(alignment: .leading, spacing: 16) {
                    // Date
                    HStack {
                        Text("Date:")
                            .font(.headline)
                        Spacer()
                        Text(formattedDate)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                    // Stool Type
                    HStack {
                        Text("Bristol Stool Type:")
                            .font(.headline)
                        Spacer()
                        Text("Type \(symptom.stoolType.rawValue)")
                            .font(.body)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                    // Pain Level
                    HStack {
                        Text("Pain Level:")
                            .font(.headline)
                        Spacer()
                        PainLevelIndicator(level: symptom.painLevel)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                    // Urgency Level
                    HStack {
                        Text("Urgency Level:")
                            .font(.headline)
                        Spacer()
                        UrgencyLevelIndicator(level: symptom.urgencyLevel)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                    // Notes
                    if let notes = symptom.notes, !notes.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Notes:")
                                .font(.headline)
                            Text(notes)
                                .font(.body)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        isEditing = true
                    }) {
                        Text("Edit")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(ColorTheme.border, lineWidth: 1)
                            )
                    }

                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Text("Delete")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ColorTheme.error)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Symptom Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Symptom?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete?(symptom)
            }
        } message: {
            Text("Are you sure you want to delete this symptom? This action cannot be undone.")
        }
        .sheet(isPresented: $isEditing) {
            SymptomEditView(symptom: symptom) { updatedSymptom in
                onEdit?(updatedSymptom)
                isEditing = false
            }
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: symptom.date)
    }
}

struct PainLevelIndicator: View {
    let level: PainLevel
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(index <= level.rawValue ? painColor : Color.gray.opacity(0.3))
                    .frame(width: 16, height: 16)
            }
        }
    }
    
    private var painColor: Color {
        switch level {
        case .none:
            return Color.green
        case .mild:
            return Color.yellow
        case .moderate:
            return Color.orange
        case .severe:
            return Color.red
        }
    }
}

struct UrgencyLevelIndicator: View {
    let level: UrgencyLevel
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                Circle()
                    .fill(index <= level.rawValue ? urgencyColor : Color.gray.opacity(0.3))
                    .frame(width: 16, height: 16)
            }
        }
    }
    
    private var urgencyColor: Color {
        switch level {
        case .none:
            return Color.green
        case .mild:
            return Color.yellow
        case .moderate:
            return Color.orange
        case .urgent:
            return Color.red
        }
    }
}

#Preview {
    NavigationStack {
        SymptomDetailView(symptom: Symptom(
            date: Date(),
            stoolType: .type4,
            painLevel: .moderate,
            urgencyLevel: .mild,
            notes: "Felt uncomfortable after lunch",
            createdBy: "testUser"
        ))
    }
}