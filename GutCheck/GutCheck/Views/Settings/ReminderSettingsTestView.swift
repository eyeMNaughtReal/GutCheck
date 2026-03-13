//
//  ReminderSettingsTestView.swift
//  GutCheck
//
//  Test view to verify reminder settings functionality
//

import SwiftUI

struct ReminderSettingsTestView: View {
    @StateObject private var reminderService = ReminderSettingsService.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Reminder Settings Test")
                    .font(.title)
                    .padding()
                
                if reminderService.isLoading {
                    ProgressView("Loading settings...")
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        if let settings = reminderService.reminderSettings {
                            Text("Settings loaded successfully!")
                                .foregroundStyle(.green)
                                .font(.headline)
                            
                            Group {
                                Text("Breakfast Reminder: \(settings.breakfastReminderEnabled ? "Enabled" : "Disabled")")
                                Text("Lunch Reminder: \(settings.lunchReminderEnabled ? "Enabled" : "Disabled")")
                                Text("Dinner Reminder: \(settings.dinnerReminderEnabled ? "Enabled" : "Disabled")")
                                Text("Symptom Reminder: \(settings.symptomReminderEnabled ? "Enabled" : "Disabled")")
                                Text("Weekly Insights: \(settings.weeklyInsightEnabled ? "Enabled" : "Disabled")")
                                Text("Remind Later Interval: \(settings.remindMeLaterInterval) minutes")
                                Text("Last Updated: \(settings.lastUpdated.formatted())")
                            }
                            .font(.body)
                            .padding(.horizontal)
                        } else {
                            Text("No settings loaded")
                                .foregroundStyle(.orange)
                        }
                        
                        if let error = reminderService.errorMessage {
                            Text("Error: \(error)")
                                .foregroundStyle(.red)
                                .padding()
                        }
                    }
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    Button("Load Settings") {
                        Task {
                            await reminderService.loadReminderSettings()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Create Test Settings") {
                        Task {
                            let testSettings = ReminderSettings(
                                breakfastReminderEnabled: true,
                                lunchReminderEnabled: true,
                                dinnerReminderEnabled: true,
                                symptomReminderEnabled: true,
                                remindMeLaterInterval: 30,
                                weeklyInsightEnabled: true
                            )
                            await reminderService.saveReminderSettings(testSettings)
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    NavigationLink("Open Full Reminders View") {
                        UserRemindersView()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Test View")
            .task {
                await reminderService.loadReminderSettings()
            }
        }
    }
}

#Preview {
    ReminderSettingsTestView()
}