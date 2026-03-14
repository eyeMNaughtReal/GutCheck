//
//  TabBarItem.swift
//  GutCheck
//
//  Individual tab bar item view component.
//

import SwiftUI

struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? ColorTheme.primary : ColorTheme.secondaryText)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(isSelected ? ColorTheme.primary : ColorTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
