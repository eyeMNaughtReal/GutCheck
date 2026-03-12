import SwiftUI

struct LogEntryView: View {
    @EnvironmentObject var router: AppRouter
    
    var body: some View {
        VStack(spacing: 40) {
            Text("What would you like to log?")
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 30) {
                LogOptionButton(
                    title: "Meal",
                    icon: "fork.knife",
                    color: .blue
                ) {
                    router.startMealLogging()
                }
                
                LogOptionButton(
                    title: "Symptom",
                    icon: "heart.text.square",
                    color: .purple
                ) {
                    router.startSymptomLogging()
                }
            }
            
            Button("Cancel") {
                router.dismissSheet()
            }
            .padding(.top, 20)
        }
        .padding()
    }
}

struct LogOptionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(color)
                
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .frame(width: 120, height: 120)
            .background(color.opacity(0.1))
            .clipShape(.rect(cornerRadius: 20))
        }
    }
}

#Preview {
    LogEntryView()
        .environmentObject(AppRouter.shared)
}
