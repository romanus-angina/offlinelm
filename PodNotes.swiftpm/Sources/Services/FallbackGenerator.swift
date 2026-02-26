import Foundation

struct FallbackGenerator: Sendable {

    func generate(from chunks: [TextChunk]) -> (segments: [DialogueSegment], slides: [Slide]) {
        var segments: [DialogueSegment] = []
        var slides: [Slide] = []
        var segmentOrder = 0

        for chunk in chunks {
            let paragraphs = splitParagraphs(chunk.text)

            for paragraph in paragraphs {
                let speaker: Speaker = segmentOrder.isMultiple(of: 2) ? .hostA : .hostB
                let segment = DialogueSegment(
                    speaker: speaker,
                    plainText: paragraph,
                    ssmlText: wrapSSML(paragraph, speaker: speaker),
                    order: segmentOrder
                )
                segments.append(segment)
                segmentOrder += 1
            }

            let sentences = extractSentences(from: chunk.text)
            let title = sentences.first ?? "Section \(chunk.order + 1)"
            let keyPoints = Array(sentences.dropFirst().prefix(3))

            let slide = Slide(
                title: title,
                keyPoints: keyPoints.isEmpty ? ["Review this section."] : keyPoints,
                quizQuestion: "What is the main idea of this section?",
                quizAnswer: sentences.first ?? "See your notes for details.",
                order: chunk.order
            )
            slides.append(slide)
        }

        return (segments, slides)
    }

    // MARK: - Private

    private func splitParagraphs(_ text: String) -> [String] {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func extractSentences(from text: String) -> [String] {
        var results: [String] = []
        var current = ""
        var index = text.startIndex

        while index < text.endIndex {
            let ch = text[index]
            current.append(ch)

            let isTerminator = ch == "." || ch == "!" || ch == "?"
            let next = text.index(after: index)
            let nextIsSpace = next < text.endIndex
                && (text[next] == " " || text[next] == "\n")

            if isTerminator && nextIsSpace {
                let trimmed = current.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { results.append(trimmed) }
                current = ""
            }

            index = next
        }

        let trailing = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trailing.isEmpty { results.append(trailing) }

        return results
    }

    private func wrapSSML(_ text: String, speaker: Speaker) -> String {
        let rate: String
        switch speaker {
        case .hostA: rate = "medium"
        case .hostB: rate = "medium"
        }
        return "<speak><prosody rate=\"\(rate)\">\(escapedForSSML(text))</prosody></speak>"
    }

    private func escapedForSSML(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
