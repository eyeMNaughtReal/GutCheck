import SwiftUI

struct WeekSelector: View {
    @Binding var selectedDate: Date
    var onDateSelected: ((Date) -> Void)? = nil
    private let calendar = Calendar.current
    private let daysInWeek = 7
    
    // Track the current week offset for navigation
    @State private var weekOffset: Int = 0

    private var weekDates: [Date] {
        // Show the 7 days with the selected week in focus
        let baseDate = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: Date()) ?? Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: baseDate)?.start ?? baseDate
        return (0..<daysInWeek).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startOfWeek)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Navigation arrows for week browsing
            HStack {
                Button(action: { navigateToPreviousWeek() }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(ColorTheme.accent)
                }
                
                Spacer()
                
                // Week range display with Today button
                VStack(spacing: 4) {
                    Text(weekRangeText)
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                    
                    Button(action: { resetToCurrentWeek() }) {
                        Text("Today")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(ColorTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(ColorTheme.accent.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                Button(action: { navigateToNextWeek() }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(ColorTheme.accent)
                }
            }
            .padding(.horizontal)
            
            // Week day selector
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(weekDates, id: \.self) { date in
                            Button(action: {
                                selectedDate = date
                                onDateSelected?(date)
                            }) {
                                VStack {
                                    Text(shortWeekdayString(for: date))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(dayString(for: date))
                                        .font(.headline)
                                        .foregroundColor(selectedDate.isSameDay(as: date) ? .white : .primary)
                                }
                                .frame(width: 44, height: 60)
                                .background(
                                    Group {
                                        if selectedDate.isSameDay(as: date) {
                                            ColorTheme.accent
                                        } else if date.isSameDay(as: Date()) {
                                            ColorTheme.accent.opacity(0.3)
                                        } else {
                                            ColorTheme.cardBackground
                                        }
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(date.isSameDay(as: Date()) ? ColorTheme.accent : Color.clear, lineWidth: 2)
                                )
                                .cornerRadius(10)
                                .shadow(color: selectedDate.isSameDay(as: date) ? ColorTheme.shadowColor : .clear, radius: 4, x: 0, y: 2)
                            }
                            .id(date)
                        }
                    }
                }
                .padding(.horizontal)
                .onAppear {
                    // Calculate week offset based on selected date
                    updateWeekOffsetForSelectedDate()
                    
                    // Scroll to selected date on appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let targetDate = weekDates.first(where: { $0.isSameDay(as: selectedDate) }) {
                            proxy.scrollTo(targetDate, anchor: .center)
                        }
                    }
                }
                .onChange(of: selectedDate) {
                    // If selectedDate is today, center it and reset week offset
                    if selectedDate.isSameDay(as: Date()) {
                        weekOffset = 0
                        if let today = weekDates.first(where: { $0.isSameDay(as: Date()) }) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                proxy.scrollTo(today, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }

    private func shortWeekdayString(for date: Date) -> String {
        DateFormattingService.string(from: date, format: .shortWeekday)
    }

    private func dayString(for date: Date) -> String {
        DateFormattingService.string(from: date, format: .dayOnly)
    }
    
    // MARK: - Navigation Methods
    
    private func navigateToPreviousWeek() {
        withAnimation(.easeInOut(duration: 0.3)) {
            weekOffset -= 1
            // Update selected date to the same day of the week in the new week
            if let newDate = calendar.date(byAdding: .weekOfYear, value: -1, to: selectedDate) {
                selectedDate = newDate
                onDateSelected?(newDate)
            }
        }
    }
    
    private func navigateToNextWeek() {
        withAnimation(.easeInOut(duration: 0.3)) {
            weekOffset += 1
            // Update selected date to the same day of the week in the new week
            if let newDate = calendar.date(byAdding: .weekOfYear, value: 1, to: selectedDate) {
                selectedDate = newDate
                onDateSelected?(newDate)
            }
        }
    }
    
    /// Reset week offset when navigating back to current week
    private func resetToCurrentWeek() {
        withAnimation(.easeInOut(duration: 0.3)) {
            weekOffset = 0
            // Update selected date to today
            selectedDate = Date()
            onDateSelected?(Date())
        }
    }
    
    /// Update week offset to show the week containing the selected date
    private func updateWeekOffsetForSelectedDate() {
        let today = Date()
        let selectedWeek = calendar.dateInterval(of: .weekOfYear, for: selectedDate)?.start ?? selectedDate
        let todayWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        if let weeksDifference = calendar.dateComponents([.weekOfYear], from: todayWeek, to: selectedWeek).weekOfYear {
            weekOffset = weeksDifference
        }
    }
    
    // MARK: - Computed Properties
    
    private var weekRangeText: String {
        guard let firstDate = weekDates.first,
              let lastDate = weekDates.last else {
            return "This Week"
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        if calendar.isDate(firstDate, equalTo: lastDate, toGranularity: .month) {
            // Same month
            return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
        } else {
            // Different months
            return "\(formatter.string(from: firstDate)) - \(formatter.string(from: lastDate))"
        }
    }
}


