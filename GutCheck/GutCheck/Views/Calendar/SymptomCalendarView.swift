//
//  SymptomCalendarView.swift
//  GutCheck
//
//  Created by Mark Conley on 7/14/25.
//


//
//  SymptomCalendarView.swift
//  GutCheck
//
//  Created on 7/14/25.
//

import SwiftUI

struct SymptomCalendarView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    
    var body: some View {
        Text("Symptom Calendar View")
            .navigationTitle("Symptoms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ProfileAvatarButton {
                        navigationCoordinator.isShowingProfile = true
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        SymptomCalendarView()
            .environmentObject(NavigationCoordinator())
    }
}