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
        NavigationView {
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
                                .foregroundColor(.green)
                                .font(.headline)
                            
                            Group {
                                Text("Meal Reminder: \(settings.mealReminderEnabled ? "Enabled" : "Disabled")")
                                Text("Symptom Reminder: \(settings.symptomReminderEnabled ? "Enabled" : "Disabled")")
                                Text("Weekly Insights: \(settings.weeklyInsightEnabled ? "Enabled" : "Disabled")")
                                Text("Remind Later Interval: \(settings.remindMeLaterInterval) minutes")
                                Text("Last Updated: \(settings.lastUpdated.formatted())")
                            }
                            .font(.body)
                            .padding(.horizontal)
                        } else {
                            Text("No settings loaded")
                                .foregroundColor(.orange)
                        }
                        
                        if let error = reminderService.errorMessage {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
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
                                mealReminderEnabled: true,
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
            .onAppear {
                Task {
                    await reminderService.loadReminderSettings()
                }
            }
        }
    }
}

#if DEBUG
struct ReminderSettingsTestView_Previews: PreviewProvider {
    static var previews: some View {
        ReminderSettingsTestView()
    }
}
#endif