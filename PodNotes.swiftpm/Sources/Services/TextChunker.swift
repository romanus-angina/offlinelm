import Foundation

/// Splits a body of extracted PDF text into ordered `TextChunk` values
/// whose word count falls within a configurable window.

struct TextChunker: Sendable {

    /// Word count the chunker aims for per chunk. When adding the next
    /// paragraph would push the buffer past this target, the buffer is
    /// flushed first.
    let targetWordCount: Int

    /// Hard ceiling for a single paragraph. Paragraphs larger than this
    /// are broken at sentence boundaries rather than kept whole.
    let maximumWordCount: Int

    init(targetWordCount: Int = 1200, maximumWordCount: Int = 1500) {
        self.targetWordCount = targetWordCount
        self.maximumWordCount = maximumWordCount
    }

    // MARK: - Public

    /// Chunk a flat string. No page-range metadata is attached to the results.
    func chunk(_ text: String) -> [TextChunk] {
        let paragraphs = extractParagraphs(from: text)
        return assemble(paragraphs: paragraphs.map { ($0, nil) })
    }

    /// Chunk page-tagged text. Each `TextChunk` in the result carries a
    /// `pageRange` spanning the PDF pages its content was drawn from.
    func chunk(pageTexts: [(pageNumber: Int, text: String)]) -> [TextChunk] {
        let tagged: [(text: String, page: Int?)] = pageTexts.flatMap { pair in
            extractParagraphs(from: pair.text).map { ($0, pair.pageNumber) }
        }
        return assemble(paragraphs: tagged)
    }

    /// Rough token estimate using the 1 word ≈ 1.3 tokens heuristic.
    /// Useful for staying within a model's advertised context window.
    static func estimatedTokenCount(for text: String) -> Int {
        let words = text.split { $0.isWhitespace }.count
        return Int(ceil(Double(words) * 1.3))
    }

    // MARK: - Private

    private func wordCount(_ text: String) -> Int {
        text.split { $0.isWhitespace }.count
    }

    /// Split on double-newline paragraph boundaries, collapsing longer
    /// runs of blank lines down to a single break.
    private func extractParagraphs(from text: String) -> [String] {
        var normalised = text
        while normalised.contains("\n\n\n") {
            normalised = normalised.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        return normalised
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func assemble(paragraphs: [(text: String, page: Int?)]) -> [TextChunk] {
        var chunks: [TextChunk] = []
        var buffer: [(text: String, page: Int?)] = []
        var bufferWords = 0

        for paragraph in paragraphs {
            let pw = wordCount(paragraph.text)

            if pw > maximumWordCount {
                // Flush what we have before handling the oversized paragraph.
                if !buffer.isEmpty {
                    chunks.append(makeChunk(from: buffer, order: chunks.count))
                    buffer = []
                    bufferWords = 0
                }
                let sub = splitAtSentences(paragraph, startingOrder: chunks.count)
                chunks.append(contentsOf: sub)
                continue
            }

            if bufferWords + pw > targetWordCount, !buffer.isEmpty {
                chunks.append(makeChunk(from: buffer, order: chunks.count))
                buffer = []
                bufferWords = 0
            }

            buffer.append(paragraph)
            bufferWords += pw
        }

        if !buffer.isEmpty {
            chunks.append(makeChunk(from: buffer, order: chunks.count))
        }

        return chunks
    }

    private func makeChunk(
        from paragraphs: [(text: String, page: Int?)],
        order: Int
    ) -> TextChunk {
        let combined = paragraphs.map(\.text).joined(separator: "\n\n")
        let pages = paragraphs.compactMap(\.page)
        let range: ClosedRange<Int>? = pages.isEmpty ? nil : (pages.min()! ... pages.max()!)
        return TextChunk(id: UUID(), text: combined, order: order, pageRange: range)
    }

    /// Breaks a paragraph that exceeds `maximumWordCount` at sentence
    /// endings (punctuation followed by whitespace).
    private func splitAtSentences(
        _ paragraph: (text: String, page: Int?),
        startingOrder: Int
    ) -> [TextChunk] {
        let sentences = paragraph.text.sentenceBoundaryComponents()
        var chunks: [TextChunk] = []
        var buffer: [String] = []
        var bufferWords = 0

        for sentence in sentences {
            let sw = wordCount(sentence)
            if bufferWords + sw > targetWordCount, !buffer.isEmpty {
                let combined = buffer.joined(separator: " ")
                let range = paragraph.page.map { $0 ... $0 }
                chunks.append(TextChunk(
                    id: UUID(),
                    text: combined,
                    order: startingOrder + chunks.count,
                    pageRange: range
                ))
                buffer = []
                bufferWords = 0
            }
            buffer.append(sentence)
            bufferWords += sw
        }

        if !buffer.isEmpty {
            let combined = buffer.joined(separator: " ")
            let range = paragraph.page.map { $0 ... $0 }
            chunks.append(TextChunk(
                id: UUID(),
                text: combined,
                order: startingOrder + chunks.count,
                pageRange: range
            ))
        }

        return chunks
    }
}

// MARK: - String + sentence splitting

private extension String {

    /// Splits the receiver at sentence-terminal punctuation (`.`, `!`, `?`)
    /// followed by whitespace, keeping the punctuation attached to the
    /// preceding sentence rather than the next.
    func sentenceBoundaryComponents() -> [String] {
        var result: [String] = []
        var current = ""
        var idx = startIndex

        while idx < endIndex {
            let ch = self[idx]
            current.append(ch)

            let isTerminator = ch == "." || ch == "!" || ch == "?"
            let nextIdx = index(after: idx)
            let nextIsSpace = nextIdx < endIndex
                && (self[nextIdx] == " " || self[nextIdx] == "\n")

            if isTerminator && nextIsSpace {
                let trimmed = current.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { result.append(trimmed) }
                current = ""
            }

            idx = nextIdx
        }

        let trailing = current.trimmingCharacters(in: .whitespaces)
        if !trailing.isEmpty { result.append(trailing) }

        return result
    }
}
