import Foundation

struct DialogueSegment: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var speaker: Speaker
    /// Readable transcript shown in the UI — no markup.
    var plainText: String
    /// SSML version fed to the speech synthesiser.
    var ssmlText: String
    /// Zero-based position within the full script.
    var order: Int

    init(
        id: UUID = UUID(),
        speaker: Speaker,
        plainText: String,
        ssmlText: String,
        order: Int
    ) {
        self.id        = id
        self.speaker   = speaker
        self.plainText = plainText
        self.ssmlText  = ssmlText
        self.order     = order
    }
}

extension DialogueSegment: Comparable {
    static func < (lhs: DialogueSegment, rhs: DialogueSegment) -> Bool {
        lhs.order < rhs.order
    }
}
