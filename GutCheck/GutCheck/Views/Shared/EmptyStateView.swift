import SwiftUI

struct EmptyStateView: View {
    let message: String
    let imageName: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: imageName)
                .font(.system(size: 50))
                .foregroundStyle(.gray)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}

#Preview {
    EmptyStateView(
        message: "No data available for this day",
        imageName: "calendar.badge.exclamationmark"
    )
}
