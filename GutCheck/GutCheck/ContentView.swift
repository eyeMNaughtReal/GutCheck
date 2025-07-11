//
//  ContentView.swift
//  GutCheck
//
//  Created by Mark Conley on 7/9/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        TabView {
            MealDashboardView()
                .tabItem {
                    Image(systemName: "fork.knife")
                    Text("Meals")
                }
            
            Text("Calendar View")
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendar")
                }
            
            Text("Analytics View")
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("Analytics")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(ColorTheme.primary)
    }
}

// Temporary placeholder views
struct MealDashboardView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("🍽️")
                    .font(.system(size: 60))
                
                Text("Welcome to GutCheck!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.text)
                
                Text("Your meal logging journey starts here.")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
                
                CustomButton(title: "Log Your First Meal", action: {
                    // TODO: Navigate to meal logging
                })
                .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ColorTheme.background)
            .navigationTitle("Meals")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(ColorTheme.primary)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(authService.user?.displayName?.prefix(2).uppercased() ?? "??")
                                    .foregroundColor(.white)
                                    .fontWeight(.semibold)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(authService.user?.displayName ?? "Unknown User")
                                .font(.headline)
                            Text(authService.user?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Account") {
                    Button("Sign Out") {
                        try? authService.signOut()
                    }
                    .foregroundColor(ColorTheme.error)
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
