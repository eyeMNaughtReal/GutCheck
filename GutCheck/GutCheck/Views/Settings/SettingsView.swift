import SwiftUI

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

#if DEBUG
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView().environmentObject(AuthService())
    }
}
#endif
