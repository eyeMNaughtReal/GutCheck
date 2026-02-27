//
//  LocalStorageSettingsView.swift
//  GutCheck
//
//  View for managing local storage settings and sync status
//
//  Created by Mark Conley on 8/18/25.
//

import SwiftUI
import CoreData

struct LocalStorageSettingsView: View {
    @EnvironmentObject private var dataSyncService: DataSyncService
    @EnvironmentObject private var localStorage: CoreDataStorageService
    @EnvironmentObject private var coreDataStack: CoreDataStack
    
    @State private var showingSyncAlert = false
    @State private var showingClearDataAlert = false
    @State private var syncAlertMessage = ""
    
    var body: some View {
        List {
            Section("Local Storage Status") {
                HStack {
                    Image(systemName: "internaldrive")
                        .foregroundColor(.blue)
                    Text("Core Data Status")
                    Spacer()
                    Text("Active")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                HStack {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.green)
                    Text("Encryption")
                    Spacer()
                    Text("Enabled")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
            
            Section("Synchronization") {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundColor(.orange)
                    Text("Sync Status")
                    Spacer()
                    Text(dataSyncService.getSyncStatus().description)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                Button(action: {
                    Task {
                        await performSync()
                    }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Sync Now")
                    }
                }
                .disabled(dataSyncService.isSyncing)
                
                if dataSyncService.isSyncing {
                    HStack {
                        ProgressView(value: dataSyncService.syncProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                        Text("\(Int(dataSyncService.syncProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Data Management") {
                Button(action: {
                    showingClearDataAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Clear Local Data")
                            .foregroundColor(.red)
                    }
                }
                
                Button(action: {
                    Task {
                        await localStorage.cleanupOldData()
                    }
                }) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.orange)
                        Text("Clean Up Old Data")
                    }
                }
            }
            
            Section("Storage Information") {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Local Database Size")
                    Spacer()
                    Text("Calculating...")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.purple)
                    Text("Last Cleanup")
                    Spacer()
                    Text("Never")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Local Storage")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sync Result", isPresented: $showingSyncAlert) {
            Button("OK") { }
        } message: {
            Text(syncAlertMessage)
        }
        .alert("Clear Local Data", isPresented: $showingClearDataAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                Task {
                    await clearLocalData()
                }
            }
        } message: {
            Text("This will remove all locally stored data. Your data will still be available in the cloud, but you'll need to sync again to restore local access.")
        }
    }
    
    private func performSync() async {
        do {
            try await dataSyncService.performFullSync()
            syncAlertMessage = "Synchronization completed successfully!"
            showingSyncAlert = true
        } catch {
            syncAlertMessage = "Synchronization failed: \(error.localizedDescription)"
            showingSyncAlert = true
        }
    }
    
    private func clearLocalData() async {
        do {
            try await coreDataStack.performBackgroundTask { context in
                // Clear all entities
                try context.deleteAll(LocalMeal.self)
                try context.deleteAll(LocalSymptom.self)
                try context.deleteAll(LocalUser.self)
                try context.deleteAll(LocalReminderSettings.self)
                try context.deleteAll(LocalActivityEntry.self)
                try context.deleteAll(LocalDataDeletionRequest.self)
                
                try context.save()
            }
        } catch {
            print("Error clearing local data: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        LocalStorageSettingsView()
            .environmentObject(DataSyncService.shared)
            .environmentObject(CoreDataStorageService.shared)
            .environmentObject(CoreDataStack.shared)
    }
}
