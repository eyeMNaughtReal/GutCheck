//
//  BristolScaleSelectionView.swift
//  GutCheck
//
//  Bristol Stool Scale selection component with square buttons and color coding
//

import SwiftUI

struct BristolScaleSelectionView: View {
    @ObservedObject var viewModel: BristolScaleViewModel
    @State private var showBristolInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with info button
            HStack {
                Text("Bristol Stool Scale")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Button(action: { showBristolInfo = true }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(ColorTheme.primary)
                }
                
                Spacer()
            }
            
            // Bristol scale grid (2 rows of 4, with type 7 on second row)
            VStack(spacing: 12) {
                // First row: Types 1-4
                HStack(spacing: 8) {
                    ForEach(Array(StoolType.allCases.prefix(4)), id: \.self) { type in
                        BristolTypeButton(
                            type: type,
                            isSelected: viewModel.selectedStoolType == type,
                            typeInfo: viewModel.getTypeInfo(for: type)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectStoolType(type)
                            }
                        }
                    }
                }
                
                // Second row: Types 5-7
                HStack(spacing: 8) {
                    ForEach(Array(StoolType.allCases.suffix(3)), id: \.self) { type in
                        BristolTypeButton(
                            type: type,
                            isSelected: viewModel.selectedStoolType == type,
                            typeInfo: viewModel.getTypeInfo(for: type)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectStoolType(type)
                            }
                        }
                    }
                    
                    // Empty space to align with first row
                    Spacer()
                        .frame(width: 60)
                }
            }
            
            // Description for selected type
            if let description = viewModel.selectedTypeDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primaryText)
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .sheet(isPresented: $showBristolInfo) {
            BristolStoolInfoView()
        }
    }
}

struct BristolTypeButton: View {
    let type: StoolType
    let isSelected: Bool
    let typeInfo: BristolTypeInfo?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(type.rawValue)")
                .font(.title2.bold())
                .foregroundColor(ColorTheme.primaryText)
                .frame(width: 60, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
    
    private var backgroundColor: Color {
        guard let typeInfo = typeInfo else {
            return ColorTheme.surface
        }
        
        return isSelected ? typeInfo.selectedColor : typeInfo.color
    }
    
    private var borderColor: Color {
        return isSelected ? ColorTheme.primary : ColorTheme.border
    }
    
    private var borderWidth: CGFloat {
        return isSelected ? 2 : 1
    }
}

#Preview {
    VStack {
        BristolScaleSelectionView(viewModel: BristolScaleViewModel())
            .padding()
    }
    .background(ColorTheme.background)
}
