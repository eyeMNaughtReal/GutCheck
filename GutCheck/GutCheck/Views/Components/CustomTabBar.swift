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
    @Environment(AppRouter.self) var router
    
    // Using shared Tab enum from Models/Core/Tab.swift

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Tab Bar (always fixed to bottom)
                VStack {
                    Spacer()
                    CustomTabBarContent(
                        selectedTab: selectedTab,
                        onTabSelected: { handleTabSelection($0) }
                    )
                }
            }
        }
    }
    
    private func handleTabSelection(_ tab: Tab) {
        
        // If switching to a different tab, reset navigation and switch tab
        if selectedTab != tab {
            router.navigateToRoot() // Clear navigation stack
            selectedTab = tab // Update the binding
        } else {
            // Same tab selected - pop to root if we're in a navigation stack
            if true {
                router.navigateToRoot()
            }
        }
    }
}

struct CustomTabBarContent: View {
    let selectedTab: Tab
    let onTabSelected: (Tab) -> Void
    
    var body: some View {
        HStack {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                TabBarItem(
                    icon: tab.icon,
                    label: tab.title,
                    isSelected: selectedTab == tab
                ) {
                    onTabSelected(tab)
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
}
