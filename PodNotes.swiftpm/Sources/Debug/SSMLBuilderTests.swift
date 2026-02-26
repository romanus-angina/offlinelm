import Foundation

enum SSMLBuilderTests {

    struct TestResult: Sendable {
        let name: String
        let passed: Bool
        let detail: String
    }

    static func runAll() -> [TestResult] {
        [
            testOutputWrappedInSpeakTags(),
            testEmptyTextProducesEmptySpeakTag(),
            testBreakAfterPeriod(),
            testBreakAfterExclamation(),
            testBreakAfterQuestion(),
            testNoBreakAtEndWithoutTerminator(),
            testProsodyWrapperOnQuestion(),
            testNoProsodyOnStatement(),
            testAllCapsThreeLetterEmphasised(),
            testAllCapsTwoLetterNotEmphasised(),
            testMixedCaseWordNotEmphasised(),
            testLowercaseWordNotEmphasised(),
            testAmpersandEscaped(),
            testLessThanEscaped(),
            testGreaterThanEscaped(),
            testDoubleQuoteEscaped(),
            testSingleQuoteEscaped(),
            testAmpersandEscapedBeforeOthers(),
            testMultipleSentencesSplit(),
            testTrailingSentenceWithoutSpaceIncluded(),
            testSentenceSplitPreservesTerminator(),
            testAllCapsInsideSentenceWithPunctuation(),
            testQuestionSentenceHasBreakOutsideProsody(),
        ]
    }

    // MARK: - Structural

    private static func testOutputWrappedInSpeakTags() -> TestResult {
        let ssml = SSMLBuilder.buildSSML(from: "Hello world.")
        return TestResult(
            name: "Output wrapped in <speak> tags",
            passed: ssml.hasPrefix("<speak>") && ssml.hasSuffix("</speak>"),
            detail: ssml
        )
    }

    private static func testEmptyTextProducesEmptySpeakTag() -> TestResult {
        let ssml = SSMLBuilder.buildSSML(from: "   ")
        return TestResult(
            name: "Whitespace-only input produces <speak></speak>",
            passed: ssml == "<speak></speak>",
            detail: ssml
        )
    }

    // MARK: - Break tag placement

    private static func testBreakAfterPeriod() -> TestResult {
        let ssml = SSMLBuilder.buildSSML(from: "First sentence. Second sentence.")
        let hasBreak = ssml.contains(".<break time=\"300ms\"/>")
        return TestResult(
            name: "Break tag inserted after period",
            passed: hasBreak,
            detail: ssml
        )
    }

    private static func testBreakAfterExclamation() -> TestResult {
        let ssml = SSMLBuilder.buildSSML(from: "This is key! Remember it.")
        let hasBreak = ssml.contains("!<break time=\"300ms\"/>")
        return TestResult(
            name: "Break tag inserted after exclamation mark",
            passed: hasBreak,
            detail: ssml
        )
    }

    private static func testBreakAfterQuestion() -> TestResult {
        let ssml = SSMLBuilder.buildSSML(from: "Why does this matter? It affects everything.")
        let hasBreak = ssml.contains("?</prosody><break time=\"300ms\"/>")
                    || ssml.contains("?<break time=\"300ms\"/>")
        return TestResult(
            name: "Break tag inserted after question mark",
            passed: hasBreak,
            detail: ssml
        )
    }

    private static func testNoBreakAtEndWithoutTerminator() -> TestResult {
        let ssml = SSMLBuilder.buildSSML(from: "An incomplete thought")
        let hasBreak = ssml.contains("<break")
        return TestResult(
            name: "No break tag when sentence lacks terminal punctuation",
            passed: !hasBreak,
            detail: ssml
        )
    }

    // MARK: - Prosody (question intonation)

    private static func testProsodyWrapperOnQuestion() -> TestResult {
        let ssml = SSMLBuilder.buildSSML(from: "What is photosynthesis?")
        let hasProsody = ssml.contains("<prosody pitch=\"+10%\">")
                      && ssml.contains("</prosody>")
        return TestResult(
            name: "Prosody pitch wrapper applied to question sentence",
            passed: hasProsody,
            detail: ssml
        )
    }

    private static func testNoProsodyOnStatement() -> TestResult {
        let ssml = SSMLBuilder.buildSSML(from: "Cells are the basic unit of life.")
        let hasProsody = ssml.contains("<prosody")
        return TestResult(
            name: "No prosody wrapper on non-question sentence",
            passed: !hasProsody,
            detail: ssml
        )
    }

    // MARK: - Emphasis (ALL CAPS)

    private static func testAllCapsThreeLetterEmphasised() -> TestResult {
        let ssml = SSMLBuilder.buildSSML(from: "DNA carries genetic information.")
        let hasEmphasis = ssml.contains("<emphasis>DNA</emphasis>")
        return TestResult(
            name: "Three-letter ALL CAPS word wrapped in <emphasis>",
            passed: hasEmphasis,
            detail: ssml
        )
    }

    private static func testAllCapsTwoLetterNotEmphasised() -> TestResult {
        let ssml = SSMLBuilder.buildSSML(from: "IT is a broad field.")
        let hasEmphasis = ssml.contains("<emphasis>IT</emphasis>")
        return TestResult(
            name: "Two-letter ALL CAPS word not emphasised",
            passed: !hasEmphasis,
            detail: ssml
        )
    }

    private static func testMixedCaseWordNotEmphasised() -> TestResult {
        let ssml = SSMLBuilder.buildSSML(from: "Python is widely used.")
        let hasEmphasis = ssml.contains("<emphasis>Python</emphasis>")
        return TestResult(
            name: "Mixed-case word not wrapped in emphasis",
            passed: !hasEmphasis,
            detail: ssml
        )
    }

    private static func testLowercaseWordNotEmphasised() -> TestResult {
        let ssml = SSMLBuilder.buildSSML(from: "the cell membrane controls transport.")
        let hasEmphasis = ssml.contains("<emphasis>")
        return TestResult(
            name: "Lowercase words produce no emphasis tags",
            passed: !hasEmphasis,
            detail: ssml
        )
    }

    // MARK: - XML escaping

    private static func testAmpersandEscaped() -> TestResult {
        let result = SSMLBuilder.escapeXML("salt & pepper")
        return TestResult(
            name: "& escaped to &amp;",
            passed: result == "salt &amp; pepper",
            detail: result
        )
    }

    private static func testLessThanEscaped() -> TestResult {
        let result = SSMLBuilder.escapeXML("pH < 7")
        return TestResult(
            name: "< escaped to &lt;",
            passed: result == "pH &lt; 7",
            detail: result
        )
    }

    private static func testGreaterThanEscaped() -> TestResult {
        let result = SSMLBuilder.escapeXML("pH > 7")
        return TestResult(
            name: "> escaped to &gt;",
            passed: result == "pH &gt; 7",
            detail: result
        )
    }

    private static func testDoubleQuoteEscaped() -> TestResult {
        let result = SSMLBuilder.escapeXML("he said \"hello\"")
        return TestResult(
            name: "\" escaped to &quot;",
            passed: result == "he said &quot;hello&quot;",
            detail: result
        )
    }

    private static func testSingleQuoteEscaped() -> TestResult {
        let result = SSMLBuilder.escapeXML("it's valid")
        return TestResult(
            name: "' escaped to &apos;",
            passed: result == "it&apos;s valid",
            detail: result
        )
    }

    private static func testAmpersandEscapedBeforeOthers() -> TestResult {
        // If & were escaped after < or > we'd get double-escaped &amp;lt; etc.
        let result = SSMLBuilder.escapeXML("a & b < c")
        let noDoubleEscape = !result.contains("&amp;amp;")
                          && !result.contains("&amp;lt;")
        return TestResult(
            name: "& replacement runs first, preventing double-escaping",
            passed: noDoubleEscape && result.contains("&amp;") && result.contains("&lt;"),
            detail: result
        )
    }

    // MARK: - Sentence splitting

    private static func testMultipleSentencesSplit() -> TestResult {
        let sentences = SSMLBuilder.splitIntoSentences("First sentence. Second sentence. Third sentence.")
        return TestResult(
            name: "Three period-separated sentences split correctly",
            passed: sentences.count == 3,
            detail: "Got \(sentences.count): \(sentences)"
        )
    }

    private static func testTrailingSentenceWithoutSpaceIncluded() -> TestResult {
        let sentences = SSMLBuilder.splitIntoSentences("Only one sentence here")
        return TestResult(
            name: "Trailing text without terminator included as final sentence",
            passed: sentences.count == 1 && sentences[0] == "Only one sentence here",
            detail: sentences.description
        )
    }

    private static func testSentenceSplitPreservesTerminator() -> TestResult {
        let sentences = SSMLBuilder.splitIntoSentences("Stop here. Continue there.")
        let firstEndsWithPeriod = sentences.first?.hasSuffix(".") ?? false
        return TestResult(
            name: "Sentence terminator stays attached to its sentence",
            passed: firstEndsWithPeriod,
            detail: sentences.first ?? "nil"
        )
    }

    // MARK: - Integration

    private static func testAllCapsInsideSentenceWithPunctuation() -> TestResult {
        // Verifies that ALL CAPS detection survives XML escaping of adjacent tokens.
        let ssml = SSMLBuilder.buildSSML(from: "The ATP molecule stores energy.")
        let hasEmphasis = ssml.contains("<emphasis>ATP</emphasis>")
        return TestResult(
            name: "ALL CAPS word mid-sentence gets emphasis after escaping",
            passed: hasEmphasis,
            detail: ssml
        )
    }

    private static func testQuestionSentenceHasBreakOutsideProsody() -> TestResult {
        // Break must appear as </prosody><break …/> — not inside the prosody element —
        // so the pause is outside the intonation arc.
        let ssml = SSMLBuilder.buildSSML(from: "Is ATP produced here?")
        let breakAfterProsody = ssml.contains("</prosody><break time=\"300ms\"/>")
        return TestResult(
            name: "Break tag appears after closing prosody tag on questions",
            passed: breakAfterProsody,
            detail: ssml
        )
    }
}
