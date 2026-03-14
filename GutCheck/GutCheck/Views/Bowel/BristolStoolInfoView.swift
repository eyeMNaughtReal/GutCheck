//
//  BristolStoolInfoView.swift
//  GutCheck
//
//  Information modal view for the Bristol stool scale.
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
                            .foregroundStyle(ColorTheme.primaryText)
                        
                        Text("Select the type that best matches your bowel movement consistency.")
                            .font(.subheadline)
                            .foregroundStyle(ColorTheme.secondaryText)
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
                    .clipShape(.rect(cornerRadius: 12))
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(ColorTheme.primary)
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

#Preview("Bristol Scale") {
    BristolStoolInfoView()
}
