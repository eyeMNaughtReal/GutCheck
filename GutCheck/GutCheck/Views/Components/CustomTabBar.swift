//
//  CustomTabBar.swift
//  GutCheck
//
//  Updated CustomTabBar with improved action handling and cleaner architecture
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    let actionHandler: (TabBarAction) -> Void
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    @State private var showActions = false
    @Namespace private var animation

    // Using shared Tab enum from Models/Core/Tab.swift

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
                if showActions {
                    actionButtonsView
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
                        .allowsHitTesting(showActions)
                        .zIndex(1)
                }

                // Tab Bar (always fixed to bottom)
                VStack {
                    Spacer()
                    tabBarView
                }
            }
        }
    }
    
    private var actionButtonsView: some View {
        let offsetY: CGFloat = -87
        let offsetX: CGFloat = 60
        
        return ZStack {
            ActionFlyButton(
                icon: "fork.knife",
                label: "Log Meal",
                color: ColorTheme.accent,
                action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        showActions = false
                    }
                    actionHandler(.logMeal)
                }
            )
            .offset(x: showActions ? -offsetX : 0, y: showActions ? offsetY : 0)
            .scaleEffect(showActions ? 1.0 : 0.1)
            .opacity(showActions ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showActions)

            ActionFlyButton(
                icon: "stethoscope",
                label: "Log Symptom",
                color: ColorTheme.secondary,
                action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        showActions = false
                    }
                    actionHandler(.logSymptom)
                }
            )
            .offset(x: showActions ? offsetX : 0, y: showActions ? offsetY : 0)
            .scaleEffect(showActions ? 1.0 : 0.1)
            .opacity(showActions ? 1 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.05), value: showActions)
        }
    }
    
    private var tabBarView: some View {
        HStack {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                if tab == .add {
                    plusButton
                } else {
                    TabBarItem(
                        icon: tab.icon,
                        label: tab.title,
                        isSelected: selectedTab == tab
                    ) {
                        handleTabSelection(tab)
                    }
                }
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
    
    private var plusButton: some View {
        ZStack {
            Circle()
                .fill(ColorTheme.accent)
                .frame(width: 56, height: 56)
                .shadow(color: ColorTheme.accent.opacity(0.3), radius: 8, x: 0, y: 4)
            
            Image(systemName: showActions ? "xmark" : "plus")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(ColorTheme.lightText)
                .rotationEffect(.degrees(showActions ? 45 : 0))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showActions)
        }
        .offset(y: -16)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                showActions.toggle()
            }
        }
    }
    
    private func handleTabSelection(_ tab: Tab) {
        print("🔧 CustomTabBar: Handling tab selection for \(tab)")
        print("🔧 Current tab: \(selectedTab), switching to: \(tab)")
        print("🔧 Current navigation path count: \(navigationCoordinator.currentNavigationPath.wrappedValue.count)")
        
        // If switching to a different tab, clear the current tab's navigation stack BEFORE switching
        if selectedTab != tab {
            // Clear the current tab's navigation stack (get the correct path for the OLD tab)
            let currentPath = navigationCoordinator.currentNavigationPath
            currentPath.wrappedValue = NavigationPath()
            print("🔧 Cleared navigation stack for old tab: \(selectedTab)")
            
            // Switch to the new tab
            selectedTab = tab
            print("🔧 Switched to new tab: \(tab)")
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
