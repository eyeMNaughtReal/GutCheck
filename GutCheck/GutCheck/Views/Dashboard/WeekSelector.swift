import SwiftUI

struct WeekSelector: View {
    @Binding var selectedDate: Date
    var onDateSelected: ((Date) -> Void)? = nil

    /// What was logged on each visible day, keyed by start of day.
    ///
    /// Supplied by the caller rather than fetched here. A view that queried on
    /// appearance would re-query on every selection change, and the strip
    /// re-renders often.
    var daySummaries: [Date: DayLogSummary] = [:]

    /// Reports which days are on screen, so the caller can fetch their
    /// summaries. The week window is computed here, so only this view knows
    /// which dates those are; duplicating the arithmetic in the store would be
    /// two places to keep in step.
    var onVisibleDatesChanged: (([Date]) -> Void)? = nil

    private let calendar = Calendar.current
    private let daysInWeek = 7

    /// Dot diameter and gap. From the approved mockup — 7pt was tried and read
    /// as dirt on the glass rather than as an indicator.
    private let dotSize: CGFloat = 8
    private let dotSpacing: CGFloat = 3.5
    
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
                        .typography(Typography.title2)
                        .foregroundStyle(ColorTheme.accent)
                }
                
                Spacer()
                
                // Week range display with Today button
                VStack(spacing: 4) {
                    Text(weekRangeText)
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                    
                    Button(action: { resetToCurrentWeek() }) {
                        Text("Today")
                            .typography(Typography.caption)
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
                        .typography(Typography.title2)
                        .foregroundStyle(ColorTheme.accent)
                }
            }
            .padding(.horizontal)
            
            // Week day selector — oblong capsules; the selected day is an accent-tinted
            // capsule with the date number sitting in a solid white circle.
            HStack(spacing: 6) {
                ForEach(weekDates, id: \.self) { date in
                    let isSelected = selectedDate.isSameDay(as: date)
                    let isToday = date.isSameDay(as: Date.now)

                    Button(action: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            selectedDate = date
                        }
                        onDateSelected?(date)
                    }) {
                        let position = DayPosition(for: date)

                        VStack(spacing: 6) {
                            Text(shortWeekdayString(for: date))
                                .typography(Typography.caption)
                                .foregroundStyle(isSelected ? ColorTheme.accent : ColorTheme.secondaryText)

                            Text(dayString(for: date))
                                .typography(Typography.headline)
                                .foregroundStyle(dayNumberColor(isSelected: isSelected, position: position))
                                .frame(width: 34, height: 34)
                                .background {
                                    if isSelected {
                                        Circle().fill(.white)
                                    }
                                }

                            indicatorRow(for: date, position: position)
                        }
                        .frame(maxWidth: .infinity)
                        // minHeight rather than a fixed height: the indicator row
                        // adds 8pt plus spacing, and a fixed 78 clipped it once
                        // Dynamic Type grew the day number.
                        .frame(minHeight: 86)
                        .background {
                            Capsule()
                                .fill(isSelected ? ColorTheme.accent.opacity(0.22) : ColorTheme.cardBackground)
                        }
                        .overlay {
                            // Selected gets a full accent ring; today keeps a quieter hint
                            // so it stays findable without competing with the selection.
                            Capsule()
                                .strokeBorder(
                                    isSelected ? ColorTheme.accent
                                        : (isToday ? ColorTheme.accent.opacity(0.45) : .clear),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityLabel(for: date, isToday: isToday))
                    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
                }
            }
            .padding(.horizontal)
            .onAppear {
                updateWeekOffsetForSelectedDate()
                onVisibleDatesChanged?(weekDates)
            }
            .onChange(of: selectedDate) {
                if selectedDate.isSameDay(as: Date.now) {
                    weekOffset = 0
                }
            }
            // Keyed on the offset, not on `selectedDate`: selecting another day
            // in the same week shows the same seven days, and refetching on
            // every tap is the "seven queries per render" problem.
            .onChange(of: weekOffset) {
                onVisibleDatesChanged?(weekDates)
            }
        }
    }

    // MARK: - Logging Indicators

    /// Three fixed dot slots beneath the day number: meal, medication, symptom.
    ///
    /// The slots are always present and always in that order, so position
    /// carries the meaning and colour only reinforces it. Collapsing to "one
    /// dot per thing logged" was tried and rejected: the dots then moved, and
    /// colour became the sole channel, which fails for anyone who cannot
    /// separate teal from pink.
    @ViewBuilder
    private func indicatorRow(for date: Date, position: DayPosition) -> some View {
        let summary = daySummaries[calendar.startOfDay(for: date)] ?? .none

        HStack(spacing: dotSpacing) {
            ForEach(Array(LogCategory.allCases.enumerated()), id: \.offset) { _, category in
                slot(for: category, summary: summary, position: position)
            }
        }
        .frame(height: dotSize)
        // Future days show nothing. They are not missed days, and drawing a
        // track on them made every future day look like a gap.
        .opacity(position == .future ? 0 : 1)
    }

    @ViewBuilder
    private func slot(for category: LogCategory, summary: DayLogSummary, position: DayPosition) -> some View {
        if category.isLogged(in: summary) {
            Circle()
                .fill(indicatorColor(for: category))
                .frame(width: dotSize, height: dotSize)
        } else if position == .today {
            // Today's unlogged slots are open, not spent — the day isn't over.
            // An outline rather than a faint fill: a 22% fill tested fine in
            // light mode and all but disappeared in dark against the capsule,
            // while an outline survives both and keeps the category hue, so it
            // still says which category is outstanding.
            Circle()
                .strokeBorder(indicatorColor(for: category), lineWidth: 1.5)
                .frame(width: dotSize, height: dotSize)
        } else {
            Circle()
                .fill(ColorTheme.secondaryText.opacity(0.28))
                .frame(width: dotSize, height: dotSize)
        }
    }

    /// Existing category tokens.
    ///
    /// Orange and green are deliberately absent. Orange is the accent — it is
    /// the selection ring, the week arrows and the Today pill, so an orange dot
    /// reads as chrome. Green is `severity(0)`, which Insights uses to print
    /// "Symptom-free", so a green dot meaning "a symptom was logged" would
    /// invert a meaning the app already established.
    private func indicatorColor(for category: LogCategory) -> Color {
        switch category {
        case .meal: ColorTheme.mealLogging
        case .medication: ColorTheme.secondary
        case .symptom: ColorTheme.symptomTracking
        }
    }

    /// Future day numbers recede, so the strip reads as "up to here".
    private func dayNumberColor(isSelected: Bool, position: DayPosition) -> Color {
        if isSelected { return ColorTheme.onFixedLightSurface }
        return position == .future ? ColorTheme.secondaryText : ColorTheme.primaryText
    }

    private func shortWeekdayString(for date: Date) -> String {
        DateFormattingService.string(from: date, format: .shortWeekday)
    }

    private func dayString(for date: Date) -> String {
        DateFormattingService.string(from: date, format: .dayOnly)
    }

    /// VoiceOver reads the full date, then what was logged and what is open.
    ///
    /// Not an enhancement to the dots — it is the same information, spoken.
    /// The dots are the only visual carrier, so without this a VoiceOver user
    /// cannot tell a complete day from a missed one at all.
    private func accessibilityLabel(for date: Date, isToday: Bool) -> String {
        let formatted = date.formatted(.dateTime.weekday(.wide).month(.wide).day())
        var label = isToday ? "Today, \(formatted)" : formatted

        // A future day has nothing to report, and saying "nothing logged"
        // about tomorrow would read as a warning rather than a fact.
        let position = DayPosition(for: date)
        guard position != .future else { return label }

        let summary = daySummaries[calendar.startOfDay(for: date)] ?? .none
        let logged = LogCategory.allCases.filter { $0.isLogged(in: summary) }.map(\.spokenName)
        let missing = LogCategory.allCases.filter { !$0.isLogged(in: summary) }.map(\.spokenName)

        if logged.isEmpty {
            label += isToday ? ". Nothing logged yet" : ". Nothing logged"
        } else {
            label += ". Logged: \(logged.formatted(.list(type: .and)))"

            if !missing.isEmpty {
                // Phrasing splits on position for the same reason the dots do:
                // today still has time left, a past day does not.
                label += isToday
                    ? ". Still to log: \(missing.formatted(.list(type: .and)))"
                    : ". Not logged: \(missing.formatted(.list(type: .and)))"
            }
        }

        return label
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


