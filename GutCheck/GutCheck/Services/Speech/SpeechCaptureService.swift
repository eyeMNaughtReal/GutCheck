//
//  SpeechCaptureService.swift
//  GutCheck
//
//  Turns spoken audio into a transcript, on device.
//
//  Scope, deliberately narrow — read before extending:
//
//  This service produces TEXT. It does not know what a food is, and it never
//  looks anything up. Understanding the transcript is
//  SpokenMealExtractionService's job, and nutrition comes from a real database
//  lookup after that. The split mirrors FoodPhotoIdentificationService, for the
//  same reason: a transcription error and a lookup error need different
//  recovery, and blending the two hides which one happened.
//
//  Nothing leaves the device. `SpeechTranscriber` runs against locally
//  installed assets, and the audio buffers are never written to disk or sent
//  anywhere. A voice recording of someone describing their symptoms and diet is
//  about as sensitive as this app gets, so the recording exists only as
//  in-memory buffers for as long as the analyzer needs them.
//

import Foundation
import AVFoundation
import Speech

// MARK: - Result

/// Why capture could not start, phrased for the person rather than the log.
enum SpeechCaptureUnavailableReason: Equatable {

    /// Microphone access was refused. Recoverable in Settings.
    case microphoneDenied

    /// The device locale has no `SpeechTranscriber` support.
    case localeNotSupported

    /// Assets are not installed and could not be downloaded.
    case assetsUnavailable

    /// The audio session or engine refused to start.
    case audioUnavailable

    var message: String {
        switch self {
        case .microphoneDenied:
            "GutCheck needs microphone access to hear your meal. You can turn it on in Settings, or add the foods yourself."
        case .localeNotSupported:
            "Speaking a meal isn't supported in this language yet. You can still add foods yourself."
        case .assetsUnavailable:
            "The speech files couldn't be downloaded. Check your connection and try again, or add the foods yourself."
        case .audioUnavailable:
            "The microphone couldn't be started. Close anything else using it and try again, or add the foods yourself."
        }
    }
}

// MARK: - Service

/// Records speech and reports the transcript as it firms up.
///
/// One capture at a time. `SpeechAnalyzer` analyses a single input sequence, so
/// starting a second run before the first finishes is a programming error
/// rather than a supported case.
@MainActor
@Observable final class SpeechCaptureService {

    // MARK: Observable state

    /// True between `start()` and `stop()`.
    private(set) var isRecording = false

    /// Best transcript so far.
    ///
    /// Updated continuously while recording. Early results are volatile — the
    /// transcriber revises them as more audio arrives — so this is for showing
    /// the person that they are being heard, not for extraction. Use the value
    /// `stop()` returns for that.
    private(set) var liveTranscript: String = ""

    /// True once `SpeechDetector` has heard actual voice activity.
    ///
    /// Distinguishes "recording, but silent" from "recording and hearing you",
    /// which is the difference between a broken mic and a person who has not
    /// started talking yet.
    private(set) var hasHeardSpeech = false

    /// Set while first-run assets download, so the UI can say why nothing is
    /// happening instead of appearing hung.
    private(set) var isPreparingAssets = false

    // MARK: Internals

    private let audioEngine = AVAudioEngine()

    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var resultsTask: Task<Void, Never>?
    private var analysisTask: Task<Void, Never>?

    /// Accumulated finalized text. Kept apart from the volatile tail so a
    /// revision of the current phrase cannot corrupt phrases already settled.
    private var finalizedText: String = ""

    // MARK: - Availability

    /// Whether this locale can be transcribed at all.
    ///
    /// Worth checking before offering the affordance: an unsupported locale is
    /// a permanent no, not a retryable failure.
    static func isLocaleSupported() async -> Bool {
        await SpeechTranscriber.supportedLocale(equivalentTo: Locale.current) != nil
    }

    // MARK: - Vocabulary biasing

    /// Terms the transcriber would otherwise mangle.
    ///
    /// This is the concrete fix for "Lay's" coming back as "lace" or "lays".
    /// Brand names are exactly the words a general dictation model has least
    /// reason to favour, and they are also the words that decide whether a
    /// database lookup finds the right record — a misheard brand does not
    /// degrade the match, it destroys it.
    ///
    /// Apple caps the useful list at about 100 phrases and asks for one or two
    /// words each, so this is a deliberately short list of common brands and
    /// the portion words that carry quantity, not an attempt at a food
    /// dictionary.
    private static let contextualTerms: [String] = [
        // Brands whose names are ordinary words, and so are the ones that get
        // transcribed as the ordinary word.
        "Lay's", "Coca-Cola", "Diet Coke", "Pepsi", "Sprite", "Dr Pepper",
        "Doritos", "Cheetos", "Pringles", "Ritz", "Oreo", "Goldfish",
        "Chick-fil-A", "Taco Bell", "McDonald's", "Wendy's", "Subway",
        "Chipotle", "Panera", "Starbucks", "Dunkin", "Five Guys",
        "In-N-Out", "Popeyes", "Arby's", "Sonic", "Whataburger",
        "Quaker", "Kellogg's", "Cheerios", "Nutella", "Skippy", "Jif",
        "Hellmann's", "Heinz", "Sriracha", "Tabasco", "Chobani", "Yoplait",
        "Gatorade", "Red Bull", "Monter", "Snapple", "Tropicana",

        // Quantity language. "Fluid ounce" and "tablespoon" are the words that
        // turn a vague portion into a real one, so they are worth biasing.
        "fluid ounce", "ounces", "tablespoon", "teaspoon", "handful",
        "handfuls", "slice", "slices", "scoop", "serving", "servings",

        // Foods from the issue's own example sentence, which is the first
        // thing anyone will try.
        "sour cream and onion", "turkey", "mayo", "mayonnaise",
        "sourdough", "rye", "whole wheat", "provolone", "cheddar", "swiss",
    ]

    // MARK: - Start

    /// Begins recording and transcribing.
    ///
    /// Returns the reason on failure rather than throwing, so every call site
    /// has a message to show and a path to manual entry.
    func start() async -> SpeechCaptureUnavailableReason? {
        guard !isRecording else { return nil }

        guard await requestMicrophoneAccess() else {
            return .microphoneDenied
        }

        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale.current) else {
            return .localeNotSupported
        }

        reset()

        // `.progressiveTranscription` rather than `.transcription`: the person
        // is watching their words appear, and a screen that stays empty until
        // they stop talking reads as a mic that is not working.
        let transcriber = SpeechTranscriber(locale: locale, preset: .progressiveTranscription)
        let detector = SpeechDetector()

        // First run on a locale may need the model downloaded. Surfacing this
        // matters — without it the screen simply sits there, and the natural
        // reading is that the app is broken rather than busy.
        do {
            if let request = try await AssetInventory.assetInstallationRequest(
                supporting: [transcriber, detector]
            ) {
                isPreparingAssets = true
                try await request.downloadAndInstall()
                isPreparingAssets = false
            }
        } catch {
            isPreparingAssets = false
            return .assetsUnavailable
        }

        // A nil format means the modules still want assets that are not
        // installed, which is the same dead end as a failed download.
        guard let audioFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [detector, transcriber]
        ) else {
            return .assetsUnavailable
        }

        // Bias toward brand and food vocabulary before any audio arrives.
        let context = AnalysisContext()
        context.contextualStrings = [.general: Self.contextualTerms]

        let analyzer = SpeechAnalyzer(modules: [detector, transcriber])
        try? await analyzer.setContext(context)

        let (inputSequence, inputBuilder) = AsyncStream.makeStream(of: AnalyzerInput.self)

        self.transcriber = transcriber
        self.analyzer = analyzer
        self.inputBuilder = inputBuilder

        do {
            try startAudioEngine(convertingTo: audioFormat, into: inputBuilder)
        } catch {
            await teardown()
            return .audioUnavailable
        }

        observeResults(from: transcriber)

        analysisTask = Task { [weak self] in
            // A thrown error here means the analyzer stopped early. The
            // transcript gathered so far is still the best answer available,
            // so this does not discard it.
            let lastSampleTime = try? await analyzer.analyzeSequence(inputSequence)
            guard let self else { return }
            await self.finish(through: lastSampleTime)
        }

        isRecording = true
        return nil
    }

    // MARK: - Stop

    /// Ends recording and returns the settled transcript.
    ///
    /// Waits for the analyzer to finalize rather than returning `liveTranscript`
    /// immediately. The tail of a phrase is the part most likely to still be
    /// provisional, and the tail of a spoken meal is usually a food — cutting
    /// it early loses the last item.
    @discardableResult
    func stop() async -> String {
        guard isRecording else { return finalizedText }

        isRecording = false

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        inputBuilder?.finish()

        // Let `analyzeSequence` drain and `finish(through:)` run.
        await analysisTask?.value
        resultsTask?.cancel()

        deactivateAudioSession()

        let transcript = finalizedText.trimmingCharacters(in: .whitespacesAndNewlines)
        liveTranscript = transcript
        return transcript
    }

    /// Abandons a capture without using the transcript.
    func cancel() async {
        guard isRecording else { return }
        _ = await stop()
        reset()
    }

    // MARK: - Audio

    /// Taps the microphone and feeds converted buffers to the analyzer.
    private func startAudioEngine(
        convertingTo analyzerFormat: AVAudioFormat,
        into builder: AsyncStream<AnalyzerInput>.Continuation
    ) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let converter = AnalyzerInputConverter(analyzerFormat: analyzerFormat)

        // Buffer size is the framework's business, so the tap asks for the
        // input node's own format and lets the converter reconcile it.
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { buffer, _ in
            guard let inputs = try? converter.convert(buffer, at: nil) else { return }
            for input in inputs {
                builder.yield(input)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Results

    /// Accumulates transcriber output.
    ///
    /// Finalized results are appended and never revisited; the volatile result
    /// is shown appended to them but not stored. Treating both the same way
    /// made the live text stutter, because a revision of the current phrase
    /// rewrote text the person had already watched settle.
    private func observeResults(from transcriber: SpeechTranscriber) {
        resultsTask = Task { [weak self] in
            do {
                for try await result in transcriber.results {
                    guard let self else { return }
                    let text = String(result.text.characters)

                    if result.isFinal {
                        self.appendFinalized(text)
                    } else {
                        self.showVolatile(text)
                    }
                }
            } catch {
                // The analyzer reports its own failure through `analyzeSequence`.
                // Whatever was transcribed before the error still stands.
            }
        }
    }

    private func appendFinalized(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        hasHeardSpeech = true
        finalizedText = finalizedText.isEmpty ? trimmed : "\(finalizedText) \(trimmed)"
        liveTranscript = finalizedText
    }

    private func showVolatile(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        hasHeardSpeech = true
        liveTranscript = finalizedText.isEmpty ? trimmed : "\(finalizedText) \(trimmed)"
    }

    // MARK: - Lifecycle

    private func finish(through lastSampleTime: CMTime?) async {
        guard let analyzer else { return }

        if let lastSampleTime {
            try? await analyzer.finalizeAndFinish(through: lastSampleTime)
        } else {
            try? await analyzer.cancelAndFinishNow()
        }
    }

    private func teardown() async {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        inputBuilder?.finish()
        resultsTask?.cancel()
        analysisTask?.cancel()
        deactivateAudioSession()
        analyzer = nil
        transcriber = nil
        inputBuilder = nil
    }

    private func reset() {
        finalizedText = ""
        liveTranscript = ""
        hasHeardSpeech = false
        isPreparingAssets = false
    }

    // MARK: - Permission

    /// Asks for the microphone, routed through `PermissionManager` so the
    /// status is recorded alongside every other permission the app holds
    /// rather than being asked for privately here.
    private func requestMicrophoneAccess() async -> Bool {
        await PermissionManager.shared.requestMicrophonePermission()
    }
}
