import SwiftUI

// This preview injects a dummy LocalUserService so @EnvironmentObject is satisfied
#Preview {
    DashboardView()
        .environment(LocalUserService.shared)
}
