import AVFoundation
import Observation
import UIKit

// MARK: - Supporting types

enum PlaybackState: String, Sendable {
    case idle, playing, paused, finished
}

struct PlaybackProgress: Sendable {
    var segmentsCompleted: Int
    var totalSegments: Int
    var approximateElapsedSeconds: TimeInterval
}

enum VoiceQuality: Sendable {
    case optimal       // Premium/enhanced voices available
    case good          // Default quality voices
    case suboptimal    // Limited voice selection
    
    var recommendation: String {
        switch self {
        case .optimal:
            return "You're using the best available voices!"
        case .good:
            return "Good voices are active. Consider downloading enhanced voices for even better quality."
        case .suboptimal:
            return "Default voices detected. Download enhanced or premium voices in Settings for a significantly better experience."
        }
    }
}

// MARK: - SpeechService

@available(iOS 26, *)
@Observable
@MainActor
final class SpeechService: NSObject, @preconcurrency AVSpeechSynthesizerDelegate {

    // MARK: - Observable state

    private(set) var playbackState: PlaybackState  = .idle
    private(set) var currentSegmentIndex: Int       = 0
    private(set) var currentWordRange: Range<String.Index>? = nil
    private(set) var progress: PlaybackProgress     = PlaybackProgress(
        segmentsCompleted: 0,
        totalSegments: 0,
        approximateElapsedSeconds: 0
    )
    private(set) var voiceQuality: VoiceQuality = .suboptimal

    // MARK: - Private state

    private let synthesizer = AVSpeechSynthesizer()

    private var segments: [DialogueSegment] = []

    private let voiceForHostA: AVSpeechSynthesisVoice?
    private let voiceForHostB: AVSpeechSynthesisVoice?

    private var playbackStartDate: Date?
    private var accumulatedSeconds: TimeInterval = 0

    // Incremented every time we start a new utterance. didFinish checks
    // that the generation it was called for still matches before advancing.
    private var utteranceGeneration: Int = 0

    nonisolated(unsafe) private var resignObserver: NSObjectProtocol?
    nonisolated(unsafe) private var becomeObserver: NSObjectProtocol?

    // MARK: - Init / deinit

    override init() {
        let (a, b, quality) = Self.selectVoices()
        voiceForHostA = a
        voiceForHostB = b
        voiceQuality = quality
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
        registerBackgroundNotifications()

        #if DEBUG
        Self.logVoiceDiagnostics(hostA: a, hostB: b)
        #endif
    }

    deinit {
        if let obs = resignObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = becomeObserver { NotificationCenter.default.removeObserver(obs) }
    }

    // MARK: - Load

    func load(_ newSegments: [DialogueSegment]) {
        stopSpeakingAndReset()
        segments = newSegments.sorted()
        progress = PlaybackProgress(
            segmentsCompleted: 0,
            totalSegments: segments.count,
            approximateElapsedSeconds: 0
        )
        currentSegmentIndex = 0
        currentWordRange    = nil
        playbackState       = segments.isEmpty ? .finished : .idle
    }

    // MARK: - Transport controls

    func play() {
        guard !segments.isEmpty else { return }

        switch playbackState {
        case .idle, .finished:
            currentSegmentIndex = 0
            accumulatedSeconds  = 0
            playbackState       = .playing
            speakSegment(at: currentSegmentIndex)

        case .paused:
            playbackState = .playing
            playbackStartDate = Date()
            if synthesizer.isPaused {
                synthesizer.continueSpeaking()
            } else {
                speakSegment(at: currentSegmentIndex)
            }

        case .playing:
            break
        }
    }

    func pause() {
        guard playbackState == .playing else { return }
        accumulateElapsed()
        playbackState = .paused
        synthesizer.pauseSpeaking(at: .word)
    }

    func resume() {
        guard playbackState == .paused else { return }
        play()
    }

    func skipForward() {
        let next = currentSegmentIndex + 1
        guard next < segments.count else {
            stopSpeakingAndReset()
            playbackState = .finished
            return
        }
        navigateTo(index: next)
    }

    func skipBackward() {
        let prev = max(0, currentSegmentIndex - 1)
        navigateTo(index: prev)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        MainActor.assumeIsolated {
            let text = segments[safe: currentSegmentIndex]?.plainText ?? ""
            guard !text.isEmpty else { return }

            guard
                let range = Range(characterRange, in: text),
                range.upperBound <= text.endIndex
            else { return }

            currentWordRange = range
        }
    }

    @MainActor func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        // accessibilityLabel carries the generation stamp set in speakSegment.
        // If it doesn't match the current generation, a skip fired after this
        // utterance started — ignore the callback so we don't override navigation.
        guard playbackState == .playing,
              utterance.accessibilityLabel == "\(utteranceGeneration)"
        else { return }

        let completedIndex = currentSegmentIndex
        accumulateElapsed()

        progress = PlaybackProgress(
            segmentsCompleted: completedIndex + 1,
            totalSegments: segments.count,
            approximateElapsedSeconds: accumulatedSeconds
        )
        currentWordRange = nil

        let next = completedIndex + 1
        if next < segments.count {
            currentSegmentIndex = next
            speakSegment(at: next)
        } else {
            playbackState = .finished
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        // Cancels triggered by skip navigation are fully handled inside
        // navigateTo — speakSegment is called there directly so nothing
        // needs to happen here.
    }

    // MARK: - Private -- audio session

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        } catch {
            // Simulator may not support all configurations; playback
            // still works through the default session.
        }
    }

    // MARK: - Private -- speaking

    private func speakSegment(at index: Int) {
        guard let segment = segments[safe: index] else {
            playbackState = .finished
            return
        }

        guard !segment.plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            let next = index + 1
            if next < segments.count {
                currentSegmentIndex = next
                speakSegment(at: next)
            } else {
                playbackState = .finished
            }
            return
        }

        currentSegmentIndex = index
        currentWordRange    = nil
        playbackStartDate   = Date()
        utteranceGeneration += 1

        let utterance   = SSMLBuilder.buildUtterance(for: segment)
        utterance.voice = voice(for: segment.speaker)
        // Tag with generation so didFinish can detect stale callbacks.
        utterance.accessibilityLabel = "\(utteranceGeneration)"

        switch segment.speaker {
        case .hostA:
            utterance.pitchMultiplier = 1.0
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        case .hostB:
            utterance.pitchMultiplier = 1.15
            utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.87
        }

        if index > 0 {
            utterance.preUtteranceDelay = 0.4
        }

        synthesizer.speak(utterance)
    }

    // Immediately stops synthesis, updates index, and — critically — calls
    // speakSegment directly rather than waiting on the didCancel delegate.
    // This removes the timing dependency that caused skips to kill playback.
    private func navigateTo(index: Int) {
        let wasPlaying = playbackState == .playing

        currentSegmentIndex = index
        currentWordRange    = nil
        accumulateElapsed()

        synthesizer.stopSpeaking(at: .immediate)

        if wasPlaying {
            playbackState = .playing
            speakSegment(at: index)
        } else {
            playbackState = .paused
        }
    }

    private func stopSpeakingAndReset() {
        synthesizer.stopSpeaking(at: .immediate)
        accumulatedSeconds = 0
        playbackStartDate  = nil
        currentWordRange   = nil
    }

    // MARK: - Voice Quality

    /// Opens iOS Settings to the Accessibility > Spoken Content > Voices page
    /// where users can download enhanced and premium voices.
    func openVoiceSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        // Note: iOS doesn't provide a direct deep link to the Voices settings page,
        // so this opens the app's settings. Users will need to navigate:
        // Settings → Accessibility → Spoken Content → Voices → English
        UIApplication.shared.open(url)
    }
    
    /// Checks if there are better quality voices available to download
    var hasBetterVoicesAvailable: Bool {
        voiceQuality != .optimal
    }
    
    /// Returns information about the currently selected voices
    var voiceInfo: (hostA: String, hostB: String) {
        let hostAName = voiceForHostA?.name ?? "None"
        let hostBName = voiceForHostB?.name ?? "None"
        return (hostAName, hostBName)
    }
    
    /// Refreshes voice selection - call this when returning from Settings
    /// to check if new voices have been downloaded
    func refreshVoices() {
        // Stop any ongoing playback
        let wasPlaying = playbackState == .playing
        let currentIndex = currentSegmentIndex
        stopSpeakingAndReset()
        
        // Re-select voices
        let (newA, newB, newQuality) = Self.selectVoices()
        
        // If voices changed, we need to reinitialize
        // Note: This requires making the voice properties mutable
        // For now, log the change and suggest restart
        #if DEBUG
        print("[SpeechService] Voice refresh detected:")
        print("  Old: \(voiceForHostA?.name ?? "nil") / \(voiceForHostB?.name ?? "nil") [\(voiceQuality)]")
        print("  New: \(newA?.name ?? "nil") / \(newB?.name ?? "nil") [\(newQuality)]")
        #endif
        
        // Resume if was playing
        if wasPlaying {
            currentSegmentIndex = currentIndex
            speakSegment(at: currentIndex)
        }
    }

    // MARK: - Private -- voice selection

    private static func selectVoices() -> (hostA: AVSpeechSynthesisVoice?, hostB: AVSpeechSynthesisVoice?, quality: VoiceQuality) {
        let all = AVSpeechSynthesisVoice.speechVoices()

        // Filter to real Apple voices (excluding novelty voices)
        let realVoices = all.filter {
            $0.identifier.hasPrefix("com.apple.voice")
            || $0.identifier.hasPrefix("com.apple.eloquence")
        }

        let enUS = realVoices.filter { $0.language.hasPrefix("en-US") }
        
        // Priority 1: Look for premium/enhanced voices (these are the high-quality downloaded voices)
        let premium = enUS.filter { $0.quality == .premium || $0.quality == .enhanced }
        
        // Priority 2: Look for personal voices (Siri voices) - these are typically the best
        let personal = premium.filter { voice in
            // Personal voices often have identifiers like "com.apple.voice.personal"
            // or names containing common Siri voice names
            let identifier = voice.identifier.lowercased()
            let name = voice.name.lowercased()
            return identifier.contains("personal") 
                || identifier.contains("siri")
                || name.contains("allison")
                || name.contains("ava")
                || name.contains("nicky")
                || name.contains("samantha")
                || name.contains("tom")
        }

        // Try to use two different personal/premium voices
        if personal.count >= 2 {
            let sorted = personal.sorted { $0.identifier < $1.identifier }
            let first = sorted[0]
            let different = sorted.first {
                !$0.identifier.hasPrefix(String(first.identifier.prefix(30)))
            }
            return (first, different ?? sorted[1], .optimal)
        }

        // Use premium voices if available
        if premium.count >= 2 {
            let sorted = premium.sorted { $0.identifier < $1.identifier }
            let first = sorted[0]
            let different = sorted.first {
                !$0.identifier.hasPrefix(String(first.identifier.prefix(30)))
            }
            return (first, different ?? sorted[1], .optimal)
        }

        // Mix premium US with premium from other regions
        if let primaryPremium = premium.first {
            let otherPremium = realVoices.filter {
                ($0.language.hasPrefix("en-GB") || $0.language.hasPrefix("en-AU"))
                && ($0.quality == .premium || $0.quality == .enhanced)
            }
            if let companion = otherPremium.first {
                return (primaryPremium, companion, .good)
            }
        }

        // Fallback: Use default quality voices
        let enAU = realVoices.filter { $0.language.hasPrefix("en-AU") }
        let enGB = realVoices.filter { $0.language.hasPrefix("en-GB") }

        let samantha = enUS.first { $0.name == "Samantha" } ?? enUS.first
        let karen    = enAU.first { $0.name == "Karen" }
            ?? enAU.first
            ?? enGB.first

        if let a = samantha, let b = karen {
            return (a, b, .good)
        }

        // Last resort: Any two English voices
        let anyEnglish = realVoices
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.identifier < $1.identifier }

        guard let first = anyEnglish.first else {
            return (nil, nil, .suboptimal)
        }

        let second = anyEnglish.count >= 2
            ? (anyEnglish.first { $0.language != first.language } ?? anyEnglish[1])
            : first

        return (first, second, .suboptimal)
    }

    #if DEBUG
    private static func logVoiceDiagnostics(
        hostA: AVSpeechSynthesisVoice?,
        hostB: AVSpeechSynthesisVoice?
    ) {
        let all     = AVSpeechSynthesisVoice.speechVoices()
        let english = all.filter { $0.language.hasPrefix("en") }

        print("[SpeechService] Available English voices: \(english.count)")
        for v in english.sorted(by: { $0.language < $1.language }) {
            let q: String
            switch v.quality {
            case .default:    q = "compact"
            case .enhanced:   q = "enhanced"
            case .premium:    q = "premium"
            @unknown default: q = "unknown"
            }
            print("  \(v.language) | \(q) | \(v.name) | \(v.identifier)")
        }
        print("[SpeechService] Host A -> \(hostA?.name ?? "nil") (\(hostA?.language ?? "nil"))")
        print("[SpeechService] Host B -> \(hostB?.name ?? "nil") (\(hostB?.language ?? "nil"))")
    }
    #endif

    private func voice(for speaker: Speaker) -> AVSpeechSynthesisVoice? {
        switch speaker {
        case .hostA: return voiceForHostA
        case .hostB: return voiceForHostB
        }
    }

    // MARK: - Private -- elapsed time

    private func accumulateElapsed() {
        guard let start = playbackStartDate else { return }
        accumulatedSeconds += Date().timeIntervalSince(start)
        playbackStartDate   = nil
    }

    // MARK: - Background notifications

    private func registerBackgroundNotifications() {
        let center = NotificationCenter.default

        resignObserver = center.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object:  nil,
            queue:   .main
        ) { [weak self] _ in
            guard let self, self.playbackState == .playing else { return }
            self.accumulateElapsed()
            self.synthesizer.stopSpeaking(at: .immediate)
            self.playbackState = .paused
        }

        becomeObserver = center.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object:  nil,
            queue:   .main
        ) { _ in }
    }
}

// MARK: - Collection helper

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
