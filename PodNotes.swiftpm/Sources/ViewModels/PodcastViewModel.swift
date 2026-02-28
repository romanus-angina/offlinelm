import Foundation
import Observation
import SwiftUI

// MARK: - Player colour palette
// Thin aliases over AppTheme so every player view has a single import point.
// Speaker accent colours delegate to Speaker.accentColor (ana1 / ana5).

@available(iOS 26, *)
enum PlayerPalette {
    static let background     = AppTheme.Colors.backgroundPrimary
    static let backgroundLift = AppTheme.Colors.backgroundSecondary
    static let textPrimary    = AppTheme.Colors.textPrimary
    static let textSecondary  = AppTheme.Colors.textSecondary
    static let textTertiary   = AppTheme.Colors.textTertiary
    static let border         = AppTheme.Colors.borderSubtle
    static let controlSurface = AppTheme.Colors.backgroundTertiary

    static func accent(for speaker: Speaker) -> Color {
        speaker.accentColor
    }

    static func glow(for speaker: Speaker) -> Color {
        speaker.accentColor.opacity(0.40)
    }
}

// MARK: - PodcastViewModel

@available(iOS 26, *)
@Observable
final class PodcastViewModel {

    // MARK: - Public state

    let title: String
    let segments: [DialogueSegment]
    let speech: SpeechService

    var isShowingSlides = false

    // MARK: - Computed: playback

    var isPlaying: Bool {
        speech.playbackState == .playing
    }

    var isPaused: Bool {
        speech.playbackState == .paused
    }

    var isFinished: Bool {
        speech.playbackState == .finished
    }

    var currentSegment: DialogueSegment? {
        segments[safe: speech.currentSegmentIndex]
    }

    var currentSpeaker: Speaker {
        currentSegment?.speaker ?? .hostA
    }

    // Fraction in [0, 1] for a progress scrubber.
    var progressFraction: Double {
        guard segments.count > 1 else { return isFinished ? 1.0 : 0.0 }
        return Double(speech.currentSegmentIndex) / Double(segments.count - 1)
    }

    // "4 / 12" style label for the transport bar.
    var segmentPositionLabel: String {
        guard !segments.isEmpty else { return "—" }
        return "\(speech.currentSegmentIndex + 1) / \(segments.count)"
    }

    // MARK: - Inits

    // Production path: driven by a real StudyModule.
    init(module: StudyModule, speech: SpeechService = SpeechService()) {
        self.title    = module.title
        let sorted    = module.dialogueSegments.sorted()
        self.segments = sorted
        self.speech   = speech
        speech.load(sorted)
    }

    // Preview / testing path: no SwiftData required.
    init(title: String, segments: [DialogueSegment], speech: SpeechService = SpeechService()) {
        self.title    = title
        self.segments = segments.sorted()
        self.speech   = speech
        speech.load(segments.sorted())
    }

    // MARK: - Transport

    func togglePlayPause() {
        switch speech.playbackState {
        case .playing:              speech.pause()
        case .paused:               speech.resume()
        case .idle, .finished:      speech.play()
        }
    }

    func skipForward() {
        speech.skipForward()
    }

    func skipBackward() {
        speech.skipBackward()
    }
}

// MARK: - Mock data

@available(iOS 26, *)
extension PodcastViewModel {

    static let mockTitle = "Cellular Biology — Chapter 4"

    static let mockSegments: [DialogueSegment] = [
        DialogueSegment(
            speaker: .hostA,
            plainText: "The cell is the fundamental unit of life. Every organism is composed of one or more cells, and all cells arise from pre-existing cells through the process of cell division.",
            ssmlText: "",
            order: 0
        ),
        DialogueSegment(
            speaker: .hostB,
            plainText: "So when textbooks say cells are the building blocks of life, they mean that literally — there is no living structure smaller than a cell that can sustain itself independently?",
            ssmlText: "",
            order: 1
        ),
        DialogueSegment(
            speaker: .hostA,
            plainText: "Precisely. Viruses blur that line, but they require a host cell to replicate, which is why biologists do not classify them as alive in the traditional sense. The cell membrane is what separates a living system from its environment.",
            ssmlText: "",
            order: 2
        ),
        DialogueSegment(
            speaker: .hostB,
            plainText: "And ATP powers most of what happens inside that boundary, right? Every active transport mechanism, every protein synthesis step — all of it runs on ATP?",
            ssmlText: "",
            order: 3
        ),
        DialogueSegment(
            speaker: .hostA,
            plainText: "That is correct. The mitochondria produce ATP through cellular respiration, oxidising glucose in a series of reactions — glycolysis, the Krebs cycle, and the electron transport chain — that collectively yield up to 36 ATP molecules per glucose molecule.",
            ssmlText: "",
            order: 4
        ),
        DialogueSegment(
            speaker: .hostB,
            plainText: "That efficiency number is theoretical though, is it not? In practice the yield is closer to 30 ATP due to membrane leakage and the cost of importing substrates into the mitochondria.",
            ssmlText: "",
            order: 5
        ),
        DialogueSegment(
            speaker: .hostA,
            plainText: "Exactly right. The theoretical maximum assumes perfect coupling between the proton gradient and ATP synthase, which never happens in a real cell. Biological efficiency is always somewhat lower than the thermodynamic ideal.",
            ssmlText: "",
            order: 6
        ),
    ]

    static var mock: PodcastViewModel {
        PodcastViewModel(title: mockTitle, segments: mockSegments)
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
