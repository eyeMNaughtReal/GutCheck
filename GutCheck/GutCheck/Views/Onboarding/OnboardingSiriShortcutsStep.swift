//
//  OnboardingSiriShortcutsStep.swift
//  GutCheck
//
//  Onboarding step that introduces hands-free logging with Siri.
//
//  Logging is easiest to abandon when both hands are busy, so the Siri
//  shortcuts are surfaced during onboarding rather than buried in Settings.
//

import SwiftUI

struct OnboardingSiriShortcutsStep: View {
    @Binding var currentStep: Int

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "mic.circle")
                    .font(.system(size: 64))
                    .foregroundStyle(ColorTheme.primary)
                    .accessibleDecorative()

                Text("Log With Your Voice")
                    .font(.largeTitle.bold())
                    .foregroundStyle(ColorTheme.primaryText)

                Text("Ask Siri to log a meal or a symptom when your hands are full. Everything stays on your device until you confirm it.")
                    .typography(Typography.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(ColorTheme.secondaryText)
            }

            Spacer()

            // Example phrases
            VStack(spacing: 16) {
                Text("Try saying:")
                    .typography(Typography.headline)
                    .foregroundStyle(ColorTheme.primaryText)

                phraseList
            }

            // Live Siri tips — only available from iOS 16.4
            if #available(iOS 16.4, *) {
                SiriShortcutsTipView(showsHeader: false)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 16) {
                Button("Continue") {
                    HapticManager.shared.light()
                    currentStep += 1
                }
                .typography(Typography.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(ColorTheme.primary)
                .clipShape(.rect(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(ColorTheme.background.ignoresSafeArea())
    }

    private var phraseList: some View {
        VStack(spacing: 12) {
            ForEach([
                ("fork.knife", "\"Hey Siri, log my lunch in GutCheck\""),
                ("heart.text.square", "\"Hey Siri, log a symptom in GutCheck\""),
                ("drop.fill", "\"Hey Siri, log water in GutCheck\""),
                ("chart.bar.fill", "\"Hey Siri, what's my GutCheck score\"")
            ], id: \.1) { icon, phrase in
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(ColorTheme.primary)
                        .frame(width: 32)
                        .accessibleDecorative()

                    Text(phrase)
                        .typography(Typography.subheadline)
                        .foregroundStyle(ColorTheme.primaryText)

                    Spacer()
                }
                .padding(.vertical, 6)
            }
        }
        .padding(16)
        .background(ColorTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    OnboardingSiriShortcutsStep(currentStep: .constant(0))
}
