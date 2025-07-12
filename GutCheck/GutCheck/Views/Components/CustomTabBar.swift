import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @State private var showActions = false
    @Namespace private var animation

    enum Tab: Int {
        case home, meal, plus, symptoms, insights
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Darkened overlay when actions are shown
                if showActions {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                showActions = false
                            }
                        }
                }

                // Action Buttons (fly up and out)
                // Animate buttons flying out from the plus button and retracting back in
                let offsetY: CGFloat = -87
                let offsetX: CGFloat = 60
                ZStack {
                    ActionFlyButton(
                        icon: "fork.knife",
                        label: "Log Meal",
                        color: ColorTheme.accent,
                        action: { /* Log Meal Action */ }
                    )
                    .offset(x: showActions ? -offsetX : 0, y: showActions ? (showActions ? offsetY : 0) : 0)
                    .scaleEffect(showActions ? 1.0 : 0.1)
                    .opacity(showActions ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showActions)

                    ActionFlyButton(
                        icon: "stethoscope",
                        label: "Log Symptom",
                        color: ColorTheme.secondary,
                        action: { /* Log Symptom Action */ }
                    )
                    .offset(x: showActions ? offsetX : 0, y: showActions ? (showActions ? offsetY : 0) : 0)
                    .scaleEffect(showActions ? 1.0 : 0.1)
                    .opacity(showActions ? 1 : 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.05), value: showActions)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
                .allowsHitTesting(showActions)
                .zIndex(1)

                // Tab Bar (always fixed to bottom)
                VStack {
                    Spacer()
                    HStack {
                        TabBarItem(icon: "house", label: "Home", isSelected: selectedTab == .home) {
                            selectedTab = .home
                        }
                        TabBarItem(icon: "list.bullet", label: "Meal", isSelected: selectedTab == .meal) {
                            selectedTab = .meal
                        }

                        ZStack {
                            Circle()
                                .fill(ColorTheme.accent)
                                .frame(width: 56, height: 56)
                                .shadow(color: ColorTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(ColorTheme.lightText)
                        }
                        .offset(y: -16) // Move the plus button up by 6px
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                showActions.toggle()
                            }
                        }

                        TabBarItem(icon: "waveform.path.ecg", label: "Symptoms", isSelected: selectedTab == .symptoms) {
                            selectedTab = .symptoms
                        }
                        TabBarItem(icon: "chart.bar.xaxis", label: "Insights", isSelected: selectedTab == .insights) {
                            selectedTab = .insights
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    .padding(.bottom, 8)
                    .background(
                        ColorTheme.cardBackground
                            .shadow(color: ColorTheme.shadowColor, radius: 8, x: 0, y: -2)
                            .edgesIgnoringSafeArea(.bottom)
                    )
                }
            }
        }
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(isSelected ? ColorTheme.primary : ColorTheme.secondaryText)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(isSelected ? ColorTheme.primary : ColorTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct ActionFlyButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: color.opacity(0.18), radius: 10, x: 0, y: 5)
                    .frame(width: 100, height: 100)
                VStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(color)
                    Text(label)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(ColorTheme.text)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 2)
                }
                .padding(.top, 6)
            }
        }
    }
}
