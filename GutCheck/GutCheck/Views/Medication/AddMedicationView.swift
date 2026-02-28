//
//  AddMedicationView.swift
//  GutCheck
//
//  Form for adding a new medication to the user's catalog.
//

import SwiftUI

struct AddMedicationView: View {
    @StateObject private var viewModel = AddMedicationViewModel()
    @Environment(\.dismiss) private var dismiss
    var onSave: (() -> Void)?

    init(onSave: (() -> Void)? = nil) { self.onSave = onSave }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Medication Name")) {
                    TextField("e.g. Omeprazole, Metronidazole", text: $viewModel.name)
                        .autocorrectionDisabled()
                        .accessibilityLabel("Medication name")
                }

                Section(header: Text("Dosage")) {
                    HStack {
                        TextField("Amount", text: $viewModel.dosageAmount)
                            .keyboardType(.decimalPad)
                            .frame(minWidth: 60)
                            .accessibilityLabel("Dosage amount")
                        Divider()
                        Picker("Unit", selection: $viewModel.dosageUnit) {
                            ForEach(["mg", "mcg", "g", "ml", "IU", "tablet", "capsule", "drop", "patch"], id: \.self) {
                                Text($0).tag($0)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    Picker("Frequency", selection: $viewModel.frequency) {
                        ForEach(MedicationFrequency.allCases, id: \.self) {
                            Text($0.displayName).tag($0)
                        }
                    }
                }

                Section(header: Text("Dates")) {
                    DatePicker("Start Date", selection: $viewModel.startDate, displayedComponents: .date)
                    Toggle("Set End Date", isOn: $viewModel.hasEndDate)
                    if viewModel.hasEndDate {
                        DatePicker("End Date",
                                   selection: $viewModel.endDate,
                                   in: viewModel.startDate...,
                                   displayedComponents: .date)
                    }
                }

                Section {
                    Toggle(isOn: $viewModel.isActive) {
                        Label("Currently Taking", systemImage: "checkmark.seal")
                    }
                } footer: {
                    Text("Uncheck if this is a past medication.")
                }

                Section(header: Text("Notes (Optional)")) {
                    ZStack(alignment: .topLeading) {
                        if viewModel.notes.isEmpty {
                            Text("e.g. Take with food, prescribed by Dr. Smith…")
                                .foregroundStyle(.secondary)
                                .font(.body)
                                .padding(.top, 8).padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $viewModel.notes).frame(minHeight: 80)
                    }
                }
            }
            .navigationTitle("Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading)  { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Group {
                        if viewModel.isSaving { ProgressView() }
                        else {
                            Button("Save") { viewModel.saveMedication() }
                                .fontWeight(.semibold)
                                .disabled(!viewModel.isFormValid)
                        }
                    }
                }
            }
            .alert("Medication Added", isPresented: $viewModel.showingSuccessAlert) {
                Button("Done") { onSave?(); dismiss() }
            } message: {
                Text("\(viewModel.name) has been saved to your medications.")
            }
            .alert("Error", isPresented: $viewModel.showingErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.loadingState.errorMessage ?? "An error occurred.")
            }
        }
    }
}
