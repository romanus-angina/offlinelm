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

// MARK: - SpeechService

@available(iOS 26, *)
@Observable
final class SpeechService: NSObject, AVSpeechSynthesizerDelegate {

    // MARK: - Observable state

    private(set) var playbackState: PlaybackState  = .idle
    private(set) var currentSegmentIndex: Int       = 0
    private(set) var currentWordRange: Range<String.Index>? = nil
    private(set) var progress: PlaybackProgress     = PlaybackProgress(
        segmentsCompleted: 0,
        totalSegments: 0,
        approximateElapsedSeconds: 0
    )

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

    private var resignObserver: NSObjectProtocol?
    private var becomeObserver: NSObjectProtocol?

    // MARK: - Init / deinit

    override init() {
        let (a, b) = Self.selectVoices()
        voiceForHostA = a
        voiceForHostB = b
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

    func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        let text = segments[safe: currentSegmentIndex]?.plainText ?? ""
        guard !text.isEmpty else { return }

        guard
            let range = Range(characterRange, in: text),
            range.upperBound <= text.endIndex
        else { return }

        currentWordRange = range
    }

    func speechSynthesizer(
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

    func speechSynthesizer(
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

    // MARK: - Private -- voice selection

    private static func selectVoices() -> (hostA: AVSpeechSynthesisVoice?, hostB: AVSpeechSynthesisVoice?) {
        let all = AVSpeechSynthesisVoice.speechVoices()

        let realVoices = all.filter {
            $0.identifier.hasPrefix("com.apple.voice")
            || $0.identifier.hasPrefix("com.apple.eloquence")
        }

        let enUS    = realVoices.filter { $0.language.hasPrefix("en-US") }
        let premium = enUS.filter { $0.quality == .premium || $0.quality == .enhanced }

        if premium.count >= 2 {
            let sorted = premium.sorted { $0.identifier < $1.identifier }
            let first = sorted[0]
            let different = sorted.first {
                !$0.identifier.hasPrefix(String(first.identifier.prefix(30)))
            }
            return (first, different ?? sorted[1])
        }

        if let primaryPremium = premium.first {
            let otherPremium = realVoices.filter {
                ($0.language.hasPrefix("en-GB") || $0.language.hasPrefix("en-AU"))
                && ($0.quality == .premium || $0.quality == .enhanced)
            }
            if let companion = otherPremium.first {
                return (primaryPremium, companion)
            }
        }

        let enAU = realVoices.filter { $0.language.hasPrefix("en-AU") }
        let enGB = realVoices.filter { $0.language.hasPrefix("en-GB") }

        let samantha = enUS.first { $0.name == "Samantha" } ?? enUS.first
        let karen    = enAU.first { $0.name == "Karen" }
            ?? enAU.first
            ?? enGB.first

        if let a = samantha, let b = karen {
            return (a, b)
        }

        let anyEnglish = realVoices
            .filter { $0.language.hasPrefix("en") }
            .sorted { $0.identifier < $1.identifier }

        guard let first = anyEnglish.first else {
            return (nil, nil)
        }

        let second = anyEnglish.count >= 2
            ? (anyEnglish.first { $0.language != first.language } ?? anyEnglish[1])
            : first

        return (first, second)
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
