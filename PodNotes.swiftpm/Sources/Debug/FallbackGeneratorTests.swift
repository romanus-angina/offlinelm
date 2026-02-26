import Foundation

enum FallbackGeneratorTests {

    struct TestResult: Sendable {
        let name: String
        let passed: Bool
        let detail: String
    }

    static func runAll() -> [TestResult] {
        var results: [TestResult] = []
        results.append(testProducesSegmentsAndSlides())
        results.append(testSpeakerAlternation())
        results.append(testSlideCountMatchesChunkCount())
        results.append(testSlideTitleIsFirstSentence())
        results.append(testSlideKeyPointsCappedAtThree())
        results.append(testSegmentOrderIsContiguous())
        results.append(testSSMLEscapesSpecialCharacters())
        results.append(testEmptyChunkProducesFallbackSlide())
        results.append(testMultipleChunksAccumulateOrder())
        results.append(testSingleSentenceChunk())
        return results
    }

    // MARK: - Tests

    private static func testProducesSegmentsAndSlides() -> TestResult {
        let chunks = [makeChunk("First paragraph.\n\nSecond paragraph.", order: 0)]
        let (segments, slides) = FallbackGenerator().generate(from: chunks)
        return TestResult(
            name: "Produces segments and slides",
            passed: !segments.isEmpty && !slides.isEmpty,
            detail: "segments: \(segments.count), slides: \(slides.count)"
        )
    }

    private static func testSpeakerAlternation() -> TestResult {
        let text = "Para one.\n\nPara two.\n\nPara three.\n\nPara four."
        let chunks = [makeChunk(text, order: 0)]
        let (segments, _) = FallbackGenerator().generate(from: chunks)

        let speakers = segments.map(\.speaker)
        let expected: [Speaker] = [.hostA, .hostB, .hostA, .hostB]
        let matches = speakers == expected

        return TestResult(
            name: "Speakers alternate hostA/hostB",
            passed: matches,
            detail: "Got: \(speakers.map(\.rawValue))"
        )
    }

    private static func testSlideCountMatchesChunkCount() -> TestResult {
        let chunks = [
            makeChunk("Chunk one content.", order: 0),
            makeChunk("Chunk two content.", order: 1),
            makeChunk("Chunk three content.", order: 2)
        ]
        let (_, slides) = FallbackGenerator().generate(from: chunks)
        return TestResult(
            name: "One slide per chunk",
            passed: slides.count == 3,
            detail: "Expected 3, got \(slides.count)"
        )
    }

    private static func testSlideTitleIsFirstSentence() -> TestResult {
        let text = "Cells are the basic unit. They contain organelles. Mitochondria produce energy."
        let chunks = [makeChunk(text, order: 0)]
        let (_, slides) = FallbackGenerator().generate(from: chunks)
        let title = slides.first?.title ?? ""
        return TestResult(
            name: "Slide title is first sentence",
            passed: title == "Cells are the basic unit.",
            detail: "Got: '\(title)'"
        )
    }

    private static func testSlideKeyPointsCappedAtThree() -> TestResult {
        let text = "First. Second. Third. Fourth. Fifth."
        let chunks = [makeChunk(text, order: 0)]
        let (_, slides) = FallbackGenerator().generate(from: chunks)
        let count = slides.first?.keyPoints.count ?? 0
        return TestResult(
            name: "Key points capped at 3",
            passed: count == 3,
            detail: "Got \(count) key points"
        )
    }

    private static func testSegmentOrderIsContiguous() -> TestResult {
        let text = "One.\n\nTwo.\n\nThree."
        let chunks = [makeChunk(text, order: 0)]
        let (segments, _) = FallbackGenerator().generate(from: chunks)
        let orders = segments.map(\.order)
        let expected = Array(0..<segments.count)
        return TestResult(
            name: "Segment orders are contiguous",
            passed: orders == expected,
            detail: "Got: \(orders)"
        )
    }

    private static func testSSMLEscapesSpecialCharacters() -> TestResult {
        let text = "pH < 7 & pH > 7 means \"acidic\" & 'basic'"
        let chunks = [makeChunk(text, order: 0)]
        let (segments, _) = FallbackGenerator().generate(from: chunks)
        let ssml = segments.first?.ssmlText ?? ""
        let hasRawAngle = ssml.contains("< 7") || ssml.contains("> 7")
        let hasEscaped = ssml.contains("&lt;") && ssml.contains("&gt;")
        return TestResult(
            name: "SSML escapes special characters",
            passed: !hasRawAngle && hasEscaped,
            detail: hasEscaped ? "Properly escaped" : "Raw characters found"
        )
    }

    private static func testEmptyChunkProducesFallbackSlide() -> TestResult {
        let chunks = [makeChunk("", order: 0)]
        let (_, slides) = FallbackGenerator().generate(from: chunks)
        let hasSlide = slides.count == 1
        let hasFallbackTitle = slides.first?.title.contains("Section") ?? false
        return TestResult(
            name: "Empty chunk produces fallback slide",
            passed: hasSlide && hasFallbackTitle,
            detail: "title: '\(slides.first?.title ?? "nil")'"
        )
    }

    private static func testMultipleChunksAccumulateOrder() -> TestResult {
        let chunks = [
            makeChunk("A.\n\nB.", order: 0),
            makeChunk("C.\n\nD.", order: 1)
        ]
        let (segments, _) = FallbackGenerator().generate(from: chunks)
        let orders = segments.map(\.order)
        let expected = [0, 1, 2, 3]
        return TestResult(
            name: "Segment order accumulates across chunks",
            passed: orders == expected,
            detail: "Got: \(orders)"
        )
    }

    private static func testSingleSentenceChunk() -> TestResult {
        let chunks = [makeChunk("Only one sentence here.", order: 0)]
        let (segments, slides) = FallbackGenerator().generate(from: chunks)
        let hasSegment = segments.count == 1
        let keyPointsFallback = slides.first?.keyPoints == ["Review this section."]
        return TestResult(
            name: "Single sentence chunk handled",
            passed: hasSegment && keyPointsFallback,
            detail: "segments: \(segments.count), fallback keyPoints: \(keyPointsFallback)"
        )
    }

    // MARK: - Factory

    private static func makeChunk(_ text: String, order: Int) -> TextChunk {
        TextChunk(id: UUID(), text: text, order: order, pageRange: nil)
    }
}
