import SwiftUI

extension View {
    func roundedCard() -> some View {
        self
            .padding()
            .background(ColorTheme.cardBackground)
            .clipShape(.rect(cornerRadius: 10))
            .shadow(radius: 2)
    }
    
    func primaryButton() -> some View {
        self
            .padding()
            .background(ColorTheme.buttonPrimary)
            .foregroundStyle(.white)
            .clipShape(.rect(cornerRadius: 8))
    }
    
    func secondaryButton() -> some View {
        self
            .padding()
            .background(ColorTheme.buttonSecondary)
            .foregroundStyle(ColorTheme.text)
            .clipShape(.rect(cornerRadius: 8))
    }
    
    func inputField() -> some View {
        self
            .padding()
            .background(ColorTheme.inputBackground)
            .clipShape(.rect(cornerRadius: 8))
    }
}
