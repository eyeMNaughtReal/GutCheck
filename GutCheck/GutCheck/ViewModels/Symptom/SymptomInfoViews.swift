//
//  SymptomInfoViews.swift
//  GutCheck
//
//  Information modal views for Bristol stool scale, pain levels, and urgency
//

import SwiftUI

// MARK: - Bristol Stool Scale Info View

struct BristolStoolInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bristol Stool Scale")
                            .font(.title2.bold())
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text("A medical classification system for human feces. Select the type that best matches your bowel movement.")
                            .font(.body)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    
                    // Types breakdown
                    VStack(spacing: 16) {
                        BristolInfoCard(
                            type: 1,
                            title: "Type 1 - Separate hard lumps",
                            description: "Like nuts, very hard to pass. Indicates severe constipation.",
                            color: ColorTheme.error,
                            severity: "Problematic"
                        )
                        
                        BristolInfoCard(
                            type: 2,
                            title: "Type 2 - Lumpy sausage",
                            description: "Sausage-shaped but lumpy. Indicates mild constipation.",
                            color: ColorTheme.error,
                            severity: "Problematic"
                        )
                        
                        BristolInfoCard(
                            type: 3,
                            title: "Type 3 - Cracked sausage",
                            description: "Like a sausage but with cracks on surface. Borderline normal.",
                            color: ColorTheme.warning,
                            severity: "Borderline"
                        )
                        
                        BristolInfoCard(
                            type: 4,
                            title: "Type 4 - Smooth snake",
                            description: "Like a sausage or snake, smooth and soft. This is ideal!",
                            color: ColorTheme.success,
                            severity: "Ideal"
                        )
                        
                        BristolInfoCard(
                            type: 5,
                            title: "Type 5 - Soft blobs",
                            description: "Soft blobs with clear-cut edges. Borderline normal.",
                            color: ColorTheme.warning,
                            severity: "Borderline"
                        )
                        
                        BristolInfoCard(
                            type: 6,
                            title: "Type 6 - Mushy consistency",
                            description: "Fluffy pieces with ragged edges, mushy. Indicates mild diarrhea.",
                            color: ColorTheme.error,
                            severity: "Problematic"
                        )
                        
                        BristolInfoCard(
                            type: 7,
                            title: "Type 7 - Liquid consistency",
                            description: "Watery, no solid pieces. Indicates diarrhea.",
                            color: ColorTheme.error,
                            severity: "Problematic"
                        )
                    }
                    
                    // Additional info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Understanding the Colors")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        HStack(spacing: 16) {
                            ColorLegendItem(color: ColorTheme.success, title: "Green", subtitle: "Ideal (Type 4)")
                            ColorLegendItem(color: ColorTheme.warning, title: "Yellow", subtitle: "Borderline (Types 3, 5)")
                            ColorLegendItem(color: ColorTheme.error, title: "Red", subtitle: "Problematic (Types 1, 2, 6, 7)")
                        }
                    }
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(12)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Bristol Stool Scale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.primary)
                }
            }
        }
    }
}

struct BristolInfoCard: View {
    let type: Int
    let title: String
    let description: String
    let color: Color
    let severity: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Type number
            Text("\(type)")
                .font(.title.bold())
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(color))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
                
                Text(severity)
                    .font(.caption.bold())
                    .foregroundColor(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
    }
}

struct ColorLegendItem: View {
    let color: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
            
            Text(title)
                .font(.caption.bold())
                .foregroundColor(ColorTheme.primaryText)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pain Level Info View

struct PainLevelInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pain Level Scale")
                            .font(.title2.bold())
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text("Rate your abdominal pain, cramping, or discomfort from 0 to 10.")
                            .font(.body)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    
                    // Pain scale breakdown
                    VStack(spacing: 12) {
                        PainLevelInfoCard(levels: "0", title: "No Pain", description: "No pain or discomfort", color: ColorTheme.success)
                        PainLevelInfoCard(levels: "1-2", title: "Mild Pain", description: "Very light pain, barely noticeable", color: ColorTheme.warning)
                        PainLevelInfoCard(levels: "3-4", title: "Moderate Pain", description: "Noticeable pain that may interfere with daily activities", color: ColorTheme.warning)
                        PainLevelInfoCard(levels: "5-6", title: "Severe Pain", description: "Strong pain that significantly interferes with activities", color: .orange)
                        PainLevelInfoCard(levels: "7-8", title: "Very Severe Pain", description: "Intense pain that dominates your attention", color: ColorTheme.error)
                        PainLevelInfoCard(levels: "9-10", title: "Worst Possible Pain", description: "Unbearable pain, unable to do anything else", color: ColorTheme.error)
                    }
                    
                    // Guidelines
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Guidelines")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)

                        Text("Use your best judgment when rating pain. This helps us correlate symptom severity with potential food or environmental triggers.")
                            .font(.body)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(12)
                Spacer(minLength: 20)
            }
            .padding()
        }
        .navigationTitle("Pain Level Scale")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(ColorTheme.primary)
            }
        }
    }
}
}

struct PainLevelInfoCard: View {
let levels: String
let title: String
let description: String
let color: Color

var body: some View {
    HStack(alignment: .top, spacing: 16) {
        Text(levels)
            .font(.title3.bold())
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(Circle().fill(color))

        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)

            Text(description)
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
        }

        Spacer()
    }
    .padding()
    .background(ColorTheme.cardBackground)
    .cornerRadius(12)
    .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
}
}

struct UrgencyLevelInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Urgency Scale")
                            .font(.title2.bold())
                            .foregroundColor(ColorTheme.primaryText)

                        Text("Describe how urgently you needed to use the bathroom.")
                            .font(.body)
                            .foregroundColor(ColorTheme.secondaryText)
                    }

                    VStack(spacing: 12) {
                        UrgencyInfoCard(level: "0", title: "None", description: "No urgency. Could go later without discomfort.", color: ColorTheme.success)
                        UrgencyInfoCard(level: "1", title: "Mild", description: "Slight urge, could hold it easily.", color: ColorTheme.warning)
                        UrgencyInfoCard(level: "2", title: "Moderate", description: "Noticeable urge, should find a bathroom soon.", color: .orange)
                        UrgencyInfoCard(level: "3", title: "Urgent", description: "Severe urge, needed to go immediately.", color: ColorTheme.error)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Why it matters")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)

                        Text("Tracking urgency helps detect bowel irregularities, potential IBS, or reaction triggers.")
                            .font(.body)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    .padding()
                    .background(ColorTheme.surface)
                    .cornerRadius(12)

                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Urgency Scale")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.primary)
                }
            }
        }
    }
}

struct UrgencyInfoCard: View {
    let level: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(level)
                .font(.title3.bold())
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(color))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
            }

            Spacer()
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 2, x: 0, y: 1)
    }
}

#Preview {
    Group {
        BristolStoolInfoView()
        PainLevelInfoView()
        UrgencyLevelInfoView()
    }
}

