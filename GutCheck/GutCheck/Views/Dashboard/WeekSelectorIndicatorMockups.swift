//
//  WeekSelectorIndicatorMockups.swift
//  GutCheck
//
//  THROWAWAY MOCKUP — not wired into the app. Delete once locked.
//
//  Iteration 3. Locked so far: dots beneath the day number, fixed slots,
//  track on past days only, future days blank (variant A4).
//
//  This pass settles colour and the "today" rule.
//
//  Colour — reusing the category tokens the app already defines rather than
//  inventing a palette:
//
//      meal        ColorTheme.mealLogging     (= primary, teal)
//      medication  ColorTheme.secondary       (purple)
//      symptom     ColorTheme.symptomTracking (pink)
//
//  Two constraints drove that. Orange is the app accent — it is the selection
//  ring, the week arrows and the Today pill — so medication cannot be orange
//  or a logged dot reads as chrome. And green already means "no pain":
//  ColorTheme.severity(0) is `success`, and Insights prints "Symptom-free" in
//  green. A green dot meaning "a symptom was logged" would invert that.
//
//  Today — a filled dot when done, an open slot when not, because the day has
//  not ended. The two options below differ in what "open" looks like.
//

import SwiftUI

// MARK: - Mock data

private enum DayPosition { case past, today, future }

private struct DayLog {
    let weekday: String
    let day: Int
    let position: DayPosition
    var meal = false
    var medication = false
    var symptom = false
    var isSelected = false

    var count: Int { [meal, medication, symptom].filter(\.self).count }
}

/// Today is Tue 22, with a meal and a medication logged but no symptom — the
/// case that exercises the "open" state. Sun 20 is a missed past day.
/// Wed/Thu are future and must stay blank.
private let week: [DayLog] = [
    DayLog(weekday: "Fri", day: 18, position: .past, meal: true, medication: true, symptom: true),
    DayLog(weekday: "Sat", day: 19, position: .past, meal: true, medication: true),
    DayLog(weekday: "Sun", day: 20, position: .past),
    DayLog(weekday: "Mon", day: 21, position: .past, meal: true, symptom: true),
    DayLog(weekday: "Tue", day: 22, position: .today, meal: true, medication: true, isSelected: true),
    DayLog(weekday: "Wed", day: 23, position: .future),
    DayLog(weekday: "Thu", day: 24, position: .future)
]

private enum Category: CaseIterable {
    case meal, medication, symptom

    var color: Color {
        switch self {
        case .meal: ColorTheme.mealLogging
        case .medication: ColorTheme.secondary
        case .symptom: ColorTheme.symptomTracking
        }
    }

    func isLogged(in day: DayLog) -> Bool {
        switch self {
        case .meal: day.meal
        case .medication: day.medication
        case .symptom: day.symptom
        }
    }
}

// MARK: - F1 · Open = hollow ring

private struct F1: View {
    let day: DayLog
    private let size: CGFloat = 8

    var body: some View {
        Cell(day: day) {
            HStack(spacing: 3.5) {
                ForEach(Category.allCases, id: \.self) { category in
                    slot(category)
                }
            }
            .frame(height: size)
            .opacity(day.position == .future ? 0 : 1)
        }
    }

    @ViewBuilder
    private func slot(_ category: Category) -> some View {
        if category.isLogged(in: day) {
            Circle().fill(category.color).frame(width: size, height: size)
        } else if day.position == .today {
            // Still possible today, so the slot reads as open rather than spent.
            Circle()
                .strokeBorder(ColorTheme.secondaryText.opacity(0.55), lineWidth: 1.2)
                .frame(width: size, height: size)
        } else {
            Circle().fill(ColorTheme.secondaryText.opacity(0.28)).frame(width: size, height: size)
        }
    }
}

// MARK: - F2 · Open = faint category tint

private struct F2: View {
    let day: DayLog
    private let size: CGFloat = 8

    var body: some View {
        Cell(day: day) {
            HStack(spacing: 3.5) {
                ForEach(Category.allCases, id: \.self) { category in
                    slot(category)
                }
            }
            .frame(height: size)
            .opacity(day.position == .future ? 0 : 1)
        }
    }

    @ViewBuilder
    private func slot(_ category: Category) -> some View {
        if category.isLogged(in: day) {
            Circle().fill(category.color).frame(width: size, height: size)
        } else if day.position == .today {
            // Tinting the open slot says *which* category is still pending,
            // not merely that something is.
            Circle().fill(category.color.opacity(0.22)).frame(width: size, height: size)
        } else {
            Circle().fill(ColorTheme.secondaryText.opacity(0.28)).frame(width: size, height: size)
        }
    }
}


// MARK: - F3 · Open = hollow ring in the category colour

private struct F3: View {
    let day: DayLog
    private let size: CGFloat = 8

    var body: some View {
        Cell(day: day) {
            HStack(spacing: 3.5) {
                ForEach(Category.allCases, id: \.self) { category in
                    slot(category)
                }
            }
            .frame(height: size)
            .opacity(day.position == .future ? 0 : 1)
        }
    }

    @ViewBuilder
    private func slot(_ category: Category) -> some View {
        if category.isLogged(in: day) {
            Circle().fill(category.color).frame(width: size, height: size)
        } else if day.position == .today {
            // F1's robustness with F2's information: an outline survives dark
            // mode, and keeping the category hue says which one is pending.
            Circle()
                .strokeBorder(category.color, lineWidth: 1.5)
                .frame(width: size, height: size)
        } else {
            Circle().fill(ColorTheme.secondaryText.opacity(0.28)).frame(width: size, height: size)
        }
    }
}

// MARK: - Shared cell

private struct Cell<Indicator: View>: View {
    let day: DayLog
    @ViewBuilder var indicator: () -> Indicator

    var body: some View {
        VStack(spacing: 5) {
            Text(day.weekday)
                .typography(Typography.caption)
                .foregroundStyle(day.isSelected ? ColorTheme.accent : ColorTheme.secondaryText)

            Text("\(day.day)")
                .typography(Typography.headline)
                .foregroundStyle(
                    day.isSelected ? ColorTheme.onFixedLightSurface
                        : (day.position == .future ? ColorTheme.secondaryText : ColorTheme.primaryText)
                )
                .frame(width: 34, height: 34)
                .background { if day.isSelected { Circle().fill(.white) } }

            indicator()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 78)
        .background {
            Capsule().fill(day.isSelected ? ColorTheme.accent.opacity(0.22) : ColorTheme.cardBackground)
        }
        .overlay {
            Capsule().strokeBorder(day.isSelected ? ColorTheme.accent : .clear, lineWidth: 2)
        }
    }
}

// MARK: - Comparison

private struct Row<C: View>: View {
    let title: String
    let note: String
    @ViewBuilder var cell: (DayLog) -> C

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).typography(Typography.subheadline).fontWeight(.bold)
            Text(note)
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                ForEach(Array(week.enumerated()), id: \.offset) { _, d in cell(d) }
            }
            .padding(.top, 2)
        }
    }
}

struct WeekSelectorIndicatorMockups: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Dots — iteration 3: colour + today")
                        .typography(Typography.title3).fontWeight(.bold)
                        .foregroundStyle(ColorTheme.primaryText)
                    Text("Today is Tue 22 (meal + med logged, symptom still open). Sun 20 was missed. Wed/Thu are future.")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 12) {
                        Chip(ColorTheme.mealLogging, "Meal")
                        Chip(ColorTheme.secondary, "Medication")
                        Chip(ColorTheme.symptomTracking, "Symptom")
                    }
                }

                Row(title: "F1 · Open slot = hollow ring",
                    note: "Today's missing symptom is an outline. Clearly different from Sun 20's solid grey 'spent' slots.") { F1(day: $0) }

                Row(title: "F2 · Open slot = faint category tint",
                    note: "Same, but the open slot keeps its category colour at 22%, so it says *which* one is pending.") { F2(day: $0) }

                Row(title: "F3 · Open = hollow ring in the category colour",
                    note: "Synthesis: an outline survives dark mode, and the hue says which category is still pending.") { F3(day: $0) }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Reference")
                        .typography(Typography.subheadline).fontWeight(.bold)
                        .foregroundStyle(ColorTheme.primaryText)
                    Text("Teal / purple / pink are the app's existing category tokens. Orange is deliberately unused here — it is the accent, so an orange dot would read as chrome. Green is deliberately unused — severity(0) is green and means 'no pain', so green for 'symptom logged' would invert it.")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
        }
        .background(ColorTheme.background)
    }
}

private struct Chip: View {
    let c: Color
    let label: String
    init(_ c: Color, _ label: String) { self.c = c; self.label = label }
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(c).frame(width: 8, height: 8)
            Text(label).typography(Typography.caption).foregroundStyle(ColorTheme.secondaryText)
        }
    }
}

#Preview("Light") {
    WeekSelectorIndicatorMockups()
}

#Preview("Dark") {
    WeekSelectorIndicatorMockups().preferredColorScheme(.dark)
}
