//
//  PainLevelInfoView.swift
//  GutCheck
//
//  Information modal view for pain level assessment.
//

import SwiftUI

// MARK: - Pain Level Info View

struct PainLevelInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("0-10 Numeric Pain Scale")
                            .font(.headline)
                            .foregroundStyle(ColorTheme.primaryText)
                        
                        Text("Rate your abdominal pain, cramping, or discomfort.")
                            .font(.subheadline)
                            .foregroundStyle(ColorTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(ColorTheme.surface)
                    
                    // Pain scale visualization
                    VStack(spacing: 20) {
                        // Horizontal scale
                        HStack(spacing: 0) {
                            ForEach(0...4, id: \.self) { level in
                                VStack(spacing: 8) {
                                    Text("\(level)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(painColor(for: level)))
                                    
                                    Text(painLabel(for: level))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(ColorTheme.secondaryText)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                        
                        // Detailed descriptions
                        VStack(spacing: 12) {
                            PainRangeCard(range: "0", title: "No Pain", description: "No discomfort", color: ColorTheme.success)
                            PainRangeCard(range: "1-2", title: "Mild", description: "Slight discomfort", color: Color.green.opacity(0.8))
                            PainRangeCard(range: "3-4", title: "Moderate", description: "Noticeable pain", color: ColorTheme.warning)
                            PainRangeCard(range: "5+", title: "Severe", description: "Significant pain", color: ColorTheme.error)
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Pain Assessment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(ColorTheme.primary)
                }
            }
        }
    }
    
    private func painColor(for level: Int) -> Color {
        switch level {
        case 0: return ColorTheme.success
        case 1: return Color.green.opacity(0.8)
        case 2: return ColorTheme.warning
        case 3: return Color.orange
        case 4: return ColorTheme.error
        default: return ColorTheme.secondaryText
        }
    }
    
    private func painLabel(for level: Int) -> String {
        switch level {
        case 0: return "None"
        case 1: return "Mild"
        case 2: return "Moderate"
        case 3: return "Severe"
        case 4: return "Extreme"
        default: return ""
        }
    }
}

#Preview("Pain Level") {
    PainLevelInfoView()
}
