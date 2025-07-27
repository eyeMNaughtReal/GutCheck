import SwiftUI

extension View {
    func roundedCard() -> some View {
        self
            .padding()
            .background(ColorTheme.cardBackground)
            .cornerRadius(10)
            .shadow(radius: 2)
    }
    
    func primaryButton() -> some View {
        self
            .padding()
            .background(ColorTheme.buttonPrimary)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    func secondaryButton() -> some View {
        self
            .padding()
            .background(ColorTheme.buttonSecondary)
            .foregroundColor(ColorTheme.text)
            .cornerRadius(8)
    }
    
    func inputField() -> some View {
        self
            .padding()
            .background(ColorTheme.inputBackground)
            .cornerRadius(8)
    }
}
