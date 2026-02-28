import Foundation
import Observation
import SwiftUI

// MARK: - Player colour palette
// Kept here so every player view imports a single source of truth.
// These live alongside the ViewModel rather than polluting AppTheme,
// which belongs to the rest of the app.

enum PlayerPalette {
    // Background — deep navy, not the app's near-black.
    static let background      = Color(red: 0.039, green: 0.055, blue: 0.102) // #0A0E1A
    static let backgroundLift  = Color(red: 0.063, green: 0.086, blue: 0.149) // slight lift for cards

    // Host A — electric blue
    static let hostA           = Color(red: 0.231, green: 0.510, blue: 0.965) // #3B82F6
    static let hostAGlow       = Color(red: 0.231, green: 0.510, blue: 0.965).opacity(0.35)

    // Host B — warm amber
    static let hostB           = Color(red: 0.961, green: 0.620, blue: 0.043) // #F59E0B
    static let hostBGlow       = Color(red: 0.961, green: 0.620, blue: 0.043).opacity(0.35)

    // Utility
    static let textPrimary     = Color(red: 0.94, green: 0.96, blue: 1.00)
    static let textSecondary   = Color(red: 0.94, green: 0.96, blue: 1.00).opacity(0.55)
    static let textTertiary    = Color(red: 0.94, green: 0.96, blue: 1.00).opacity(0.30)
    static let border          = Color.white.opacity(0.07)
    static let controlSurface  = Color(red: 0.10, green: 0.13, blue: 0.20)

    static func accent(for speaker: Speaker) -> Color {
        speaker == .hostA ? hostA : hostB
    }

    static func glow(for speaker: Speaker) -> Color {
        speaker == .hostA ? hostAGlow : hostBGlow
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
