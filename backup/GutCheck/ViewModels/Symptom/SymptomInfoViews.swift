// Wrapper for presenting the correct info view
import SwiftUI

// ...existing code...

public struct SymptomInfoViews: View {
    public let infoType: SymptomInfoType
    public init(infoType: SymptomInfoType) {
        self.infoType = infoType
    }
    public var body: some View {
        switch infoType {
        case .bristol:
            BristolStoolInfoView()
        case .pain:
            PainLevelInfoView()
        case .urgency:
            UrgencyLevelInfoView()
        }
    }
}
//
//  SymptomInfoViews.swift
//  GutCheck
//
//  Information modal views for Bristol stool scale, pain levels, and urgency
//  Redesigned for professional medical application
//

import SwiftUI

// MARK: - Bristol Stool Scale Info View

struct BristolStoolInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Medical Classification System")
                            .font(.headline)
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text("Select the type that best matches your bowel movement consistency.")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(ColorTheme.surface)
                    
                    // Color legend
                    HStack(spacing: 20) {
                        LegendItem(color: ColorTheme.success, text: "Ideal")
                        LegendItem(color: ColorTheme.warning, text: "Borderline")
                        LegendItem(color: ColorTheme.error, text: "Problematic")
                    }
                    .padding()
                    .background(ColorTheme.cardBackground)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Detailed guide
                    LazyVStack(spacing: 8) {
                        ForEach(1...7, id: \.self) { type in
                            BristolDetailCard(
                                type: type,
                                title: bristolTitle(for: type),
                                description: bristolDescription(for: type),
                                color: bristolColor(for: type)
                            )
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
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
    

    
    // Helper functions
    private func bristolTitle(for type: Int) -> String {
        switch type {
        case 1: return "Hard lumps"
        case 2: return "Lumpy sausage"
        case 3: return "Cracked sausage"
        case 4: return "Smooth sausage"
        case 5: return "Soft blobs"
        case 6: return "Mushy pieces"
        case 7: return "Watery liquid"
        default: return ""
        }
    }
    
    private func bristolDescription(for type: Int) -> String {
        switch type {
        case 1: return "Separate hard lumps, like nuts. Severe constipation."
        case 2: return "Sausage-shaped but lumpy. Mild constipation."
        case 3: return "Like a sausage with cracks on surface. Borderline normal."
        case 4: return "Like a sausage, smooth and soft. Ideal consistency."
        case 5: return "Soft blobs with clear-cut edges. Borderline normal."
        case 6: return "Fluffy pieces with ragged edges. Mild diarrhea."
        case 7: return "Watery, no solid pieces. Diarrhea."
        default: return ""
        }
    }
    
    private func bristolColor(for type: Int) -> Color {
        switch type {
        case 4: return ColorTheme.success
        case 3, 5: return ColorTheme.warning
        default: return ColorTheme.error
        }
    }
}

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
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text("Rate your abdominal pain, cramping, or discomfort.")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)
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
                                        .foregroundColor(.white)
                                        .frame(width: 40, height: 40)
                                        .background(Circle().fill(painColor(for: level)))
                                    
                                    Text(painLabel(for: level))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(ColorTheme.secondaryText)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.primary)
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
                            .foregroundColor(ColorTheme.primaryText)
                        
                        Text("How urgently did you need to use the bathroom?")
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.secondaryText)
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
                                        .foregroundColor(ColorTheme.secondaryText)
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(ColorTheme.primary)
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

// MARK: - Supporting Views

struct BristolQuickCard: View {
    let type: Int
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text("\(type)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(color))
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(height: 70)
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(ColorTheme.cardBackground)
        .cornerRadius(8)
    }
}

struct BristolDetailCard: View {
    let type: Int
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(type)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(color))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .cornerRadius(8)
    }
}

struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(ColorTheme.secondaryText)
        }
    }
}

struct PainRangeCard: View {
    let range: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Text(range)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 36, height: 28)
                .background(RoundedRectangle(cornerRadius: 6).fill(color))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(ColorTheme.cardBackground)
        .cornerRadius(8)
    }
}

struct UrgencyCard: View {
    let level: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(level)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ColorTheme.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(ColorTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(ColorTheme.cardBackground)
        .cornerRadius(8)
    }
}

#Preview("Bristol Scale") {
    BristolStoolInfoView()
}

#Preview("Pain Level") {
    PainLevelInfoView()
}

#Preview("Urgency Level") {
    UrgencyLevelInfoView()
}
