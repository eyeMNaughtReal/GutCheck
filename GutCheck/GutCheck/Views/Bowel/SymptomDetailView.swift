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
            print("🔄 SymptomDetailView: View appeared, symptomId: \(viewModel.symptomId ?? "nil")")
            print("🔄 SymptomDetailView: Current entity ID: \(viewModel.entity.id)")
            print("🔄 SymptomDetailView: Is loading: \(viewModel.isLoading)")
            print("🔄 SymptomDetailView: View frame: \(UIScreen.main.bounds)")
            print("🔄 SymptomDetailView: Entity data - date: \(viewModel.entity.date), stoolType: \(viewModel.entity.stoolType.rawValue)")
            print("🔄 SymptomDetailView: Entity data - painLevel: \(viewModel.entity.painLevel.rawValue), urgencyLevel: \(viewModel.entity.urgencyLevel.rawValue)")
            print("🔄 SymptomDetailView: Entity data - notes: \(viewModel.entity.notes ?? "nil"), tags: \(viewModel.entity.tags)")
            
            if viewModel.symptomId != nil && viewModel.entity.id.isEmpty {
                Task {
                    await viewModel.loadEntity()
                }
            }
        }
        .onChange(of: viewModel.entity) { _, newEntity in
            print("🔄 SymptomDetailView: Entity changed to: \(newEntity.id), date: \(newEntity.date)")
        }
        .onChange(of: viewModel.isLoading) { _, isLoading in
            print("🔄 SymptomDetailView: Loading state changed to: \(isLoading)")
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView("Loading symptom details...")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView
                symptomInformationView
            }
            .padding(.bottom, 80)
        }
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
                // When presented as a sheet, dismiss the sheet instead of navigating back
                dismiss()
            }
        }
    }
    
    private var headerView: some View {
        Text(viewModel.isEditing ? "Edit Symptom" : "Symptom Detail")
            .font(.title)
            .padding(.top)
    }
    
    private var symptomInformationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            dateRow
            stoolTypeRow
            painLevelRow
            urgencyLevelRow
            notesRow
            tagsRow
        }
        .padding(.horizontal)
    }
    
    private var dateRow: some View {
        HStack {
            Text("Date:")
                .font(.headline)
            Spacer()
            Text(viewModel.entity.date.formatted(.dateTime.month().day().year()))
                .font(.body)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var stoolTypeRow: some View {
        HStack {
            Text("Bristol Stool Type:")
                .font(.headline)
            Spacer()
            Text("Type \(viewModel.entity.stoolType.rawValue)")
                .font(.body)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var painLevelRow: some View {
        HStack {
            Text("Pain Level:")
                .font(.headline)
            Spacer()
            Text(painLevelDescription)
                .font(.body)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var urgencyLevelRow: some View {
        HStack {
            Text("Urgency Level:")
                .font(.headline)
            Spacer()
            Text(urgencyLevelDescription)
                .font(.body)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var notesRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes:")
                .font(.headline)
            if let notes = viewModel.entity.notes, !notes.isEmpty {
                Text(notes)
                    .font(.body)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                Text("No notes")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
    }
    
    private var tagsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags:")
                .font(.headline)
            if !viewModel.entity.tags.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(viewModel.entity.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(12)
                    }
                }
            } else {
                Text("No tags")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Computed Properties
    
    private var painLevelDescription: String {
        switch viewModel.entity.painLevel {
        case .none: return "None"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .severe: return "Severe"
        }
    }
    
    private var urgencyLevelDescription: String {
        switch viewModel.entity.urgencyLevel {
        case .none: return "None"
        case .mild: return "Mild"
        case .moderate: return "Moderate"
        case .urgent: return "Urgent"
        }
    }
    
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