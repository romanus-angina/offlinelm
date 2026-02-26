import AVFoundation

enum SSMLBuilder {

    // MARK: - Public

    static func buildUtterance(for segment: DialogueSegment) -> AVSpeechUtterance {
        let ssml = buildSSML(from: segment.plainText)

        if let utterance = AVSpeechUtterance(ssmlRepresentation: ssml) {
            return utterance
        }

        let utterance = AVSpeechUtterance(string: segment.plainText)
        utterance.rate             = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier  = segment.speaker == .hostA ? 1.0 : 1.05
        utterance.postUtteranceDelay = 0.3
        return utterance
    }

    // MARK: - Internal (exposed for testing)

    static func buildSSML(from text: String) -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "<speak></speak>"
        }
        let sentences = splitIntoSentences(text)
        let body = sentences.map { processSentence($0) }.joined()
        return "<speak>\(body)</speak>"
    }

    static func escapeXML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&",  with: "&amp;")
            .replacingOccurrences(of: "<",  with: "&lt;")
            .replacingOccurrences(of: ">",  with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'",  with: "&apos;")
    }

    // MARK: - Sentence splitting

    static func splitIntoSentences(_ text: String) -> [String] {
        var sentences: [String] = []
        var current = ""
        var idx = text.startIndex

        while idx < text.endIndex {
            let ch = text[idx]
            current.append(ch)
            let next = text.index(after: idx)

            let isTerminator = ch == "." || ch == "!" || ch == "?"
            let nextIsBreak   = next >= text.endIndex
                             || text[next] == " "
                             || text[next] == "\n"

            if isTerminator && nextIsBreak {
                let trimmed = current.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { sentences.append(trimmed) }
                current = ""
                if next < text.endIndex && (text[next] == " " || text[next] == "\n") {
                    idx = text.index(after: next)
                    continue
                }
            }

            idx = next
        }

        let trailing = current.trimmingCharacters(in: .whitespaces)
        if !trailing.isEmpty { sentences.append(trailing) }

        return sentences
    }

    // MARK: - Per-sentence SSML construction

    private static func processSentence(_ sentence: String) -> String {
        guard !sentence.isEmpty else { return "" }

        let isQuestion    = sentence.last == "?"
        let hasTerminator = sentence.last == "." || sentence.last == "!" || sentence.last == "?"

        let body     = applyEmphasis(to: sentence)
        let breakTag = hasTerminator ? "<break time=\"300ms\"/>" : ""

        if isQuestion {
            return "<prosody pitch=\"+10%\">\(body)</prosody>\(breakTag)"
        }
        return body + breakTag
    }

    // MARK: - ALL CAPS emphasis

    private static func applyEmphasis(to text: String) -> String {
        let tokens = text.components(separatedBy: " ")
        let processed = tokens.map { token -> String in
            let escaped = escapeXML(token)
            return shouldEmphasise(token) ? "<emphasis>\(escaped)</emphasis>" : escaped
        }
        return processed.joined(separator: " ")
    }

    private static func shouldEmphasise(_ token: String) -> Bool {
        let letters = token.filter(\.isLetter)
        guard letters.count >= 3 else { return false }
        let upper = letters.uppercased()
        let lower = letters.lowercased()
        return letters == upper && letters != lower
    }
}
