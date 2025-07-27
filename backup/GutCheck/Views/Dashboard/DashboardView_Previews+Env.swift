import SwiftUI

// This preview injects a dummy AuthService so @EnvironmentObject is satisfied
#Preview {
    DashboardView()
        .environmentObject(AuthService())
}
