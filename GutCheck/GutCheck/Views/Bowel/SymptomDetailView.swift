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
            if viewModel.isLoading {
                loadingView
            } else {
                contentView
            }
        }
        .onAppear {
            if viewModel.symptomId != nil {
                Task {
                    await viewModel.loadEntity()
                }
            }
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
                router.navigateBack()
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
            
            // Additional symptom fields can be added here
            // painLevelRow
            // urgencyLevelRow
            // notesRow
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