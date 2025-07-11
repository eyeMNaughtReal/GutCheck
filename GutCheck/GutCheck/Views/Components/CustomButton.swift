//
//  CustomButton.swift
//  GutCheck
//
//  Created by Mark Conley on 7/11/25.
//

import SwiftUI

struct CustomButton: View {
    let title: String
    let action: () -> Void
    var style: ButtonStyle = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    
    enum ButtonStyle {
        case primary
        case secondary
        case outline
        case danger
        case success
        
        var backgroundColor: Color {
            switch self {
            case .primary:
                return ColorTheme.primary
            case .secondary:
                return ColorTheme.secondary
            case .outline:
                return Color.clear
            case .danger:
                return ColorTheme.error
            case .success:
                return ColorTheme.success
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .danger, .success:
                return ColorTheme.lightText
            case .secondary:
                return ColorTheme.text
            case .outline:
                return ColorTheme.primary
            }
        }
        
        var borderColor: Color {
            switch self {
            case .outline:
                return ColorTheme.primary
            default:
                return Color.clear
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isDisabled ? ColorTheme.disabled : style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(style.borderColor, lineWidth: style == .outline ? 2 : 0)
            )
            .cornerRadius(12)
            .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
        }
        .disabled(isDisabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

// Convenience modifiers
extension CustomButton {
    func loading(_ isLoading: Bool) -> CustomButton {
        CustomButton(
            title: title,
            action: action,
            style: style,
            isLoading: isLoading,
            isDisabled: isDisabled
        )
    }
    
    func disabled(_ isDisabled: Bool) -> CustomButton {
        CustomButton(
            title: title,
            action: action,
            style: style,
            isLoading: isLoading,
            isDisabled: isDisabled
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomButton(title: "Primary Button", action: {})
        
        CustomButton(title: "Secondary Button", action: {}, style: .secondary)
        
        CustomButton(title: "Outline Button", action: {}, style: .outline)
        
        CustomButton(title: "Loading Button", action: {}, isLoading: true)
        
        CustomButton(title: "Disabled Button", action: {}, isDisabled: true)
    }
    .padding()
    .background(ColorTheme.background)
}
