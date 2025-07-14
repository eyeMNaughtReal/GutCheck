//
//  PainLevelSliderView.swift
//  GutCheck
//
//  Pain level slider component (0-10 scale)
//

import SwiftUI

struct PainLevelSliderView: View {
    @ObservedObject var viewModel: PainLevelViewModel
    @State private var showPainInfo = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with info button
            HStack {
                Text("Pain Level")
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Button(action: { showPainInfo = true }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(ColorTheme.primary)
                }
                
                Spacer()
            }
            
            // Current level display
            HStack {
                Text("Current Level:")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
                
                Text(viewModel.formattedLevel)
                    .font(.title2.bold())
                    .foregroundColor(viewModel.currentColor)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.painLevel)
                
                Spacer()
                
                Text(viewModel.currentDescription)
                    .font(.subheadline)
                    .foregroundColor(viewModel.currentColor)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.painLevel)
            }
            
            // Slider
            VStack(spacing: 8) {
                Slider(
                    value: Binding(
                        get: { viewModel.painLevel },
                        set: { viewModel.setPainLevel($0) }
                    ),
                    in: 0...10,
                    step: 1
                ) {
                    Text("Pain Level")
                } minimumValueLabel: {
                    Text("0")
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                } maximumValueLabel: {
                    Text("10")
                        .font(.caption)
                        .foregroundColor(ColorTheme.secondaryText)
                }
                .accentColor(viewModel.currentColor)
                
                // Scale markers
                HStack {
                    ForEach(0...10, id: \.self) { level in
                        VStack(spacing: 2) {
                            Rectangle()
                                .fill(level == Int(viewModel.painLevel) ? viewModel.currentColor : ColorTheme.border)
                                .frame(width: 1, height: level % 5 == 0 ? 8 : 4)
                            
                            if level % 5 == 0 {
                                Text("\(level)")
                                    .font(.caption2)
                                    .foregroundColor(ColorTheme.secondaryText)
                            }
                        }
                        
                        if level < 10 {
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding()
            .background(ColorTheme.surface)
            .cornerRadius(12)
        }
        .sheet(isPresented: $showPainInfo) {
            PainLevelInfoView()
        }
    }
}

#Preview {
    VStack {
        PainLevelSliderView(viewModel: PainLevelViewModel())
            .padding()
    }
    .background(ColorTheme.background)
}
