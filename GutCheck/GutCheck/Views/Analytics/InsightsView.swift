
//  InsightsView.swift
//  GutCheck
//
//  Fixed to use correct navigation and User model
//

import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showProfileSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Insights Coming Soon!")
                    .font(.title2)
                    .foregroundColor(ColorTheme.secondaryText)
                
                Text("AI-powered food trigger analysis will be available in a future update.")
                    .font(.body)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showProfileSheet = true
                    }) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                            .foregroundColor(ColorTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showProfileSheet) {
                if let currentUser = authService.currentUser {
                    UserProfileView(user: currentUser)
                        .environmentObject(authService)
                } else {
                    VStack(spacing: 20) {
                        ProgressView()
                        Text("Loading profile...")
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(ColorTheme.background)
                }
            }
        }
    }
}

#Preview {
    InsightsView()
        .environmentObject(AuthService())
}
