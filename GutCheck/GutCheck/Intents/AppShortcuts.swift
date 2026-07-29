//
//  AppShortcuts.swift
//  GutCheck
//
//  Curated Siri phrases for GutCheck's App Intents, plus the tip views that
//  make those phrases discoverable inside the app.
//
//  Shortcuts declared here appear automatically in the Shortcuts app and in
//  Spotlight — the user doesn't have to build anything first.
//

import AppIntents
import SwiftUI

// MARK: - Shortcuts Provider

@available(iOS 16.0, *)
struct GutCheckAppShortcuts: AppShortcutsProvider {

    /// Siri matches spoken phrases verbatim, so each intent gets several
    /// natural phrasings. Every phrase must contain the app name token.
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogMealIntent(),
            phrases: [
                "Log a meal in \(.applicationName)",
                "Log my meal in \(.applicationName)",
                "Log my lunch in \(.applicationName)",
                "Log my breakfast in \(.applicationName)",
                "Log my dinner in \(.applicationName)",
                "Track what I ate in \(.applicationName)"
            ],
            shortTitle: "Log Meal",
            systemImageName: "fork.knife"
        )

        AppShortcut(
            intent: LogSymptomIntent(),
            phrases: [
                "Log a symptom in \(.applicationName)",
                "Log my symptoms in \(.applicationName)",
                "Record a gut symptom in \(.applicationName)",
                "I'm having symptoms in \(.applicationName)"
            ],
            shortTitle: "Log Symptom",
            systemImageName: "heart.text.square.fill"
        )

        AppShortcut(
            intent: GetHealthScoreIntent(),
            phrases: [
                "What's my \(.applicationName) score",
                "What's my gut health score in \(.applicationName)",
                "Check my \(.applicationName) health score",
                "How's my gut today in \(.applicationName)"
            ],
            shortTitle: "Health Score",
            systemImageName: "chart.bar.fill"
        )

        AppShortcut(
            intent: LogWaterIntent(),
            phrases: [
                "Log water in \(.applicationName)",
                "Log a glass of water in \(.applicationName)",
                "Track my water in \(.applicationName)",
                "I drank water in \(.applicationName)"
            ],
            shortTitle: "Log Water",
            systemImageName: "drop.fill"
        )
    }
}

// MARK: - Siri Tips

/// Surfaces the curated Siri phrases so users discover voice logging without
/// having to open the Shortcuts app.
///
/// `SiriTipView` and `ShortcutsLink` are iOS 16.4+, so the whole view is gated;
/// callers wrap it in an availability check.
@available(iOS 16.4, *)
struct SiriShortcutsTipView: View {
    /// Persisted so a dismissed tip stays dismissed across launches.
    @AppStorage("siriTip.mealTipVisible") private var mealTipVisible = true
    @AppStorage("siriTip.symptomTipVisible") private var symptomTipVisible = true

    /// Whether to show the supporting copy above the tips.
    private let showsHeader: Bool

    /// Explicit initializer: the `@AppStorage` properties are private, which
    /// would otherwise make the memberwise initializer private too.
    init(showsHeader: Bool = true) {
        self.showsHeader = showsHeader
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if showsHeader {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Log hands-free")
                        .typography(Typography.headline)
                        .foregroundStyle(ColorTheme.primaryText)

                    Text("Ask Siri to log meals and symptoms while you're cooking or eating.")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }
                .accessibilityElement(children: .combine)
            }

            if mealTipVisible {
                SiriTipView(intent: LogMealIntent(), isVisible: $mealTipVisible)
            }

            if symptomTipVisible {
                SiriTipView(intent: LogSymptomIntent(), isVisible: $symptomTipVisible)
            }

            ShortcutsLink()
                .shortcutsLinkStyle(.automaticOutline)
                .accessibilityLabel("Open GutCheck shortcuts in the Shortcuts app")
        }
    }
}

#Preview {
    if #available(iOS 16.4, *) {
        SiriShortcutsTipView()
            .padding()
            .background(ColorTheme.background)
    }
}
