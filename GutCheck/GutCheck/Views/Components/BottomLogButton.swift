import SwiftUI

/// Full-width primary action pinned to the bottom of a logging screen.
///
/// Attach with `.safeAreaInset(edge: .bottom)` so scroll content insets for it
/// rather than sliding underneath. It stacks above the app's tab bar, which is
/// itself a safeAreaInset in ContentView.
///
/// Bottom placement is deliberate: these are the primary action on their screen
/// and belong in the thumb zone rather than beside a section header.
struct BottomLogButton: View {
    let title: String
    let systemImage: String
    let accessibilityHint: String
    let action: () -> Void

    var body: some View {
        Button {
            HapticManager.shared.medium()
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
            }
            .typography(Typography.button)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(ColorTheme.accent, in: Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 4)
        // Keeps the bar readable when list content scrolls behind it.
        .background(.ultraThinMaterial)
        .accessibleButton(label: title, hint: accessibilityHint)
    }
}

#Preview {
    VStack {
        Spacer()
        BottomLogButton(
            title: "Log Meal",
            systemImage: "plus.circle.fill",
            accessibilityHint: "Tap to log a new meal"
        ) {}
    }
    .background(ColorTheme.background)
}
