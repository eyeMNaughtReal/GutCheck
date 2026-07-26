//
//  UrgencyLevelInfoView.swift
//  GutCheck
//
//  Information modal view for urgency level assessment.
//

import SwiftUI

// MARK: - Urgency Level Info View

struct UrgencyLevelInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Urgency Classification")
                            .font(.headline)
                            .foregroundStyle(ColorTheme.primaryText)
                        
                        Text("How urgently did you need to use the bathroom?")
                            .font(.subheadline)
                            .foregroundStyle(ColorTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(ColorTheme.surface)
                    
                    // Urgency scale
                    VStack(spacing: 20) {
                        // Visual scale
                        HStack(spacing: 16) {
                            ForEach(0...3, id: \.self) { level in
                                VStack(spacing: 8) {
                                    Circle()
                                        .fill(urgencyColor(for: level))
                                        .frame(width: 32, height: 32)
                                    
                                    Text(urgencyLabel(for: level))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(ColorTheme.secondaryText)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding()
                        
                        // Descriptions
                        VStack(spacing: 12) {
                            UrgencyCard(level: "None", description: "No urgency - could wait", color: ColorTheme.success)
                            UrgencyCard(level: "Mild", description: "Slight urge - easily manageable", color: ColorTheme.warning)
                            UrgencyCard(level: "Moderate", description: "Notable urge - should find bathroom", color: Color.orange)
                            UrgencyCard(level: "Urgent", description: "Immediate need - couldn't wait", color: ColorTheme.error)
                        }
                        .padding()
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Urgency Assessment")
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
    
    private func urgencyColor(for level: Int) -> Color {
        switch level {
        case 0: return ColorTheme.success
        case 1: return ColorTheme.warning
        case 2: return Color.orange
        case 3: return ColorTheme.error
        default: return ColorTheme.secondaryText
        }
    }
    
    private func urgencyLabel(for level: Int) -> String {
        switch level {
        case 0: return "None"
        case 1: return "Mild"
        case 2: return "Moderate"
        case 3: return "Urgent"
        default: return ""
        }
    }
}

#Preview("Urgency Level") {
    UrgencyLevelInfoView()
}
