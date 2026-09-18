//
//  InsightNarrationService.swift
//  GutCheck
//
//  Turns already-computed insight facts into natural prose using the on-device
//  Apple Foundation Model.
//
//  Design constraint — read before extending:
//
//  The model is a *writer*, never an *analyst*. Every number and every food name
//  it sees is computed deterministically by PatternRecognitionService before it
//  gets here, and the instructions forbid it from introducing any claim that
//  isn't in the facts it was handed. This matters because a 3B on-device model
//  will happily invent a plausible-sounding correlation, and to someone reading
//  the dashboard an invented trigger is indistinguishable from a measured one.
//
//  Consequences of that constraint, all deliberate:
//  - Severity/tone stays on the deterministic path. The model does not get to
//    decide whether something is a warning, because that drives UI styling.
//  - Every failure falls back to the caller's precomputed string. Narration is
//    a presentation upgrade, never a dependency.
//  - Output goes through @Generable so it can't come back malformed.
//

import Foundation
import FoundationModels

// MARK: - Input

/// The complete set of facts the narration is permitted to mention.
///
/// Anything not in here must not appear in the output. Keep this struct small:
/// everything in it costs context window, and the on-device model degrades as
/// the prompt grows.
struct InsightFacts: Sendable {
    /// Meals logged in the period being described.
    let mealCount: Int

    /// Symptoms logged in the period being described.
    let symptomCount: Int

    /// Highest pain level recorded, as a word ("mild", "moderate", "severe").
    ///
    /// Deliberately a label and not a number: `PainLevel` is a 0-3 enum, and
    /// handing the model a bare `2` invites it to render that as "2 out of 10".
    let peakPainDescription: String?

    /// Foods that deterministic analysis flagged, strongest correlation first.
    /// Empty when nothing crossed the confidence threshold.
    let flaggedFoods: [String]

    /// Typical hours between eating a flagged food and symptom onset, when known.
    let averageOnsetHours: Double?

    /// Renders the facts as short labelled lines.
    ///
    /// Labelled lines rather than prose on purpose — the model's job is to write
    /// the prose, so handing it prose invites it to copy the phrasing instead of
    /// producing something natural.
    var promptDescription: String {
        var lines = [
            "Meals logged: \(mealCount)",
            "Symptoms logged: \(symptomCount)"
        ]
        if let peakPainDescription {
            lines.append("Highest pain recorded: \(peakPainDescription)")
        }
        if !flaggedFoods.isEmpty {
            lines.append("Foods statistically associated with symptoms: \(flaggedFoods.joined(separator: ", "))")
        }
        if let averageOnsetHours {
            let hours = averageOnsetHours.formatted(.number.precision(.fractionLength(1)))
            lines.append("Typical hours from eating to symptom onset: \(hours)")
        }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Output

/// The shape the model must produce.
///
/// Guided generation via `@Generable` means the framework constrains sampling to
/// this structure, so there's no string parsing and no malformed-response path.
@Generable(description: "A short, plain-language summary of one person's gut health data")
struct NarratedInsight {
    @Guide(description: "One or two sentences describing only the data provided. Plain, calm, second person. No diagnosis, no medical advice, no numbers that were not provided.")
    var summary: String
}

// MARK: - Service

/// Narrates deterministic insight facts using the on-device system language model.
@MainActor
@Observable final class InsightNarrationService {

    static let shared = InsightNarrationService()

    private let model = SystemLanguageModel.default

    private init() {}

    /// Whether narration can run right now.
    ///
    /// Worth checking before showing any AI-related affordance in the UI: a
    /// device can be on a supported OS and still have no model, because the user
    /// hasn't enabled Apple Intelligence, the hardware isn't eligible, or the
    /// weights haven't finished downloading.
    var isAvailable: Bool { model.availability == .available }

    /// Why narration is unavailable, for surfacing in settings or diagnostics.
    var unavailableReason: SystemLanguageModel.Availability.UnavailableReason? {
        guard case .unavailable(let reason) = model.availability else { return nil }
        return reason
    }

    /// Instructions are fixed at compile time and never include user input, so
    /// there's no path for logged data to alter the model's behaviour.
    private static let instructions = Instructions {
        """
        You rewrite health tracking statistics into brief, natural sentences for \
        the person whose data it is.

        Rules you must follow:
        - Only describe the facts you are given. Never introduce a food, a number, \
        a symptom, or a correlation that does not appear in them.
        - Never diagnose, never name a condition, and never give medical or \
        dietary advice.
        - Never tell the person to see a doctor; the app handles that separately.
        - Describe associations as associations, not causes.
        - Write one or two sentences in second person. Be calm and factual. Do \
        not be alarming and do not be falsely reassuring.
        """
    }

    /// Rewrites `facts` as prose, returning `fallback` if anything goes wrong.
    ///
    /// Never throws and never returns an empty string: the caller's deterministic
    /// text is always a valid answer, so a model failure degrades the wording
    /// rather than the feature.
    func narrate(_ facts: InsightFacts, fallback: String) async -> String {
        guard isAvailable else { return fallback }

        // A session per call keeps each narration independent. There's no
        // conversation here, and a shared transcript would grow unbounded and
        // eventually throw contextSizeExceeded.
        let session = LanguageModelSession(instructions: Self.instructions)

        do {
            let response = try await session.respond(
                to: """
                Summarize this data:

                \(facts.promptDescription)
                """,
                generating: NarratedInsight.self,
                options: GenerationOptions(temperature: 0.3)
            )
            let summary = response.content.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            return summary.isEmpty ? fallback : summary
        } catch {
            // Guardrail violations, refusals, context overflow and unsupported
            // locales all land here and all mean the same thing to the caller.
            return fallback
        }
    }
}
