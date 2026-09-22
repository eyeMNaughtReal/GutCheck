//
//  DayLogSummary.swift
//  GutCheck
//
//  What was logged on a single day, per category.
//
//  Presence only, deliberately — not counts. The dashboard week strip asks
//  "did anything get logged", and a count would invite a UI that distinguishes
//  one meal from three, which is not a distinction worth making when the point
//  is spotting a day that was missed entirely.
//

import Foundation

struct DayLogSummary: Equatable, Sendable {

    var hasMeal: Bool = false
    var hasMedication: Bool = false
    var hasSymptom: Bool = false

    /// Nothing logged at all. For a past day this is the gap worth surfacing.
    var isEmpty: Bool { !hasMeal && !hasMedication && !hasSymptom }

    /// Every category covered.
    var isComplete: Bool { hasMeal && hasMedication && hasSymptom }

    static let none = DayLogSummary()
}

// MARK: - Category

/// The three tracked categories, in the fixed order the indicator draws them.
///
/// Order is load-bearing. The week strip gives each category a permanent slot
/// so that position, not just colour, carries the meaning — which is what keeps
/// the indicator readable for someone who cannot separate teal from pink.
enum LogCategory: CaseIterable, Sendable {
    case meal
    case medication
    case symptom

    func isLogged(in summary: DayLogSummary) -> Bool {
        switch self {
        case .meal: summary.hasMeal
        case .medication: summary.hasMedication
        case .symptom: summary.hasSymptom
        }
    }

    /// Used in VoiceOver output, so it must read naturally in a list.
    var spokenName: String {
        switch self {
        case .meal: "meal"
        case .medication: "medication"
        case .symptom: "symptom"
        }
    }
}

// MARK: - Day Position

/// Where a day sits relative to today.
///
/// The indicator treats these differently on purpose: an unlogged day that has
/// not happened yet is not a gap, while an unlogged day in the past is. An
/// earlier design drew the same empty track on both, which made half the strip
/// look like missed days and hid the real ones.
enum DayPosition: Equatable, Sendable {
    case past
    case today
    case future

    init(for date: Date, now: Date = .now, calendar: Calendar = .current) {
        if calendar.isDate(date, inSameDayAs: now) {
            self = .today
        } else if date < now {
            self = .past
        } else {
            self = .future
        }
    }
}
