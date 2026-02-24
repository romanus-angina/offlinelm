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

    // Codable collections live in JSON blobs; SwiftData stores them as Data.
    @Attribute var dialogueSegmentsData: Data
    @Attribute var slidesData: Data

    // MARK: - Computed accessors

    var dialogueSegments: [DialogueSegment] {
        get { (try? JSONDecoder().decode([DialogueSegment].self, from: dialogueSegmentsData)) ?? [] }
        set { dialogueSegmentsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var slides: [Slide] {
        get { (try? JSONDecoder().decode([Slide].self, from: slidesData)) ?? [] }
        set { slidesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        title: String,
        sourceText: String = "",
        createdAt: Date = .now,
        status: ProcessingStatus = .importing,
        dialogueSegments: [DialogueSegment] = [],
        slides: [Slide] = []
    ) {
        self.id = id
        self.title = title
        self.sourceText = sourceText
        self.createdAt = createdAt
        self.status = status
        self.dialogueSegmentsData = (try? JSONEncoder().encode(dialogueSegments)) ?? Data()
        self.slidesData = (try? JSONEncoder().encode(slides)) ?? Data()
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
}
