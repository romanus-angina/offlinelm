import Foundation

struct Slide: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var title: String
    var keyPoints: [String]
    var quizQuestion: String
    var quizAnswer: String
    /// Zero-based position within the deck.
    var order: Int

    init(
        id: UUID = UUID(),
        title: String,
        keyPoints: [String] = [],
        quizQuestion: String = "",
        quizAnswer: String = "",
        order: Int
    ) {
        self.id           = id
        self.title        = title
        self.keyPoints    = keyPoints
        self.quizQuestion = quizQuestion
        self.quizAnswer   = quizAnswer
        self.order        = order
    }
}

extension Slide: Comparable {
    static func < (lhs: Slide, rhs: Slide) -> Bool {
        lhs.order < rhs.order
    }
}
