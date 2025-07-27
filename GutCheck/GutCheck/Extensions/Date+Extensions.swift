import Foundation

extension Date {
    // Date formatting moved to DateFormattingService
    // Use the computed properties: formattedDate, formattedTime, formattedDateTime
    // Example: date.formattedDate instead of date.formattedDate()
    
    func isSameDay(as date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
    
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }
    
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
}
