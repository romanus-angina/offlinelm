import Foundation

@available(iOS 26, *)
struct ChatMessage: Codable, Identifiable, Sendable {
    var id: UUID
    var role: ChatRole
    var content: String
    var timestamp: Date
    /// Slide titles the response relates to, determined by keyword matching after generation.
    /// Empty for user messages.
    var relatedTopics: [String]

    init(
        id: UUID = UUID(),
        role: ChatRole,
        content: String,
        timestamp: Date = .now,
        relatedTopics: [String] = []
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.relatedTopics = relatedTopics
    }
}

@available(iOS 26, *)
enum ChatRole: String, Codable, Sendable {
    case user
    case assistant
}
