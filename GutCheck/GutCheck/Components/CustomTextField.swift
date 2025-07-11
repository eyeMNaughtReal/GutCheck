//
//  CustomTextField.swift
//  GutCheck
//
//  Created by Mark Conley on 7/11/25.
//

import SwiftUI

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    
    @FocusState private var isFocused: Bool
    
    init(title: String, text: Binding<String>, placeholder: String? = nil, isSecure: Bool = false, keyboardType: UIKeyboardType = .default) {
        self.title = title
        self._text = text
        self.placeholder = placeholder ?? title
        self.isSecure = isSecure
        self.keyboardType = keyboardType
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.text)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ColorTheme.surface)
                    )
                
                HStack {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                            .textFieldStyle(PlainTextFieldStyle())
                            .keyboardType(keyboardType)
                            .focused($isFocused)
                    } else {
                        TextField(placeholder, text: $text)
                            .textFieldStyle(PlainTextFieldStyle())
                            .keyboardType(keyboardType)
                            .focused($isFocused)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(height: 48)
        }
    }
    
    private var borderColor: Color {
        if isFocused {
            return ColorTheme.primary
        } else if !text.isEmpty {
            return ColorTheme.mint
        } else {
            return ColorTheme.border
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomTextField(
            title: "Email",
            text: .constant(""),
            placeholder: "Enter your email"
        )
        
        CustomTextField(
            title: "Password",
            text: .constant(""),
            placeholder: "Enter your password",
            isSecure: true
        )
        
        CustomTextField(
            title: "Phone Number",
            text: .constant(""),
            placeholder: "Enter your phone number",
            keyboardType: .phonePad
        )
    }
    .padding()
    .background(ColorTheme.background)
}
