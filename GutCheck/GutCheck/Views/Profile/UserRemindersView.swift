import SwiftUI
import UserNotifications

struct UserRemindersView: View {
    @AppStorage("mealReminderEnabled") private var mealReminderEnabled = false
    @AppStorage("mealReminderTime") private var mealReminderTime = Date()
    @AppStorage("symptomReminderEnabled") private var symptomReminderEnabled = false
    @AppStorage("symptomReminderTime") private var symptomReminderTime = Date()
    @AppStorage("remindMeLaterInterval") private var remindMeLaterInterval = 15
    @AppStorage("weeklyInsightEnabled") private var weeklyInsightEnabled = false
    @AppStorage("weeklyInsightTime") private var weeklyInsightTime = Date()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                ReminderSection(title: "Daily Reminders", color: ColorTheme.accent) {
                    Toggle("Daily Meal Reminder", isOn: $mealReminderEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: ColorTheme.accent))
                    
                    if mealReminderEnabled {
                        DatePicker("Time", selection: $mealReminderTime, displayedComponents: .hourAndMinute)
                            .accentColor(ColorTheme.accent)
                    }
                    
                    Toggle("Daily Symptom Reminder", isOn: $symptomReminderEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: ColorTheme.accent))
                    
                    if symptomReminderEnabled {
                        DatePicker("Time", selection: $symptomReminderTime, displayedComponents: .hourAndMinute)
                            .accentColor(ColorTheme.accent)
                    }
                    
                    HStack {
                        Text("Remind Me Later Interval")
                        Spacer()
                        Picker("Interval", selection: $remindMeLaterInterval) {
                            ForEach([5, 10, 15, 30, 60, 90, 120, 240, 300], id: \.self) { min in
                                Text("\(min) min").tag(min)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .accentColor(ColorTheme.secondaryText)
                    }
                }
                
                ReminderSection(title: "AI Insights", color: ColorTheme.secondary) {
                    Toggle("Weekly Insight Summary", isOn: $weeklyInsightEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: ColorTheme.secondary))
                    
                    if weeklyInsightEnabled {
                        DatePicker("Time", selection: $weeklyInsightTime, displayedComponents: .hourAndMinute)
                            .accentColor(ColorTheme.secondary)
                    }
                }
                
                Button(action: saveReminders) {
                    Text("Save Reminders")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(ColorTheme.background.ignoresSafeArea())
        .navigationTitle("Reminders")
    }

    private func saveReminders() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                scheduleNotifications()
            }
        }
    }
    
    private func scheduleNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        if mealReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Meal Reminder"
            content.body = "Don't forget to log your meals!"
            let trigger = calendarTrigger(for: mealReminderTime)
            let request = UNNotificationRequest(identifier: "mealReminder", content: content, trigger: trigger)
            center.add(request)
        }
        
        if symptomReminderEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Symptom Reminder"
            content.body = "Don't forget to log your symptoms!"
            let trigger = calendarTrigger(for: symptomReminderTime)
            let request = UNNotificationRequest(identifier: "symptomReminder", content: content, trigger: trigger)
            center.add(request)
        }
        
        if weeklyInsightEnabled {
            let content = UNMutableNotificationContent()
            content.title = "Weekly Insight"
            content.body = "Check your AI-powered weekly health insights!"
            let trigger = calendarTrigger(for: weeklyInsightTime, weekday: 2) // Monday
            let request = UNNotificationRequest(identifier: "weeklyInsight", content: content, trigger: trigger)
            center.add(request)
        }
    }
    
    private func calendarTrigger(for date: Date, weekday: Int? = nil) -> UNCalendarNotificationTrigger {
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.hour, .minute], from: date)
        if let weekday = weekday {
            dateComponents.weekday = weekday
        }
        return UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
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
