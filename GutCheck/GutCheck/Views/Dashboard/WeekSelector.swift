import SwiftUI

struct WeekSelector: View {
    @Binding var selectedDate: Date
    var onDateSelected: ((Date) -> Void)? = nil
    private let calendar = Calendar.current
    private let daysInWeek = 7

    private var weekDates: [Date] {
        // Show the 7 days with today in the center (if possible)
        let today = Date()
        let centerIndex = daysInWeek / 2
        return (0..<daysInWeek).compactMap { offset in
            calendar.date(byAdding: .day, value: offset - centerIndex, to: today)
        }
    }

    var body: some View {
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
                .padding(.horizontal)
                .onAppear {
                    // Scroll to center today's date on appear
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let today = weekDates.first(where: { $0.isSameDay(as: Date()) }) {
                            proxy.scrollTo(today, anchor: .center)
                        }
                    }
                }
                .onChange(of: selectedDate) {
                    // If selectedDate is today, center it
                    if selectedDate.isSameDay(as: Date()), let today = weekDates.first(where: { $0.isSameDay(as: Date()) }) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            proxy.scrollTo(today, anchor: .center)
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
}


