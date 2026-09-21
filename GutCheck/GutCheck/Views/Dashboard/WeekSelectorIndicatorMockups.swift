//
//  WeekSelectorIndicatorMockups.swift
//  GutCheck
//
//  THROWAWAY MOCKUP — not wired into the app, not intended to ship.
//  Exists so per-day logging indicators can be compared side by side before
//  one is chosen. Delete this file once a direction is picked.
//
//  The problem being solved: on the dashboard week strip, show at a glance
//  which days have a meal / medication / symptom logged, so a day that was
//  missed is obvious when scanning back.
//
//  The constraint that shapes every option: a single day can carry all three
//  categories at once, so "a circle around the date" can only encode one of
//  them. Each variant below answers that differently.
//
//  Also note the existing cell already spends a ring on selection (an accent
//  capsule stroke) and a white circle behind the number, so any indicator has
//  to coexist with those rather than compete.
//

import SwiftUI

// MARK: - Mock data

/// What was logged on a given day.
private struct DayLog {
    let weekday: String
    let day: Int
    var meal = false
    var medication = false
    var symptom = false
    var isToday = false
    var isSelected = false

    var count: Int { [meal, medication, symptom].filter(\.self).count }
    var isComplete: Bool { meal && medication && symptom }
    var isEmpty: Bool { count == 0 }
}

/// A deliberately mixed week: a complete day, partial days, and two blanks —
/// the blanks are the whole point of the feature.
private let sampleWeek: [DayLog] = [
    DayLog(weekday: "Fri", day: 18, meal: true, medication: true, symptom: true),
    DayLog(weekday: "Sat", day: 19, meal: true, medication: true),
    DayLog(weekday: "Sun", day: 20),
    DayLog(weekday: "Mon", day: 21, meal: true, symptom: true),
    DayLog(weekday: "Tue", day: 22, meal: true, medication: true, symptom: true, isToday: true, isSelected: true),
    DayLog(weekday: "Wed", day: 23, medication: true),
    DayLog(weekday: "Thu", day: 24)
]

private enum MockPalette {
    static let meal = Color.blue
    static let medication = Color.orange
    static let symptom = Color.green
    static let accent = Color(red: 0.95, green: 0.45, blue: 0.10)
    static let card = Color(white: 0.96)
    static let secondary = Color.secondary
}

// MARK: - A. Dots beneath the number

private struct VariantDots: View {
    let day: DayLog

    var body: some View {
        DayCell(day: day) {
            HStack(spacing: 3) {
                if day.meal { Circle().fill(MockPalette.meal).frame(width: 5, height: 5) }
                if day.medication { Circle().fill(MockPalette.medication).frame(width: 5, height: 5) }
                if day.symptom { Circle().fill(MockPalette.symptom).frame(width: 5, height: 5) }
            }
            .frame(height: 5)
        }
    }
}

// MARK: - B. Segmented ring around the number

private struct VariantSegmentedRing: View {
    let day: DayLog

    private var segments: [Color] {
        var colors: [Color] = []
        if day.meal { colors.append(MockPalette.meal) }
        if day.medication { colors.append(MockPalette.medication) }
        if day.symptom { colors.append(MockPalette.symptom) }
        return colors
    }

    var body: some View {
        DayCell(day: day, ringOverlay: {
            ZStack {
                ForEach(Array(segments.enumerated()), id: \.offset) { index, color in
                    Circle()
                        .trim(
                            from: Double(index) / Double(segments.count),
                            to: Double(index + 1) / Double(segments.count)
                        )
                        .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                }
            }
            .padding(-3)
        }) {
            EmptyView()
        }
    }
}

// MARK: - C. One ring, completeness only

private struct VariantCompleteness: View {
    let day: DayLog

    private var ringColor: Color? {
        if day.isEmpty { return nil }
        return day.isComplete ? MockPalette.symptom : MockPalette.medication
    }

    var body: some View {
        DayCell(day: day, ringOverlay: {
            if let ringColor {
                Circle()
                    .stroke(ringColor, lineWidth: 2.5)
                    .padding(-3)
            }
        }) {
            EmptyView()
        }
    }
}

// MARK: - D. Segmented bar underneath

private struct VariantBar: View {
    let day: DayLog

    var body: some View {
        DayCell(day: day) {
            HStack(spacing: 2) {
                if day.meal { Capsule().fill(MockPalette.meal) }
                if day.medication { Capsule().fill(MockPalette.medication) }
                if day.symptom { Capsule().fill(MockPalette.symptom) }
            }
            .frame(width: 22, height: 3)
        }
    }
}

// MARK: - E. Glyphs instead of colour alone

private struct VariantGlyphs: View {
    let day: DayLog

    var body: some View {
        DayCell(day: day) {
            HStack(spacing: 2) {
                if day.meal {
                    Image(systemName: "fork.knife").foregroundStyle(MockPalette.meal)
                }
                if day.medication {
                    Image(systemName: "pills.fill").foregroundStyle(MockPalette.medication)
                }
                if day.symptom {
                    Image(systemName: "heart.fill").foregroundStyle(MockPalette.symptom)
                }
            }
            .font(.system(size: 7))
            .frame(height: 8)
        }
    }
}

// MARK: - Shared cell

/// Mirrors the real cell's geometry so the variants are judged in context:
/// 78pt capsule, weekday label, day number in a 34pt circle.
private struct DayCell<Indicator: View, Ring: View>: View {
    let day: DayLog
    @ViewBuilder var ringOverlay: () -> Ring
    @ViewBuilder var indicator: () -> Indicator

    init(
        day: DayLog,
        @ViewBuilder ringOverlay: @escaping () -> Ring = { EmptyView() },
        @ViewBuilder indicator: @escaping () -> Indicator
    ) {
        self.day = day
        self.ringOverlay = ringOverlay
        self.indicator = indicator
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(day.weekday)
                .font(.caption)
                .foregroundStyle(day.isSelected ? MockPalette.accent : MockPalette.secondary)

            Text("\(day.day)")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 34, height: 34)
                .background { if day.isSelected { Circle().fill(.white) } }
                .overlay { ringOverlay() }

            indicator()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 78)
        .background {
            Capsule().fill(day.isSelected ? MockPalette.accent.opacity(0.22) : MockPalette.card)
        }
        .overlay {
            Capsule().strokeBorder(
                day.isSelected ? MockPalette.accent : .clear,
                lineWidth: 2
            )
        }
    }
}

// MARK: - Comparison sheet

private struct VariantRow<Cell: View>: View {
    let title: String
    let note: String
    @ViewBuilder var cell: (DayLog) -> Cell

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.subheadline.bold())
            Text(note).font(.caption2).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(Array(sampleWeek.enumerated()), id: \.offset) { _, day in
                    cell(day)
                }
            }
            .padding(.top, 2)
        }
    }
}

struct WeekSelectorIndicatorMockups: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Per-day logging indicators")
                        .font(.title3.bold())
                    Text("Sample week: Fri and Tue complete, Sat/Mon/Wed partial, Sun and Thu nothing logged. Tue is today and selected.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 10) {
                        LegendChip(color: MockPalette.meal, label: "Meal")
                        LegendChip(color: MockPalette.medication, label: "Medication")
                        LegendChip(color: MockPalette.symptom, label: "Symptom")
                    }
                    .padding(.top, 2)
                }

                VariantRow(
                    title: "A · Dots beneath the number",
                    note: "Shows exactly which categories. Reads left-to-right, never collides with the selection ring."
                ) { VariantDots(day: $0) }

                VariantRow(
                    title: "B · Segmented ring around the number",
                    note: "Compact and closest to your original idea. Segments shrink as categories are added."
                ) { VariantSegmentedRing(day: $0) }

                VariantRow(
                    title: "C · One ring, completeness only",
                    note: "Green = all three, amber = partial, none = nothing. Answers 'did I miss anything' but not 'what'."
                ) { VariantCompleteness(day: $0) }

                VariantRow(
                    title: "D · Segmented bar underneath",
                    note: "Like A but continuous; width encodes how much was logged."
                ) { VariantBar(day: $0) }

                VariantRow(
                    title: "E · Tiny glyphs instead of colour alone",
                    note: "Only option that survives colour-blindness and greyscale without a legend."
                ) { VariantGlyphs(day: $0) }
            }
            .padding(16)
        }
    }
}

private struct LegendChip: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

#Preview("Indicator variants") {
    WeekSelectorIndicatorMockups()
}
