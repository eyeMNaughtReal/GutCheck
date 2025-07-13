//
//  ContentView.swift
//  GutCheck
//
//  Created by Mark Conley on 7/9/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    @State private var selectedTab: CustomTabBar.Tab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    DashboardView()
                case .meal:
                    Text("Calendar View")
                case .symptoms:
                    Text("Analytics View")
                case .insights:
                    InsightsView()
                default:
                    DashboardView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}
// ...existing code...

// ...existing code...

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
