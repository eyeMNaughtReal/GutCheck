//
//  PhotoFoodLoggingView.swift
//  GutCheck
//
//  Photo → identify → look up → confirm portion, as an alternative to typing
//  a food name.
//
//  The review step is the point of this screen. Identification is a
//  suggestion, so every row shows what the photo suggested next to what will
//  actually be logged, and nothing reaches the meal until the person taps Add.
//

import SwiftUI
import PhotosUI

struct PhotoFoodLoggingView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = PhotoFoodLoggingViewModel()
    @State private var pickerItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingCameraDenied = false
    @State private var cameraUnavailable = false

    /// Called when the person wants to type the food in by hand instead.
    /// Every failure path routes here rather than dead-ending.
    var onManualEntry: () -> Void

    var body: some View {
        NavigationStack {
            content
                .background(ColorTheme.background)
                .navigationTitle("Identify from Photo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
        }
        .task(id: pickerItem) {
            guard let pickerItem,
                  let data = try? await pickerItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else { return }
            await viewModel.analyze(image)
        }
        .sheet(isPresented: $showingCamera) {
            CameraCaptureView { image in
                Task { await viewModel.analyze(image) }
            }
            .ignoresSafeArea()
        }
        .alert("Camera Access Needed", isPresented: $showingCameraDenied) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Choose a Photo Instead", role: .cancel) {}
        } message: {
            Text("GutCheck needs camera access to photograph your plate. You can turn it on in Settings, or pick an existing photo.")
        }
        .alert("No Camera Available", isPresented: $cameraUnavailable) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This device has no camera available. Choose an existing photo instead.")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .choosingPhoto:
            chooserView
        case .analyzing:
            analyzingView
        case .reviewing:
            reviewView
        case .failed(let message):
            failureView(message)
        }
    }

    // MARK: - Choose a photo

    private var chooserView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 72))
                .foregroundStyle(ColorTheme.accent)

            Text("Photograph your plate")
                .font(.title2.bold())
                .foregroundStyle(ColorTheme.primaryText)

            Text("GutCheck names the foods it recognises, then looks each one up so the nutrition comes from the database rather than a guess. You choose the portion.")
                .typography(Typography.body)
                .foregroundStyle(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            if !viewModel.isIdentificationAvailable {
                Label(
                    "Photo identification isn't available on this device. You can still add foods yourself.",
                    systemImage: "exclamationmark.triangle"
                )
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    // Ask before presenting. Without this the picker is shown
                    // regardless and renders black when camera access has not
                    // been granted, which looks like a broken camera rather
                    // than a permission problem.
                    Task {
                        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                            cameraUnavailable = true
                            return
                        }
                        if await PermissionManager.shared.requestCameraPermission() {
                            showingCamera = true
                        } else {
                            showingCameraDenied = true
                        }
                    }
                } label: {
                    Label("Take a Photo", systemImage: "camera")
                        .typography(Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 12))
                }
                .disabled(!viewModel.isIdentificationAvailable)
                .accessibilityIdentifier("photoLogging.camera.button")

                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Choose an Existing Photo", systemImage: "photo.on.rectangle")
                        .typography(Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.surface)
                        .foregroundStyle(ColorTheme.primaryText)
                        .clipShape(.rect(cornerRadius: 12))
                }
                .disabled(!viewModel.isIdentificationAvailable)
                .accessibilityIdentifier("photoLogging.library.button")

                Button("Add Foods Manually") {
                    onManualEntry()
                    dismiss()
                }
                .typography(Typography.body)
                .foregroundStyle(ColorTheme.accent)
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Analyzing

    private var analyzingView: some View {
        VStack(spacing: 20) {
            Spacer()

            if let image = viewModel.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 180, height: 180)
                    .clipShape(.rect(cornerRadius: 16))
            }

            ProgressView()
            Text("Identifying foods…")
                .typography(Typography.body)
                .foregroundStyle(ColorTheme.secondaryText)

            Spacer()
        }
        .accessibilityIdentifier("photoLogging.analyzing")
    }

    // MARK: - Review

    private var reviewView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let image = viewModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .clipped()
                            .clipShape(.rect(cornerRadius: 12))
                    }

                    Text("Check these before adding them. Nutrition comes from the database entry you pick, not from the photo.")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)

                    ForEach(viewModel.candidates) { candidate in
                        CandidateRow(candidate: candidate, viewModel: viewModel)
                    }

                    if viewModel.needsSeasoningInput {
                        seasoningSection
                    }
                }
                .padding(20)
            }

            addBar
        }
        .accessibilityIdentifier("photoLogging.review")
    }

    private var seasoningSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Seasoning or sauce", systemImage: "sparkles")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            Text("There looks to be seasoning or sauce here, but it can't be identified from a photo. Add it if you know what it was — spices are common triggers.")
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)

            TextField("e.g. cayenne, garlic powder, soy sauce", text: $viewModel.seasoningText, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(12)
                .background(ColorTheme.cardBackground)
                .clipShape(.rect(cornerRadius: 10))
                .accessibilityIdentifier("photoLogging.seasoning.field")
        }
        .padding(16)
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }

    private var addBar: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.addToMeal()
                dismiss()
            } label: {
                Text(addButtonTitle)
                    .typography(Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canAddToMeal ? ColorTheme.accent : ColorTheme.surface)
                    .foregroundStyle(viewModel.canAddToMeal ? .white : ColorTheme.secondaryText)
                    .clipShape(.rect(cornerRadius: 12))
            }
            .disabled(!viewModel.canAddToMeal)
            .accessibilityIdentifier("photoLogging.add.button")

            Button("Retake Photo") { viewModel.reset() }
                .typography(Typography.body)
                .foregroundStyle(ColorTheme.accent)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(ColorTheme.background)
    }

    private var addButtonTitle: String {
        let count = viewModel.itemsToAdd.count
        return count == 1 ? "Add 1 Item to Meal" : "Add \(count) Items to Meal"
    }

    // MARK: - Failure

    private func failureView(_ message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "questionmark.diamond")
                .font(.system(size: 64))
                .foregroundStyle(ColorTheme.secondaryText)

            Text("Couldn't identify this plate")
                .font(.title3.bold())
                .foregroundStyle(ColorTheme.primaryText)

            Text(message)
                .typography(Typography.body)
                .foregroundStyle(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    onManualEntry()
                    dismiss()
                } label: {
                    Text("Add Foods Manually")
                        .typography(Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 12))
                }
                .accessibilityIdentifier("photoLogging.manual.button")

                Button("Try Another Photo") { viewModel.reset() }
                    .typography(Typography.body)
                    .foregroundStyle(ColorTheme.accent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .accessibilityIdentifier("photoLogging.failed")
    }
}

// MARK: - Candidate Row

private struct CandidateRow: View {

    @Bindable var candidate: PhotoFoodCandidate
    let viewModel: PhotoFoodLoggingViewModel

    @State private var isEditingName = false
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Toggle(isOn: $candidate.isIncluded) {
                    Text(candidate.searchName.capitalized)
                        .typography(Typography.headline)
                        .foregroundStyle(ColorTheme.primaryText)
                }
                .toggleStyle(.switch)
            }

            if candidate.nameWasCorrected {
                Text("Photo suggested “\(candidate.identifiedName)”")
                    .typography(Typography.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
            }

            // Correcting the name is the only way out of a wrong
            // identification: the match list below can only ever offer
            // variations of whatever was named.
            if isEditingName {
                HStack(spacing: 8) {
                    TextField("What is it?", text: $candidate.searchName)
                        .textFieldStyle(.plain)
                        .focused($nameFieldFocused)
                        .submitLabel(.search)
                        .onSubmit { search() }
                        .padding(10)
                        .background(ColorTheme.cardBackground)
                        .clipShape(.rect(cornerRadius: 8))
                        .accessibilityIdentifier("photoLogging.candidate.nameField")

                    Button("Search") { search() }
                        .typography(Typography.body)
                        .foregroundStyle(ColorTheme.accent)
                }
            } else {
                Button {
                    isEditingName = true
                    nameFieldFocused = true
                } label: {
                    Label("Not right? Rename and search", systemImage: "pencil")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.accent)
                }
                .accessibilityIdentifier("photoLogging.candidate.rename")
            }

            // The portion hint, stated as an impression. It has already
            // preselected a serving below; showing it explains why.
            Label(candidate.portionHint.label, systemImage: "ruler")
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)

            switch candidate.lookupState {
            case .pending, .searching:
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Looking up nutrition…")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                }

            case .matched:
                if let item = candidate.selectedItem {
                    VStack(alignment: .leading, spacing: 4) {
                        if candidate.matchDiffersFromIdentification {
                            Text("Logging as \(item.name)")
                                .typography(Typography.caption)
                                .foregroundStyle(ColorTheme.secondaryText)
                        }
                        Text(item.quantity)
                            .typography(Typography.body)
                            .foregroundStyle(ColorTheme.primaryText)
                    }

                    if candidate.matches.count > 1 {
                        Picker("Database match", selection: matchSelection) {
                            ForEach(Array(candidate.matches.enumerated()), id: \.offset) { index, match in
                                Text(match.name).tag(index)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(ColorTheme.accent)
                    }
                }

            case .noMatch:
                Text("No database match for “\(candidate.searchName)”. Try a simpler name, like the main ingredient.")
                    .typography(Typography.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
            }
        }
        .padding(16)
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .opacity(candidate.isIncluded ? 1 : 0.5)
    }

    private func search() {
        nameFieldFocused = false
        isEditingName = false
        Task { await viewModel.lookUp(candidate) }
    }

    /// Bridges the menu's index selection to the view model's setter so the
    /// portion hint is reapplied whenever the match changes.
    private var matchSelection: Binding<Int> {
        Binding(
            get: {
                guard let selected = candidate.selectedItem else { return 0 }
                return candidate.matches.firstIndex { $0.name == selected.name } ?? 0
            },
            set: { index in
                guard candidate.matches.indices.contains(index) else { return }
                viewModel.select(candidate.matches[index], for: candidate)
            }
        )
    }
}

// MARK: - Camera

/// Minimal camera capture.
///
/// SwiftUI has no native still-camera picker, so this is the one place a
/// representable is unavoidable. It returns a single image and dismisses.
private struct CameraCaptureView: UIViewControllerRepresentable {

    let onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCapture: onCapture, onFinish: { dismiss() })
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

        private let onCapture: (UIImage) -> Void
        private let onFinish: () -> Void

        init(onCapture: @escaping (UIImage) -> Void, onFinish: @escaping () -> Void) {
            self.onCapture = onCapture
            self.onFinish = onFinish
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            onFinish()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onFinish()
        }
    }
}
