import SwiftUI

struct SymptomDetailView: View {
    @StateObject private var viewModel: SymptomDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var refreshManager: RefreshManager

    // New initializer that takes a symptom ID
    init(symptomId: String) {
        self._viewModel = StateObject(wrappedValue: SymptomDetailViewModel(symptomId: symptomId))
    }

    // Keep the original initializer for backward compatibility
    init(symptom: Symptom) {
        self._viewModel = StateObject(wrappedValue: SymptomDetailViewModel(entity: symptom))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.entity.id.isEmpty {
                loadingView
            } else {
                contentView
            }
        }
        .onAppear {
            #if DEBUG
            print("🔄 SymptomDetailView: View appeared, symptomId: \(viewModel.symptomId ?? "nil")")
            print("🔄 SymptomDetailView: Current entity ID: \(viewModel.entity.id)")
            print("🔄 SymptomDetailView: Is loading: \(viewModel.isLoading)")
            print("🔄 SymptomDetailView: Entity data - date: \(viewModel.entity.date), stoolType: \(viewModel.entity.stoolType.rawValue)")
            print("🔄 SymptomDetailView: Entity data - painLevel: \(viewModel.entity.painLevel.rawValue), urgencyLevel: \(viewModel.entity.urgencyLevel.rawValue)")
            print("🔄 SymptomDetailView: Entity data - notes: \(viewModel.entity.notes ?? "nil"), tags: \(viewModel.entity.tags)")
            #endif

            if viewModel.symptomId != nil && viewModel.entity.id.isEmpty {
                Task {
                    await viewModel.loadEntity()
                }
            }
        }
        .onChange(of: viewModel.entity) { _, newEntity in
            #if DEBUG
            print("🔄 SymptomDetailView: Entity changed to: \(newEntity.id), date: \(newEntity.date)")
            #endif
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            #if DEBUG
            print("🔄 SymptomDetailView: Loading state changed to: \(isLoading)")
            #endif
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading symptom details...")
                .font(.subheadline)
                .foregroundColor(ColorTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorTheme.background)
    }

    // MARK: - Content View

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                dateHeaderCard
                symptomDetailsCard
                if hasAdditionalInfo {
                    additionalInfoCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 80)
        }
        .background(ColorTheme.background)
        .navigationTitle("Symptom Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                trailingToolbarContent
            }
            ToolbarItem(placement: .navigationBarLeading) {
                leadingToolbarContent
            }
        }
        .alert("Error", isPresented: $viewModel.showingErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "An unknown error occurred")
        }
        .confirmationDialog(
            "Are you sure you want to delete this symptom record?",
            isPresented: $viewModel.showingDeleteConfirmation
        ) {
            deleteConfirmationButton
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }

    // MARK: - Date Header Card

    private var dateHeaderCard: some View {
        HStack(spacing: 16) {
            // Calendar day block
            VStack(spacing: 2) {
                Text(viewModel.entity.date.formatted(.dateTime.month(.abbreviated)).uppercased())
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.primary)
                    .kerning(0.5)
                Text(viewModel.entity.date.formatted(.dateTime.day()))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(ColorTheme.primaryText)
            }
            .frame(width: 58)
            .padding(.vertical, 10)
            .background(ColorTheme.primary.opacity(0.1))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.entity.date.formatted(.dateTime.weekday(.wide)))
                    .font(.headline)
                    .foregroundColor(ColorTheme.primaryText)
                Text(viewModel.entity.date.formatted(.dateTime.month(.wide).day().year()))
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.secondaryText)
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                        .foregroundColor(ColorTheme.tertiaryText)
                    Text(viewModel.entity.date.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundColor(ColorTheme.tertiaryText)
                }
            }

            Spacer()
        }
        .padding(16)
        .background(ColorTheme.surface)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
    }

    // MARK: - Symptom Details Card

    private var symptomDetailsCard: some View {
        VStack(spacing: 0) {
            infoRow(
                icon: "list.bullet.clipboard",
                iconColor: stoolTypeColor,
                label: "Bristol Stool Type",
                trailing: {
                    AnyView(
                        HStack(spacing: 6) {
                            Circle()
                                .fill(stoolTypeColor)
                                .frame(width: 8, height: 8)
                            Text("Type \(viewModel.entity.stoolType.rawValue)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(stoolTypeColor)
                        }
                    )
                }
            )
            cardDivider
            infoRow(
                icon: "bolt.heart.fill",
                iconColor: painLevelColor,
                label: "Pain Level",
                trailing: { AnyView(severityBadge(label: painLevelDescription, color: painLevelColor)) }
            )
            cardDivider
            infoRow(
                icon: "exclamationmark.triangle.fill",
                iconColor: urgencyLevelColor,
                label: "Urgency Level",
                trailing: { AnyView(severityBadge(label: urgencyLevelDescription, color: urgencyLevelColor)) }
            )
        }
        .background(ColorTheme.surface)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
    }

    // MARK: - Additional Info Card

    private var additionalInfoCard: some View {
        VStack(spacing: 0) {
            if let notes = viewModel.entity.notes, !notes.isEmpty {
                notesSection(notes: notes)
                if !viewModel.entity.tags.isEmpty {
                    cardDivider
                }
            }
            if !viewModel.entity.tags.isEmpty {
                tagsSection
            }
        }
        .background(ColorTheme.surface)
        .cornerRadius(12)
        .shadow(color: ColorTheme.shadowColor, radius: 4, x: 0, y: 2)
    }

    // MARK: - Row Builders

    private func infoRow(
        icon: String,
        iconColor: Color,
        label: String,
        trailing: () -> AnyView
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.12))
                .cornerRadius(8)

            Text(label)
                .font(.subheadline)
                .foregroundColor(ColorTheme.primaryText)

            Spacer()

            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "note.text")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ColorTheme.info)
                    .frame(width: 28, height: 28)
                    .background(ColorTheme.info.opacity(0.12))
                    .cornerRadius(8)

                Text("Notes")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primaryText)
            }

            Text(notes)
                .font(.body)
                .foregroundColor(ColorTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 40)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ColorTheme.secondary)
                    .frame(width: 28, height: 28)
                    .background(ColorTheme.secondary.opacity(0.12))
                    .cornerRadius(8)

                Text("Tags")
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.primaryText)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.entity.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(ColorTheme.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(ColorTheme.primary.opacity(0.12))
                            .cornerRadius(20)
                    }
                }
                .padding(.leading, 40)
                .padding(.trailing, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Reusable Sub-views

    private var cardDivider: some View {
        Divider()
            .padding(.leading, 56)
    }

    private func severityBadge(label: String, color: Color) -> some View {
        Text(label)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.15))
            .cornerRadius(20)
    }

    // MARK: - Color Helpers

    private var painLevelColor: Color {
        switch viewModel.entity.painLevel {
        case .none:     return ColorTheme.success
        case .mild:     return ColorTheme.warning
        case .moderate: return .orange
        case .severe:   return ColorTheme.error
        }
    }

    private var urgencyLevelColor: Color {
        switch viewModel.entity.urgencyLevel {
        case .none:     return ColorTheme.success
        case .mild:     return ColorTheme.warning
        case .moderate: return .orange
        case .urgent:   return ColorTheme.error
        }
    }

    private var stoolTypeColor: Color {
        switch viewModel.entity.stoolType {
        case .type1, .type2: return ColorTheme.error    // Hard, constipation
        case .type3, .type4: return ColorTheme.success  // Ideal
        case .type5:         return ColorTheme.warning  // Soft blobs
        case .type6, .type7: return .orange             // Mushy/watery
        }
    }

    // MARK: - Computed Properties

    private var hasAdditionalInfo: Bool {
        let hasNotes = !(viewModel.entity.notes?.isEmpty ?? true)
        return hasNotes || !viewModel.entity.tags.isEmpty
    }

    private var painLevelDescription: String {
        switch viewModel.entity.painLevel {
        case .none:     return "None"
        case .mild:     return "Mild"
        case .moderate: return "Moderate"
        case .severe:   return "Severe"
        }
    }

    private var urgencyLevelDescription: String {
        switch viewModel.entity.urgencyLevel {
        case .none:     return "None"
        case .mild:     return "Mild"
        case .moderate: return "Moderate"
        case .urgent:   return "Urgent"
        }
    }

    // MARK: - Toolbar

    private var trailingToolbarContent: some View {
        HStack {
            if viewModel.isEditing {
                saveButton
            } else {
                editMenu
            }
        }
    }

    private var leadingToolbarContent: some View {
        Group {
            if viewModel.isEditing {
                Button("Cancel") {
                    viewModel.isEditing = false
                }
            }
        }
    }

    private var saveButton: some View {
        Button("Save") {
            Task {
                if await viewModel.saveSymptom() {
                    refreshManager.triggerRefresh()
                }
            }
        }
        .disabled(viewModel.isSaving)
    }

    private var editMenu: some View {
        Menu {
            Button {
                viewModel.isEditing = true
            } label: {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive) {
                viewModel.showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private var deleteConfirmationButton: some View {
        Button("Delete", role: .destructive) {
            Task {
                if await viewModel.deleteSymptom() {
                    refreshManager.triggerRefresh()
                    router.navigateBack()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SymptomDetailView(symptom: Symptom.sampleSymptom())
        .environmentObject(AppRouter.shared)
        .environmentObject(RefreshManager.shared)
}

// Add this if not available elsewhere
extension Symptom {
    static func sampleSymptom() -> Symptom {
        return Symptom(
            id: "sample-id",
            date: Date(),
            stoolType: .type4,
            painLevel: .none,
            urgencyLevel: .none,
            notes: nil,
            tags: [],
            createdBy: ""
        )
    }
}
