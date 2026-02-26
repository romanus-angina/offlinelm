import Foundation
import FoundationModels

// MARK: - Call 1: Topic extraction

@available(iOS 26.0, *)
@Generable
struct TopicList: Sendable {
    @Guide(description: "5 to 8 core topics extracted strictly from the provided text. No external facts.")
    var topics: [Topic]
}

@available(iOS 26.0, *)
@Generable
struct Topic: Sendable {
    @Guide(description: "Topic name, 2-5 words")
    var name: String

    @Guide(description: "One sentence summary using only information from the source text")
    var summary: String
}

// MARK: - Call 2: Podcast dialogue

@available(iOS 26.0, *)
@Generable
struct PodcastScript: Sendable {
    @Guide(description: "12 to 20 dialogue turns alternating between Alex and Sam")
    var turns: [DialogueTurn]
}

@available(iOS 26.0, *)
@Generable
struct DialogueTurn: Sendable {
    var speaker: TurnSpeaker

    @Guide(description: "1-3 conversational sentences. No filler like 'Certainly!' or 'Great question!'")
    var text: String
}

@available(iOS 26.0, *)
@Generable
enum TurnSpeaker: String, Sendable {
    case alex
    case sam
}

// MARK: - Call 3: Slide generation

@available(iOS 26.0, *)
@Generable
struct SlideSet: Sendable {
    var slides: [SlideEntry]
}

@available(iOS 26.0, *)
@Generable
struct SlideEntry: Sendable {
    @Guide(description: "Slide title matching the topic name")
    var title: String

    @Guide(description: "Exactly 3-4 concise bullet points. Each under 12 words.")
    var keyPoints: [String]

    var quizQuestion: String
    var quizAnswer: String
}
