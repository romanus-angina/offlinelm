// StudyModule.swift

import Foundation
import SwiftData

@available(iOS 26, *)
@Model
final class StudyModule {

    // MARK: - Stored

    var id: UUID
    var title: String
    var sourceText: String
    var createdAt: Date
    var status: ProcessingStatus

    // Raw PDF bytes kept so the module can be re-processed without
    // asking the user to re-import. Typical study PDFs are 1-10 MB
    // which is fine for on-device SwiftData storage.
    @Attribute var pdfData: Data?

    // Codable collections live in JSON blobs; SwiftData stores them as Data.
    @Attribute var dialogueSegmentsData: Data
    @Attribute var slidesData: Data

    // Quiz answer persistence: maps slide UUID string to selected choice index.
    @Attribute var quizAnswersData: Data = Data()

    // Chat message persistence: stores the full conversation history.
    @Attribute var chatMessagesData: Data = Data()

    // MARK: - Computed accessors

    var dialogueSegments: [DialogueSegment] {
        get { (try? JSONDecoder().decode([DialogueSegment].self, from: dialogueSegmentsData)) ?? [] }
        set { dialogueSegmentsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var slides: [Slide] {
        get { (try? JSONDecoder().decode([Slide].self, from: slidesData)) ?? [] }
        set { slidesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var quizAnswers: [String: Int] {
        get { (try? JSONDecoder().decode([String: Int].self, from: quizAnswersData)) ?? [:] }
        set { quizAnswersData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var chatMessages: [ChatMessage] {
        get { (try? JSONDecoder().decode([ChatMessage].self, from: chatMessagesData)) ?? [] }
        set { chatMessagesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        title: String,
        sourceText: String = "",
        createdAt: Date = .now,
        status: ProcessingStatus = .importing,
        pdfData: Data? = nil,
        dialogueSegments: [DialogueSegment] = [],
        slides: [Slide] = [],
        chatMessages: [ChatMessage] = []
    ) {
        self.id = id
        self.title = title
        self.sourceText = sourceText
        self.createdAt = createdAt
        self.status = status
        self.pdfData = pdfData
        self.dialogueSegmentsData = (try? JSONEncoder().encode(dialogueSegments)) ?? Data()
        self.slidesData = (try? JSONEncoder().encode(slides)) ?? Data()
        self.quizAnswersData = Data()
        self.chatMessagesData = (try? JSONEncoder().encode(chatMessages)) ?? Data()
    }
}

// MARK: - Convenience

@available(iOS 26, *)
extension StudyModule {
    var formattedDate: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: createdAt, relativeTo: .now)
    }

    var isPlayable: Bool { status == .ready }

    // Rough estimate at 150 wpm average reading pace.
    var estimatedDurationMinutes: Int {
        let words = dialogueSegments.reduce(0) { $0 + $1.plainText.split(separator: " ").count }
        return max(1, Int(ceil(Double(words) / 150.0)))
    }

    // MARK: - Quiz helpers

    /// Number of quiz questions answered so far.
    var quizAnsweredCount: Int {
        quizAnswers.count
    }

    /// Total number of quiz questions available.
    var quizTotalCount: Int {
        slides.count
    }

    /// Number of correctly answered quiz questions.
    var quizCorrectCount: Int {
        let sortedSlides = slides.sorted()
        return sortedSlides.reduce(0) { total, slide in
            guard let picked = quizAnswers[slide.id.uuidString] else { return total }
            return total + (picked == slide.correctAnswerIndex ? 1 : 0)
        }
    }

    /// Whether the quiz has been started but not finished.
    var quizInProgress: Bool {
        quizAnsweredCount > 0 && quizAnsweredCount < quizTotalCount
    }

    /// Whether every quiz question has been answered.
    var quizCompleted: Bool {
        quizTotalCount > 0 && quizAnsweredCount >= quizTotalCount
    }

    /// Clears all saved quiz answers.
    func resetQuiz() {
        quizAnswers = [:]
    }
}
