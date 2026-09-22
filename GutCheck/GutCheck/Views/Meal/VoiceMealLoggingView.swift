//
//  VoiceMealLoggingView.swift
//  GutCheck
//
//  Speak → transcribe → extract → clarify → confirm, as an alternative to
//  typing a food name.
//
//  The clarify step is the point of this screen. Speech leaves specific,
//  nameable gaps — which bread, how much of the bag — and every one of them is
//  answered here with a control, not with a spoken follow-up question. Nothing
//  reaches the meal until the person taps Add.
//

import SwiftUI

struct VoiceMealLoggingView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = VoiceMealLoggingViewModel()

    /// Called when the person wants to type the food in by hand instead.
    /// Every failure path routes here rather than dead-ending.
    var onManualEntry: () -> Void

    var body: some View {
        NavigationStack {
            content
                .background(ColorTheme.background)
                .navigationTitle("Speak Your Meal")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            Task {
                                await viewModel.cancelRecording()
                                dismiss()
                            }
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.phase {
        case .ready:
            readyView
        case .recording:
            recordingView
        case .extracting:
            extractingView
        case .reviewing:
            reviewView
        case .failed(let message):
            failureView(message)
        }
    }

    // MARK: - Ready

    private var readyView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "waveform")
                .font(.system(size: 72))
                .foregroundStyle(ColorTheme.accent)
                .accessibilityHidden(true)

            Text("Say what you ate")
                .font(.title2.bold())
                .foregroundStyle(ColorTheme.primaryText)

            Text("Describe the whole meal in one go — brands, sizes and how much you actually had. GutCheck looks each food up, then asks about anything you didn't say.")
                .typography(Typography.body)
                .foregroundStyle(ColorTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Text("“For lunch I had half a 20oz Coke and a turkey sandwich with mayo”")
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
                .italic()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if !viewModel.isExtractionAvailable {
                Label(
                    "Reading a spoken meal isn't available on this device. You can still add foods yourself.",
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
                    HapticManager.shared.medium()
                    Task { await viewModel.startRecording() }
                } label: {
                    Label("Start Recording", systemImage: "mic.fill")
                        .typography(Typography.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(ColorTheme.accent)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 12))
                }
                .disabled(!viewModel.isExtractionAvailable)
                .accessibilityIdentifier("voiceLogging.record.button")

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

    // MARK: - Recording

    private var recordingView: some View {
        VStack(spacing: 20) {
            Spacer()

            // Pulses only while speech is actually being heard, so a dead
            // microphone looks different from a quiet room.
            Image(systemName: "waveform")
                .font(.system(size: 64))
                .foregroundStyle(viewModel.capture.hasHeardSpeech ? ColorTheme.accent : ColorTheme.secondaryText)
                .symbolEffect(.variableColor.iterative, isActive: viewModel.capture.hasHeardSpeech)
                .accessibilityHidden(true)

            if viewModel.capture.isPreparingAssets {
                ProgressView()
                Text("Getting speech files ready…")
                    .typography(Typography.body)
                    .foregroundStyle(ColorTheme.secondaryText)
            } else {
                Text(viewModel.capture.hasHeardSpeech ? "Listening…" : "Go ahead — I'm listening")
                    .typography(Typography.body)
                    .foregroundStyle(ColorTheme.secondaryText)
            }

            // Shown as it firms up. Watching the words appear is what tells
            // someone they are being heard correctly, and it is much cheaper
            // to stop and start again than to discover a misheard brand at
            // the review step.
            ScrollView {
                Text(viewModel.capture.liveTranscript)
                    .typography(Typography.body)
                    .foregroundStyle(ColorTheme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            }
            .frame(maxHeight: 220)
            .background(ColorTheme.surface)
            .clipShape(.rect(cornerRadius: 12))
            .padding(.horizontal, 20)
            .accessibilityIdentifier("voiceLogging.transcript")

            Spacer()

            Button {
                HapticManager.shared.medium()
                Task { await viewModel.stopRecordingAndExtract() }
            } label: {
                Label("Done", systemImage: "stop.fill")
                    .typography(Typography.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ColorTheme.accent)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .accessibilityIdentifier("voiceLogging.stop.button")
        }
    }

    // MARK: - Extracting

    private var extractingView: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
            Text("Picking out the foods…")
                .typography(Typography.body)
                .foregroundStyle(ColorTheme.secondaryText)
            Spacer()
        }
        .accessibilityIdentifier("voiceLogging.extracting")
    }

    // MARK: - Review

    private var reviewView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    transcriptSection

                    if viewModel.unresolvedCount > 0 {
                        Label(
                            viewModel.unresolvedCount == 1
                                ? "1 thing you didn't say — answer it or leave the default."
                                : "\(viewModel.unresolvedCount) things you didn't say — answer them or leave the defaults.",
                            systemImage: "questionmark.circle"
                        )
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.secondaryText)
                    }

                    mealSection

                    ForEach(viewModel.candidates) { candidate in
                        SpokenCandidateRow(candidate: candidate, viewModel: viewModel)
                    }
                }
                .padding(20)
            }

            addBar
        }
        .accessibilityIdentifier("voiceLogging.review")
    }

    /// The transcript, editable.
    ///
    /// A misheard word is the most likely failure of the whole flow, and
    /// fixing it as text then re-extracting is far less work than saying the
    /// entire meal again.
    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("What I heard", systemImage: "quote.opening")
                .typography(Typography.headline)
                .foregroundStyle(ColorTheme.primaryText)

            TextField("What you said", text: $viewModel.transcript, axis: .vertical)
                .textFieldStyle(.plain)
                .typography(Typography.body)
                .padding(12)
                .background(ColorTheme.cardBackground)
                .clipShape(.rect(cornerRadius: 10))
                .accessibilityIdentifier("voiceLogging.transcript.field")

            Button {
                Task { await viewModel.extract() }
            } label: {
                Label("Fix a word and read it again", systemImage: "arrow.clockwise")
                    .typography(Typography.caption)
                    .foregroundStyle(ColorTheme.accent)
            }
            .accessibilityIdentifier("voiceLogging.reextract.button")
        }
        .padding(16)
        .background(ColorTheme.surface)
        .clipShape(.rect(cornerRadius: 12))
    }

    /// Meal type and time, with the assumption stated when there was one.
    private var mealSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let mealType = viewModel.mealType {
                Label("Logging as \(mealType.rawValue.capitalized)", systemImage: "fork.knife")
                    .typography(Typography.subheadline)
                    .foregroundStyle(ColorTheme.primaryText)
            }

            // Stated rather than silently applied. "For lunch" is a window,
            // not an instant, and a meal stamped with the wrong hour falls
            // outside the window symptom correlation looks at.
            if viewModel.mealTimeWasAssumed {
                Text("You didn't say a time, so this is set to now. Change it if that's wrong.")
                    .typography(Typography.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
            }

            DatePicker(
                "When",
                selection: $viewModel.mealDate,
                in: ...Date.now,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .accessibilityIdentifier("voiceLogging.date")
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
            .accessibilityIdentifier("voiceLogging.add.button")

            Button("Say It Again") { viewModel.reset() }
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
                .accessibilityHidden(true)

            Text("Couldn't read that as a meal")
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
                .accessibilityIdentifier("voiceLogging.manual.button")

                Button("Try Again") { viewModel.reset() }
                    .typography(Typography.body)
                    .foregroundStyle(ColorTheme.accent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .accessibilityIdentifier("voiceLogging.failed")
    }
}

// MARK: - Candidate Row

private struct SpokenCandidateRow: View {

    @Bindable var candidate: SpokenFoodCandidate
    let viewModel: VoiceMealLoggingViewModel

    @State private var isEditingName = false
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $candidate.isIncluded) {
                Text(candidate.searchName.capitalized)
                    .typography(Typography.headline)
                    .foregroundStyle(ColorTheme.primaryText)
            }
            .toggleStyle(.switch)

            // The open question, stated before the controls that answer it.
            if let prompt = candidate.clarificationPrompt {
                Label(prompt, systemImage: "questionmark.circle.fill")
                    .typography(Typography.subheadline)
                    .foregroundStyle(ColorTheme.accent)
            }

            if candidate.nameWasCorrected {
                Text("You said “\(candidate.spokenName)”")
                    .typography(Typography.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
            }

            // Correcting the name is the only way out of a misheard food: the
            // match list below can only ever offer variations of whatever was
            // transcribed.
            if isEditingName {
                HStack(spacing: 8) {
                    TextField("What was it?", text: $candidate.searchName)
                        .textFieldStyle(.plain)
                        .focused($nameFieldFocused)
                        .submitLabel(.search)
                        .onSubmit { search() }
                        .padding(10)
                        .background(ColorTheme.cardBackground)
                        .clipShape(.rect(cornerRadius: 8))
                        .accessibilityIdentifier("voiceLogging.candidate.nameField")

                    Button("Search") { search() }
                        .typography(Typography.body)
                        .foregroundStyle(ColorTheme.accent)
                }
            } else {
                Button {
                    isEditingName = true
                    nameFieldFocused = true
                } label: {
                    Label("Misheard? Rename and search", systemImage: "pencil")
                        .typography(Typography.caption)
                        .foregroundStyle(ColorTheme.accent)
                }
                .accessibilityIdentifier("voiceLogging.candidate.rename")
            }

            amountLine

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
                        if candidate.matchDiffersFromSpeech {
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
                        .accessibilityIdentifier("voiceLogging.candidate.match")
                    }

                    // Only offered when the amount is genuinely open. With a
                    // spoken measurement the count is already right, and a
                    // stepper next to it would invite someone to overwrite
                    // what they just said.
                    if candidate.needsAmountAnswer, item.selectedServing != nil {
                        servingStepper(for: item)
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

    /// What the speaker said about the amount, and what was done with it.
    @ViewBuilder
    private var amountLine: some View {
        switch candidate.amountCertainty {
        case .stated:
            if let spoken = candidate.statedAmount {
                Label("You said “\(spoken)”", systemImage: "checkmark.circle")
                    .typography(Typography.caption)
                    .foregroundStyle(ColorTheme.secondaryText)
            }

        case .vague:
            // Named but not converted. Turning "a couple handfuls" into a
            // gram weight here would put a fabricated portion into the
            // trigger analysis, which is worse than an unanswered question.
            Label(
                "“\(candidate.statedAmount ?? "That")” isn't a measurement, so this is a normal serving until you change it.",
                systemImage: "questionmark.circle"
            )
            .typography(Typography.caption)
            .foregroundStyle(ColorTheme.secondaryText)

        case .unstated:
            Label(candidate.portionHint.label, systemImage: "ruler")
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
        }
    }

    /// Scales the chosen database serving. Never invents a weight of its own —
    /// it multiplies a portion the source published.
    private func servingStepper(for item: FoodItem) -> some View {
        Stepper(
            value: Binding(
                get: { item.servingCount ?? 1 },
                set: { viewModel.setServingCount($0, for: candidate) }
            ),
            in: 0.25...20,
            step: 0.25
        ) {
            Text("How many servings")
                .typography(Typography.caption)
                .foregroundStyle(ColorTheme.secondaryText)
        }
        .accessibilityIdentifier("voiceLogging.candidate.servings")
    }

    private func search() {
        nameFieldFocused = false
        isEditingName = false
        Task { await viewModel.lookUp(candidate) }
    }

    /// Bridges the menu's index selection to the view model's setter so the
    /// spoken portion is reapplied whenever the match changes.
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
