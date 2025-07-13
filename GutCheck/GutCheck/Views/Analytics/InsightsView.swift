
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
                    ProfileAvatarButton {
                        showProfileSheet = true
                    }
                }
            }
            .sheet(isPresented: $showProfileSheet) {
                if let currentUser = authService.currentUser {
                    UserProfileView(user: currentUser)
                }
            }
        }
    }
}

#Preview {
    InsightsView()
        .environmentObject(AuthService())
}
