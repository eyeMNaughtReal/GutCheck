//
//  CalendarView.swift
//  GutCheck
//
//  Created by Mark Conley on 7/12/25.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var authService: AuthService 
    let selectedDate: Date
    private let calendar = Calendar.current
    private let daysInWeek = 7

    private var weekDates: [Date] {
        let centerIndex = daysInWeek / 2
        return (0..<daysInWeek).compactMap { offset in
            calendar.date(byAdding: .day, value: offset - centerIndex, to: selectedDate)
        }
    }

    @State private var showProfileSheet = false
    var body: some View {
    VStack(spacing: 0) {
            // Month label
            ZStack {
                Text(monthYearString(for: selectedDate))
                    .font(.headline)
                    .bold()
                    .foregroundColor(ColorTheme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.horizontal)
            .padding(.top, 24)
            .padding(.bottom,30)

            // Weekday row
            HStack(spacing: 0) {
                ForEach(weekDates, id: \.self) { date in
                    VStack(spacing: 6) {
                        Text(shortWeekdayString(for: date))
                            .font(.caption)
                            .foregroundColor(ColorTheme.secondaryText)
                        Text(dayString(for: date))
                            .font(.headline)
                            .foregroundColor(date.isSameDay(as: selectedDate) ? .white : ColorTheme.primaryText)
                            .frame(width: 36, height: 36)
                            .background(
                                date.isSameDay(as: selectedDate) ? ColorTheme.accent : Color.clear
                            )
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 32)

            // Daily Meals row (placeholder)
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Meals")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                RoundedRectangle(cornerRadius: 12)
                    .fill(ColorTheme.cardBackground)
                    .frame(height: 60)
                    .overlay(
                        Text("No meals logged for this day.")
                            .foregroundColor(ColorTheme.secondaryText)
                    )
            }
            .padding(.horizontal)
            .padding(.bottom, 16)

            // Daily Symptoms row (placeholder)
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Symptoms")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                RoundedRectangle(cornerRadius: 12)
                    .fill(ColorTheme.cardBackground)
                    .frame(height: 60)
                    .overlay(
                        Text("No symptoms logged for this day.")
                            .foregroundColor(ColorTheme.secondaryText)
                    )
            }
            .padding(.horizontal)
            .padding(.bottom, 16)

            Spacer()
        }
        .background(ColorTheme.background.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ProfileAvatarButton {
                    showProfileSheet = true
                }
            }
        }
        .sheet(isPresented: $showProfileSheet) {
            if let currentUser = authService.currentUser {
                UserProfileView(user: currentUser)
            }
        }
    }

    private func shortWeekdayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    private func weekdayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private func dayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    CalendarView(selectedDate: Date())
}
