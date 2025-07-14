import SwiftUI

struct SymptomEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var editedSymptom: Symptom
    var onSave: (Symptom) -> Void

    init(symptom: Symptom, onSave: @escaping (Symptom) -> Void) {
        _editedSymptom = State(initialValue: symptom)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $editedSymptom.date, displayedComponents: [.date, .hourAndMinute])
                Picker("Stool Type", selection: $editedSymptom.stoolType) {
                    ForEach(StoolType.allCases, id: \ .self) { type in
                        Text("Type \(type.rawValue)").tag(type)
                    }
                }
                Picker("Pain Level", selection: $editedSymptom.painLevel) {
                    ForEach(PainLevel.allCases, id: \ .self) { level in
                        Text(String(describing: level).capitalized).tag(level)
                    }
                }
                Picker("Urgency Level", selection: $editedSymptom.urgencyLevel) {
                    ForEach(UrgencyLevel.allCases, id: \ .self) { level in
                        Text(String(describing: level).capitalized).tag(level)
                    }
                }
                Section(header: Text("Notes")) {
                    TextEditor(text: Binding(
                        get: { editedSymptom.notes ?? "" },
                        set: { editedSymptom.notes = $0.isEmpty ? nil : $0 }
                    ))
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle("Edit Symptom")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(editedSymptom)
                        dismiss()
                    }
                }
            }
        }
    }
}

// Preview with mock data
#Preview {
    SymptomEditView(symptom: Symptom(
        date: Date(),
        stoolType: .type4,
        painLevel: .moderate,
        urgencyLevel: .mild,
        notes: "Edit notes here",
        createdBy: "testUser"
    )) { _ in }
}
