//
//  LogSymptomView.swift
//  GutCheck
//
//  Fixed to use correct navigation and User model
//

import SwiftUI

struct LogSymptomView: View {
    @EnvironmentObject var authService: AuthService
    @State private var showProfileSheet = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Symptom Logging Coming Soon!")
                    .font(.title2)
                    .foregroundColor(ColorTheme.secondaryText)
                
                Text("Bristol stool chart and symptom tracking will be available in a future update.")
                    .font(.body)
                    .foregroundColor(ColorTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Log Symptoms")
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
    LogSymptomView()
        .environmentObject(AuthService())
}
