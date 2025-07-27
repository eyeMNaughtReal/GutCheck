import SwiftUI

struct UnifiedCalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    
    private let calendar = Calendar.current
    private let daysInWeek = 7
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Month Header
                monthHeader
                
                // Week Day Headers
                weekDayHeader
                
                // Calendar Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: daysInWeek), spacing: 0) {
                    ForEach(viewModel.calendarDays) { day in
                        DayCell(
                            day: day,
                            isSelected: calendar.isDate(day.date, inSameDayAs: selectedDate)
                        )
                        .onTapGesture {
                            selectedDate = day.date
                        }
                    }
                }
                .padding(.horizontal)
                
                // Daily Summary
                if let selectedDay = viewModel.calendarDays.first(where: { calendar.isDate($0.date, inSameDayAs: selectedDate) }) {
                    NavigationLink(destination: CalendarDetailView(date: selectedDate)) {
                        DailySummaryCard(day: selectedDay)
                            .padding()
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingDatePicker = true }) {
                        Image(systemName: "calendar")
                    }
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerView(selectedDate: $selectedDate, isPresented: $showingDatePicker)
            }
            .task {
                await viewModel.loadCalendarData(for: selectedDate)
            }
        }
    }
    
    private var monthHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(selectedDate.formatted(.dateTime.month(.wide)))
                    .font(.title2)
                    .bold()
                Text(selectedDate.formatted(.dateTime.year()))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: { selectPreviousMonth() }) {
                    Image(systemName: "chevron.left")
                }
                
                Button(action: { selectNextMonth() }) {
                    Image(systemName: "chevron.right")
                }
            }
        }
        .padding()
    }
    
    private var weekDayHeader: some View {
        HStack {
            ForEach(calendar.veryShortWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private func selectPreviousMonth() {
        withAnimation {
            selectedDate = calendar.date(byAdding: .month, value: -1, to: selectedDate) ?? selectedDate
        }
        Task {
            await viewModel.loadCalendarData(for: selectedDate)
        }
    }
    
    private func selectNextMonth() {
        withAnimation {
            selectedDate = calendar.date(byAdding: .month, value: 1, to: selectedDate) ?? selectedDate
        }
        Task {
            await viewModel.loadCalendarData(for: selectedDate)
        }
    }
}

// MARK: - Supporting Views

private struct DayCell: View {
    let day: CalendarDay
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(Calendar.current.component(.day, from: day.date))")
                .font(.system(.body, design: .rounded))
                .foregroundColor(isSelected ? .white : day.isCurrentMonth ? .primary : .secondary)
            
            if day.hasMeals || day.hasSymptoms {
                HStack(spacing: 4) {
                    if day.hasMeals {
                        Circle()
                            .fill(ColorTheme.mealLogging)
                            .frame(width: 6, height: 6)
                    }
                    if day.hasSymptoms {
                        Circle()
                            .fill(ColorTheme.bowelTracking)
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .frame(height: 50)
        .background(
            Circle()
                .fill(isSelected ? ColorTheme.primary : Color.clear)
                .frame(width: 35, height: 35)
        )
    }
}

private struct DailySummaryCard: View {
    let day: CalendarDay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(day.date.formatted(.dateTime.month().day().weekday()))
                .font(.headline)
            
            if day.hasMeals {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Meals", systemImage: "fork.knife")
                        .foregroundColor(ColorTheme.mealLogging)
                    ForEach(day.meals) { meal in
                        Text(meal.name)
                            .font(.subheadline)
                    }
                }
            }
            
            if day.hasSymptoms {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Symptoms", systemImage: "waveform.path.ecg")
                        .foregroundColor(ColorTheme.bowelTracking)
                    ForEach(day.symptoms) { symptom in
                        Text("Stool: \(symptom.stoolType.rawValue), Pain: \(symptom.painLevel.rawValue)")
                            .font(.subheadline)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .roundedCard()
    }
}

private struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .navigationTitle("Choose Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

#Preview {
    UnifiedCalendarView()
}
