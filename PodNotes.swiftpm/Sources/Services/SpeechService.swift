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

    // Sorted segments loaded by the most recent load() call.
    private var segments: [DialogueSegment] = []

    // Voice assignments, Set at init
    private let voiceForHostA: AVSpeechSynthesisVoice?
    private let voiceForHostB: AVSpeechSynthesisVoice?

    // Tracks whether a didCancel callback belongs to a skip navigation
    private var isNavigatingViaSkip = false

    // Tracks elapsed playback time across segments.
    private var playbackStartDate: Date?
    private var accumulatedSeconds: TimeInterval = 0

    // Notification observers
    private var resignObserver:   NSObjectProtocol?
    private var becomeObserver:   NSObjectProtocol?

    // MARK: - Init / deinit

    override init() {
        let (a, b) = Self.selectVoices()
        voiceForHostA = a
        voiceForHostB = b
        super.init()
        synthesizer.delegate = self
        registerBackgroundNotifications()
    }

    deinit {
        if let obs = resignObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = becomeObserver { NotificationCenter.default.removeObserver(obs) }
    }

    // MARK: - Load

    /// Accepts a new dialogue array and resets all playback state.
    /// Safe to call while audio is playing — stops any current utterance first.
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
            synthesizer.continueSpeaking()

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

        // The delegate fires with an NSRange into utterance.speechString.
        // When SSML is used, speechString is the stripped plain text, which
        // may differ slightly from segment.plainText hence map the range onto
        // segment.plainText directly
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
        // didCancel fires first when a skip is in progress
        //  didFinish only fires for natural completion.
        guard playbackState == .playing else { return }

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
        guard isNavigatingViaSkip else { return }
        isNavigatingViaSkip = false

        // Begin speaking the segment we navigated to, but only if the user
        // was actively playing. If they skipped while paused, stay paused.
        if playbackState == .playing {
            speakSegment(at: currentSegmentIndex)
        }
    }

    // MARK: - Private — speaking

    private func speakSegment(at index: Int) {
        guard let segment = segments[safe: index] else {
            playbackState = .finished
            return
        }

        guard !segment.plainText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // Skip empty segments and continue.
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

        let utterance       = SSMLBuilder.buildUtterance(for: segment)
        utterance.voice     = voice(for: segment.speaker)

        // Add a brief pause before all segments except the first so
        // transitions between speakers feel natural.
        if index > 0 {
            utterance.preUtteranceDelay = 0.4
        }

        synthesizer.speak(utterance)
    }

    private func navigateTo(index: Int) {
        let wasPlaying    = playbackState == .playing
        isNavigatingViaSkip = true
        accumulateElapsed()

        currentSegmentIndex = index
        currentWordRange    = nil

        synthesizer.stopSpeaking(at: .immediate)

        // If the user was paused, stay paused at the new position.
        // didCancel will fire and check playbackState there.
        if !wasPlaying {
            playbackState = .paused
            isNavigatingViaSkip = false
        }
        // If wasPlaying, didCancel fires and calls speakSegment(at:).
    }

    private func stopSpeakingAndReset() {
        isNavigatingViaSkip = false
        synthesizer.stopSpeaking(at: .immediate)
        accumulatedSeconds = 0
        playbackStartDate  = nil
        currentWordRange   = nil
    }

    // MARK: - Private — voice selection

    private static func selectVoices() -> (hostA: AVSpeechSynthesisVoice?, hostB: AVSpeechSynthesisVoice?) {
        let all = AVSpeechSynthesisVoice.speechVoices()
        let enUS = all.filter { $0.language.hasPrefix("en-US") }

        // Prefer premium/enhanced; fall back to compact.
        let preferred = enUS.filter {
            $0.quality == .premium || $0.quality == .enhanced
        }
        let pool = preferred.isEmpty ? enUS : preferred

        guard !pool.isEmpty else {
            // No en-US voice available at all — use system default for both.
            return (nil, nil)
        }

        let sorted = pool.sorted { $0.identifier < $1.identifier }

        if sorted.count == 1 {
            return (sorted[0], sorted[0])
        }

        // Pick two voices with different identifier prefixes where possible,
        // so they differ in more than just a version suffix.
        let first = sorted[0]
        let different = sorted.first {
            !$0.identifier.hasPrefix(String(first.identifier.prefix(30)))
        }
        let second = different ?? sorted[1]

        return (first, second)
    }

    private func voice(for speaker: Speaker) -> AVSpeechSynthesisVoice? {
        switch speaker {
        case .hostA: return voiceForHostA
        case .hostB: return voiceForHostB
        }
    }

    // MARK: - Private — elapsed time

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

        // On foreground return, do not auto-resume
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
