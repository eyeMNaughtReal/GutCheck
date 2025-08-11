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
    @EnvironmentObject var router: AppRouter
    
    // Using shared Tab enum from Models/Core/Tab.swift

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Tab Bar (always fixed to bottom)
                VStack {
                    Spacer()
                    tabBarView
                }
            }
        }
    }
    
    private var tabBarView: some View {
        HStack {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                TabBarItem(
                    icon: tab.icon,
                    label: tab.title,
                    isSelected: selectedTab == tab
                ) {
                    handleTabSelection(tab)
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
    
    
    
    private func handleTabSelection(_ tab: Tab) {
        print("🔧 CustomTabBar: Handling tab selection for \(tab)")
        print("🔧 Current tab: \(selectedTab), switching to: \(tab)")
        print("🔧 Current navigation path count: \(router.path.count)")
        
        // If switching to a different tab, reset navigation and switch tab
        if selectedTab != tab {
            print("🔧 Switching from \(selectedTab) to \(tab)")
            router.navigateToRoot() // Clear navigation stack
            selectedTab = tab // Update the binding
            print("🔧 Tab switch completed")
        } else {
            // Same tab selected - pop to root if we're in a navigation stack
            if !router.path.isEmpty {
                router.navigateToRoot()
                print("🔧 Same tab selected - popped to root for tab: \(tab)")
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
