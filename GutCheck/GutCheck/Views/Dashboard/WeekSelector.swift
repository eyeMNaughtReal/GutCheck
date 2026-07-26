import SwiftUI

struct WeekSelector: View {
    @Binding var selectedDate: Date
    var onDateSelected: ((Date) -> Void)? = nil
    private let calendar = Calendar.current
    private let daysInWeek = 7
    
    // Track the current week offset for navigation
    @State private var weekOffset: Int = 0

    private var weekDates: [Date] {
        // Center today (or the navigated day) in the week: 3 days before, center, 3 days after
        let baseDate = calendar.date(byAdding: .day, value: weekOffset * 7, to: Date.now) ?? Date.now
        let startDate = calendar.date(byAdding: .day, value: -3, to: baseDate) ?? baseDate
        return (0..<daysInWeek).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: startDate)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Navigation arrows for week browsing
            HStack {
                Button(action: { navigateToPreviousWeek() }) {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundStyle(ColorTheme.accent)
                }
                
                Spacer()
                
                // Week range display with Today button
                VStack(spacing: 4) {
                    Text(weekRangeText)
                        .font(.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                    
                    Button(action: { resetToCurrentWeek() }) {
                        Text("Today")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(ColorTheme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(ColorTheme.accent.opacity(0.1))
                            .clipShape(.rect(cornerRadius: 8))
                    }
                }
                
                Spacer()
                
                Button(action: { navigateToNextWeek() }) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundStyle(ColorTheme.accent)
                }
            }
            .padding(.horizontal)
            
            // Week day selector
            HStack(spacing: 4) {
                ForEach(weekDates, id: \.self) { date in
                    Button(action: {
                        selectedDate = date
                        onDateSelected?(date)
                    }) {
                        VStack {
                            Text(shortWeekdayString(for: date))
                                .font(.caption)
                                .foregroundStyle(ColorTheme.secondaryText)
                            Text(dayString(for: date))
                                .font(.headline)
                                .foregroundStyle(selectedDate.isSameDay(as: date) ? .white : ColorTheme.primaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            Group {
                                if selectedDate.isSameDay(as: date) {
                                    ColorTheme.accent
                                } else if date.isSameDay(as: Date.now) {
                                    ColorTheme.accent.opacity(0.3)
                                } else {
                                    ColorTheme.cardBackground
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(date.isSameDay(as: Date.now) ? ColorTheme.accent : Color.clear, lineWidth: 2)
                        )
                        .clipShape(.rect(cornerRadius: 10))
                        .shadow(color: selectedDate.isSameDay(as: date) ? ColorTheme.shadowColor : .clear, radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal)
            .onAppear {
                updateWeekOffsetForSelectedDate()
            }
            .onChange(of: selectedDate) {
                if selectedDate.isSameDay(as: Date.now) {
                    weekOffset = 0
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
            selectedDate = Date.now
            onDateSelected?(Date.now)
        }
    }
    
    /// Update week offset to show the week containing the selected date
    private func updateWeekOffsetForSelectedDate() {
        let today = calendar.startOfDay(for: Date.now)
        let selected = calendar.startOfDay(for: selectedDate)
        let daysDifference = calendar.dateComponents([.day], from: today, to: selected).day ?? 0
        // Convert day difference to week offset (rounds toward zero)
        weekOffset = daysDifference / 7
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


