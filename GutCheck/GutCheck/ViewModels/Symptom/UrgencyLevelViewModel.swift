//
//  UrgencyLevelSelectionView.swift
//  GutCheck
//
//  Urgency level selection component
//

import SwiftUI

struct UrgencyLevelSelectionView: View {
    @ObservedObject var viewModel: UrgencyLevelViewModel
    @State private var showUrgencyInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with info button
            HStack {
                Text("Urgency Level")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Button(action: { showUrgencyInfo = true }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(ColorTheme.primary)
                }
                
                Spacer()
            }
            
            // Urgency level buttons
            VStack(spacing: 8) {
                ForEach(viewModel.urgencyLevels, id: \.level) { urgencyInfo in
                    UrgencyLevelButton(
                        urgencyInfo: urgencyInfo,
                        isSelected: viewModel.selectedUrgencyLevel == urgencyInfo.level
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectUrgencyLevel(urgencyInfo.level)
                        }
                    }
                }
            }
            
            // Description for selected level
            if viewModel.selectedUrgencyLevel != .none {
                Text(viewModel.selectedUrgencyDescription)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primaryText)
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .sheet(isPresented: $showUrgencyInfo) {
            UrgencyLevelInfoView()
        }
    }
}

struct UrgencyLevelButton: View {
    let urgencyInfo: UrgencyLevelInfo
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Level indicator
                Text("\(urgencyInfo.level.rawValue)")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isSelected ? ColorTheme.primary : ColorTheme.secondaryText)
                    )
                
                // Title and description
                VStack(alignment: .leading, spacing: 2) {
                    Text(urgencyInfo.title)
                        .font(.subheadline.bold())
                        .foregroundColor(ColorTheme.primaryText)
                    
                    Text(urgencyInfo.description)
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(ColorTheme.primary)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? ColorTheme.primary.opacity(0.1) : ColorTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? ColorTheme.primary : ColorTheme.border, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

#Preview {
    VStack {
        UrgencyLevelSelectionView(viewModel: UrgencyLevelViewModel())
            .padding()
    }
    .background(ColorTheme.background)
}
