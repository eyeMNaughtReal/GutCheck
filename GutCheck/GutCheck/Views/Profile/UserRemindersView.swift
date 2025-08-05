import SwiftUI
import UserNotifications

struct UserRemindersView: View {
    @StateObject private var reminderService = ReminderSettingsService.shared
    @State private var localSettings = ReminderSettings()
    @State private var showingSaveConfirmation = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ReminderSection(title: "Daily Reminders", color: ColorTheme.accent) {
                    Toggle("Daily Meal Reminder", isOn: $localSettings.mealReminderEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: ColorTheme.accent))
                    
                    if localSettings.mealReminderEnabled {
                        DatePicker("Time", selection: $localSettings.mealReminderTime, displayedComponents: .hourAndMinute)
                            .accentColor(ColorTheme.accent)
                    }
                    
                    Toggle("Daily Symptom Reminder", isOn: $localSettings.symptomReminderEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: ColorTheme.accent))
                    
                    if localSettings.symptomReminderEnabled {
                        DatePicker("Time", selection: $localSettings.symptomReminderTime, displayedComponents: .hourAndMinute)
                            .accentColor(ColorTheme.accent)
                    }
                    
                    HStack {
                        Text("Remind Me Later Interval")
                        Spacer()
                        Picker("Interval", selection: $localSettings.remindMeLaterInterval) {
                            ForEach([5, 10, 15, 30, 60, 90, 120, 240, 300], id: \.self) { min in
                                Text("\(min) min").tag(min)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .accentColor(ColorTheme.secondaryText)
                    }
                }
                
                ReminderSection(title: "AI Insights", color: ColorTheme.secondary) {
                    Toggle("Weekly Insight Summary", isOn: $localSettings.weeklyInsightEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: ColorTheme.secondary))
                    
                    if localSettings.weeklyInsightEnabled {
                        DatePicker("Time", selection: $localSettings.weeklyInsightTime, displayedComponents: .hourAndMinute)
                            .accentColor(ColorTheme.secondary)
                    }
                }
                
                Button(action: saveReminders) {
                    HStack(spacing: 8) {
                        if reminderService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.9)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                        }
                        
                        Text(reminderService.isLoading ? "Saving..." : "Save Reminders")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(reminderService.isLoading)
            }
            .padding()
        }
        .background(ColorTheme.background.ignoresSafeArea())
        .navigationTitle("Reminders")
        .onAppear {
            loadReminderSettings()
        }
        .alert("Reminders Saved", isPresented: $showingSaveConfirmation) {
            Button("OK") { }
        } message: {
            Text("Your reminder settings have been saved and notifications scheduled.")
        }
        .alert("Error", isPresented: .constant(reminderService.errorMessage != nil)) {
            Button("OK") { 
                reminderService.errorMessage = nil
            }
        } message: {
            if let errorMessage = reminderService.errorMessage {
                Text(errorMessage)
            }
        }
    }

    private func loadReminderSettings() {
        Task {
            await reminderService.loadReminderSettings()
            if let settings = reminderService.reminderSettings {
                localSettings = settings
            }
        }
    }

    private func saveReminders() {
        Task {
            await reminderService.saveReminderSettings(localSettings)
            if reminderService.errorMessage == nil {
                showingSaveConfirmation = true
            }
        }
    }
}

struct ReminderSection<Content: View>: View {
    let title: String
    let color: Color
    @ViewBuilder let content: () -> Content  // ✅ ViewBuilder added
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(color)
            VStack(spacing: 12) {
                content()
            }
            .padding()
            .background(ColorTheme.cardBackground)
            .cornerRadius(12)
            .shadow(color: ColorTheme.shadowColor.opacity(0.06), radius: 2, x: 0, y: 1)
        }
    }
}

#if DEBUG
struct UserRemindersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            UserRemindersView()
        }
    }
}
#endif
