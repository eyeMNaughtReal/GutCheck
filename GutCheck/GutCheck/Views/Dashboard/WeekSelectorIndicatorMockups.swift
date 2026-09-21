//
//  WeekSelectorIndicatorMockups.swift
//  GutCheck
//
//  THROWAWAY MOCKUP — not wired into the app, not intended to ship.
//  Delete once a direction is locked.
//
//  Iteration 2. Direction chosen: dots beneath the day number. These variants
//  explore the three questions the first pass raised:
//
//  1. Fixed slots or collapsed? Collapsed dots shift position, so a lone dot
//     tells you nothing without distinguishing its colour. Fixed slots mean
//     left/middle/right always mean meal/medication/symptom, which is the
//     cheap route to colour-blind safety — no 7pt glyphs needed.
//
//  2. Past vs future. A blank past day means "you missed it". A blank future
//     day means "hasn't happened". Rendering both as empty space turns half
//     the strip into noise, and the whole point of the feature is spotting
//     the gap.
//
//  3. Legibility on the selected day, where dots sit on an accent-tinted
//     capsule rather than the grey one.
//

import SwiftUI

// MARK: - Mock data

private enum DayPosition {
    case past
    case today
    case future
}

private struct DayLog {
    let weekday: String
    let day: Int
    let position: DayPosition
    var meal = false
    var medication = false
    var symptom = false
    var isSelected = false

    var count: Int { [meal, medication, symptom].filter(\.self).count }

    /// A past day with nothing logged. The case the feature exists to surface.
    var isMissed: Bool { position == .past && count == 0 }
}

/// Today is Tue 22. Sun 20 is the missed day; Wed/Thu are simply in the
/// future. Those two cases must not look the same.
private let week: [DayLog] = [
    DayLog(weekday: "Fri", day: 18, position: .past, meal: true, medication: true, symptom: true),
    DayLog(weekday: "Sat", day: 19, position: .past, meal: true, medication: true),
    DayLog(weekday: "Sun", day: 20, position: .past),
    DayLog(weekday: "Mon", day: 21, position: .past, meal: true, symptom: true),
    DayLog(weekday: "Tue", day: 22, position: .today, meal: true, medication: true, isSelected: true),
    DayLog(weekday: "Wed", day: 23, position: .future),
    DayLog(weekday: "Thu", day: 24, position: .future)
]

private enum P {
    static let meal = Color.blue
    static let medication = Color.orange
    static let symptom = Color.green
    static let accent = Color(red: 0.95, green: 0.45, blue: 0.10)
    static let card = Color(white: 0.96)
    static let track = Color(white: 0.80)
    static let missed = Color(white: 0.62)
}

// MARK: - A1 · Collapsed dots (iteration 1 baseline)

private struct A1: View {
    let day: DayLog
    var body: some View {
        Cell(day: day) {
            HStack(spacing: 3) {
                if day.meal { dot(P.meal) }
                if day.medication { dot(P.medication) }
                if day.symptom { dot(P.symptom) }
            }
            .frame(height: 6)
        }
    }
    private func dot(_ c: Color) -> some View { Circle().fill(c).frame(width: 6, height: 6) }
}

// MARK: - A2 · Fixed slots, empties invisible

private struct A2: View {
    let day: DayLog
    var body: some View {
        Cell(day: day) {
            HStack(spacing: 3) {
                slot(day.meal, P.meal)
                slot(day.medication, P.medication)
                slot(day.symptom, P.symptom)
            }
            .frame(height: 6)
        }
    }
    private func slot(_ on: Bool, _ c: Color) -> some View {
        Circle().fill(on ? c : .clear).frame(width: 6, height: 6)
    }
}

// MARK: - A3 · Fixed slots with a visible empty track

private struct A3: View {
    let day: DayLog
    var body: some View {
        Cell(day: day) {
            HStack(spacing: 3) {
                slot(day.meal, P.meal)
                slot(day.medication, P.medication)
                slot(day.symptom, P.symptom)
            }
            .frame(height: 6)
        }
    }
    private func slot(_ on: Bool, _ c: Color) -> some View {
        Circle()
            .fill(on ? c : P.track.opacity(0.45))
            .frame(width: 6, height: 6)
    }
}

// MARK: - A4 · Track on past days only

private struct A4: View {
    let day: DayLog
    var body: some View {
        Cell(day: day) {
            HStack(spacing: 3) {
                slot(day.meal, P.meal)
                slot(day.medication, P.medication)
                slot(day.symptom, P.symptom)
            }
            .frame(height: 6)
            // Future days carry no track at all — there is nothing to have
            // missed yet, so an empty track there would be noise.
            .opacity(day.position == .future ? 0 : 1)
        }
    }
    private func slot(_ on: Bool, _ c: Color) -> some View {
        Circle()
            .fill(on ? c : P.track.opacity(0.45))
            .frame(width: 6, height: 6)
    }
}

// MARK: - A5 · A4 plus an explicit "missed" mark

private struct A5: View {
    let day: DayLog
    var body: some View {
        Cell(day: day) {
            Group {
                if day.isMissed {
                    // A past day with nothing at all reads as a dash rather
                    // than three empty slots — it states the gap instead of
                    // leaving the reader to notice an absence.
                    Text("—")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(P.missed)
                } else {
                    HStack(spacing: 3) {
                        slot(day.meal, P.meal)
                        slot(day.medication, P.medication)
                        slot(day.symptom, P.symptom)
                    }
                    .opacity(day.position == .future ? 0 : 1)
                }
            }
            .frame(height: 6)
        }
    }
    private func slot(_ on: Bool, _ c: Color) -> some View {
        Circle()
            .fill(on ? c : P.track.opacity(0.45))
            .frame(width: 6, height: 6)
    }
}

// MARK: - A6 · A4 at larger dots

private struct A6: View {
    let day: DayLog
    var body: some View {
        Cell(day: day) {
            HStack(spacing: 3.5) {
                slot(day.meal, P.meal)
                slot(day.medication, P.medication)
                slot(day.symptom, P.symptom)
            }
            .frame(height: 8)
            .opacity(day.position == .future ? 0 : 1)
        }
    }
    private func slot(_ on: Bool, _ c: Color) -> some View {
        Circle()
            .fill(on ? c : P.track.opacity(0.45))
            .frame(width: 8, height: 8)
    }
}

// MARK: - Shared cell

private struct Cell<Indicator: View>: View {
    let day: DayLog
    @ViewBuilder var indicator: () -> Indicator

    var body: some View {
        VStack(spacing: 5) {
            Text(day.weekday)
                .font(.caption)
                .foregroundStyle(day.isSelected ? P.accent : .secondary)

            Text("\(day.day)")
                .font(.headline)
                // Future days recede, so the eye lands on the days that
                // could actually have been logged.
                .foregroundStyle(day.position == .future ? .secondary : .primary)
                .frame(width: 34, height: 34)
                .background { if day.isSelected { Circle().fill(.white) } }

            indicator()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 78)
        .background {
            Capsule().fill(day.isSelected ? P.accent.opacity(0.22) : P.card)
        }
        .overlay {
            Capsule().strokeBorder(day.isSelected ? P.accent : .clear, lineWidth: 2)
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
            Text(title).font(.subheadline.bold())
            Text(note).font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
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
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Dots — iteration 2").font(.title3.bold())
                    Text("Today is Tue 22. Sun 20 is a MISSED day. Wed/Thu are future — they should not look missed.")
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 10) {
                        Chip(P.meal, "Meal"); Chip(P.medication, "Med"); Chip(P.symptom, "Symptom")
                    }
                }

                Row(title: "A1 · Collapsed (iteration 1)",
                    note: "Dots shift position. Wed's lone dot could be any category — colour is the only cue.") { A1(day: $0) }

                Row(title: "A2 · Fixed slots, empties invisible",
                    note: "Position now encodes category. But past-blank and future-blank still look identical.") { A2(day: $0) }

                Row(title: "A3 · Fixed slots + empty track",
                    note: "Gaps become visible. Downside: future days show three empty slots for nothing.") { A3(day: $0) }

                Row(title: "A4 · Track on past days only",
                    note: "Future days drop the track entirely and their numbers recede. Sun 20 now stands out.") { A4(day: $0) }

                Row(title: "A5 · A4 plus an explicit missed mark",
                    note: "A fully blank past day shows a dash — states the gap rather than relying on absence.") { A5(day: $0) }

                Row(title: "A6 · A4 at 8pt dots",
                    note: "Same logic as A4, larger dots. Check legibility on the tinted selected capsule.") { A6(day: $0) }
            }
            .padding(16)
        }
    }
}

private struct Chip: View {
    let c: Color
    let label: String
    init(_ c: Color, _ label: String) { self.c = c; self.label = label }
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(c).frame(width: 7, height: 7)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
    }
}

#Preview("Dots iteration") {
    WeekSelectorIndicatorMockups()
}
