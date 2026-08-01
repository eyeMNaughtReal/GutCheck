//
//  LocalStorageSettingsView.swift
//  GutCheck
//
//  View for inspecting the on-device store.
//
//  Created by Mark Conley on 8/18/25.
//

import SwiftUI
import SwiftData

struct LocalStorageSettingsView: View {
    @Environment(SwiftDataStack.self) private var stack

    @State private var showingClearDataAlert = false
    @State private var storeSize: String = "Calculating…"
    @State private var recordCounts: RecordCounts?

    private struct RecordCounts {
        var meals = 0
        var symptoms = 0
        var medications = 0
        var doses = 0
    }

    var body: some View {
        List {
            Section("Storage Status") {
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundStyle(.blue)
                    Text("SwiftData Store")
                    Spacer()
                    Text("Active")
                        .foregroundStyle(.green)
                        .typography(Typography.caption)
                }

                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundStyle(.green)
                    Text("Data Protection")
                    Spacer()
                    Text("Enabled")
                        .foregroundStyle(.green)
                        .typography(Typography.caption)
                }

                HStack {
                    Image(systemName: "iphone")
                        .foregroundStyle(.blue)
                    Text("Location")
                    Spacer()
                    Text("This device only")
                        .foregroundStyle(.secondary)
                        .typography(Typography.caption)
                }
            }

            if let counts = recordCounts {
                Section("Stored Records") {
                    LabeledContent("Meals", value: "\(counts.meals)")
                    LabeledContent("Symptoms", value: "\(counts.symptoms)")
                    LabeledContent("Medications", value: "\(counts.medications)")
                    LabeledContent("Doses", value: "\(counts.doses)")
                }
            }

            Section("Storage Information") {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text("Database Size")
                    Spacer()
                    Text(storeSize)
                        .foregroundStyle(.secondary)
                        .typography(Typography.caption)
                }
            }

            Section("Data Management") {
                Button(role: .destructive) {
                    showingClearDataAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Erase All Data")
                    }
                }
            }
        }
        .navigationTitle("Local Storage")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await refreshStats()
        }
        .alert("Erase All Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Erase", role: .destructive) {
                Task {
                    try? await LocalUserService.shared.deleteAllLocalData()
                    await refreshStats()
                }
            }
        } message: {
            // The old copy promised the data was still in the cloud. It isn't —
            // this is the only copy, so the warning has to say so.
            Text("This permanently removes every meal, symptom and medication "
                 + "recorded on this device. There is no cloud backup, so this "
                 + "cannot be undone. Export your data first if you want to keep it.")
        }
    }

    private func refreshStats() async {
        recordCounts = RecordCounts(
            meals: (try? stack.context.fetchCount(FetchDescriptor<StoredMeal>())) ?? 0,
            symptoms: (try? stack.context.fetchCount(FetchDescriptor<StoredSymptom>())) ?? 0,
            medications: (try? stack.context.fetchCount(FetchDescriptor<StoredMedication>())) ?? 0,
            doses: (try? stack.context.fetchCount(FetchDescriptor<StoredMedicationDose>())) ?? 0
        )
        storeSize = Self.formattedStoreSize()
    }

    /// Sums the store and its SQLite journal files — the write-ahead log can be
    /// a meaningful share of the total, so reporting the store alone understates it.
    private static func formattedStoreSize() -> String {
        let bytes = SwiftDataStack.storeFileURLs.reduce(into: Int64(0)) { total, url in
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
            total += (attributes?[.size] as? Int64) ?? 0
        }

        guard bytes > 0 else { return "Empty" }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

#Preview {
    NavigationStack {
        LocalStorageSettingsView()
            .environment(SwiftDataStack.shared)
    }
}
