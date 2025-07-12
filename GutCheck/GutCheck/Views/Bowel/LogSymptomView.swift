//
//  LogSymptomView.swift
//  GutCheck
//
//  Created by Mark Conley on 7/12/25.
//

import SwiftUI

struct LogSymptomView: View {
    @State private var showProfileSheet = false
    var body: some View {
        NavigationView {
            Text("Hello, World!")
                .navigationBarItems(trailing:
                    ProfileAvatarButton {
                        showProfileSheet = true
                    }
                )
                .sheet(isPresented: $showProfileSheet) {
                    UserProfileView(user: UserProfile(id: "1", email: "jenny@email.com", fullName: "Jenny Wilson", age: 20, weight: 76, height: 176))
                }
        }
    }
}

#Preview {
    LogSymptomView()
}
