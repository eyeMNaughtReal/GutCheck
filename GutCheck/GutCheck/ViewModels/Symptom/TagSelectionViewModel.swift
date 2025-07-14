//
//  TagSelectionView.swift
//  GutCheck
//
//  Tag selection component with predefined and custom tags
//

import SwiftUI

struct TagSelectionView: View {
    @ObservedObject var viewModel: TagSelectionViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            Text("Tags")
                .font(.headline)
                .foregroundColor(ColorTheme.primaryText)
            
            // Selected tags display
            if viewModel.hasSelectedTags {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.selectedTagsArray, id: \.self) { tag in
                            SelectedTagChip(tag: tag) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.removeTag(tag)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            
            // Predefined tags
            VStack(alignment: .leading, spacing: 8) {
                Text("Common Tags")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 100), spacing: 8)
                ], spacing: 8) {
                    ForEach(viewModel.predefinedTags, id: \.self) { tag in
                        PredefinedTagButton(
                            tag: tag,
                            isSelected: viewModel.isTagSelected(tag)
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.toggleTag(tag)
                            }
                        }
                    }
                }
            }
            
            // Custom tag input
            VStack(alignment: .leading, spacing: 8) {
                Text("Add Custom Tag")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
                
                HStack {
                    TextField("Enter custom tag", text: $viewModel.customTag)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            viewModel.addCustomTag()
                        }
                    
                    Button(action: {
                        viewModel.addCustomTag()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(ColorTheme.primary)
                            .font(.title2)
                    }
                    .disabled(viewModel.customTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct SelectedTagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .foregroundColor(.white)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(ColorTheme.primary)
        )
    }
}

struct PredefinedTagButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.caption)
                .foregroundColor(isSelected ? .white : ColorTheme.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? ColorTheme.primary : ColorTheme.surface)
                )
                .overlay(
                    Capsule()
                        .stroke(ColorTheme.border, lineWidth: isSelected ? 0 : 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isSelected)
    }
}

#Preview {
    VStack {
        TagSelectionView(viewModel: TagSelectionViewModel())
            .padding()
    }
    .background(ColorTheme.background)
}
