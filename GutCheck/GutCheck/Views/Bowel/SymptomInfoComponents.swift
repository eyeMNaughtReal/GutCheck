//
//  SymptomInfoComponents.swift
//  GutCheck
//
//  Supporting view components for symptom info views.
//

import SwiftUI

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
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(Circle().fill(color))
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(height: 70)
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(ColorTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 8))
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
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(color))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorTheme.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(ColorTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 8))
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
                .foregroundStyle(ColorTheme.secondaryText)
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
                .foregroundStyle(.white)
                .frame(width: 36, height: 28)
                .background(RoundedRectangle(cornerRadius: 6).fill(color))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(ColorTheme.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(ColorTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 8))
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
                    .foregroundStyle(ColorTheme.primaryText)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(ColorTheme.cardBackground)
        .clipShape(.rect(cornerRadius: 8))
    }
}
