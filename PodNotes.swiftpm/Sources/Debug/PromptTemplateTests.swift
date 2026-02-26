import Foundation

@available(iOS 26.0, *)
enum PromptTemplateTests {

    struct TestResult: Sendable {
        let name: String
        let passed: Bool
        let detail: String
    }

    static func runAll() -> [TestResult] {
        var results: [TestResult] = []
        results.append(testFormatTopicsProducesNumberedList())
        results.append(testFormatTopicsHandlesEmptyList())
        results.append(testFormatTopicsPreservesAllEntries())
        results.append(testTopicExtractionPromptContainsChunkText())
        results.append(testTopicExtractionPromptHasBoundaryMarkers())
        results.append(testDialoguePromptContainsFormattedTopics())
        results.append(testSlidePromptContainsFormattedTopics())
        results.append(testInstructionsAnchorToSourceText())
        results.append(testDialogueInstructionIncludesModuleTitle())
        results.append(testNoEmojisInPrompts())
        return results
    }

    // MARK: - formatTopicsForPrompt

    private static func testFormatTopicsProducesNumberedList() -> TestResult {
        let topics = makeSampleTopicList(count: 3)
        let output = PromptTemplates.formatTopicsForPrompt(topics)
        let lines = output.components(separatedBy: "\n")

        let startsCorrectly = lines[0].hasPrefix("1. ")
            && lines[1].hasPrefix("2. ")
            && lines[2].hasPrefix("3. ")

        return TestResult(
            name: "formatTopics produces numbered list",
            passed: lines.count == 3 && startsCorrectly,
            detail: "Got \(lines.count) lines, prefixes correct: \(startsCorrectly)"
        )
    }

    private static func testFormatTopicsHandlesEmptyList() -> TestResult {
        let topics = TopicList(topics: [])
        let output = PromptTemplates.formatTopicsForPrompt(topics)
        return TestResult(
            name: "formatTopics handles empty list",
            passed: output.isEmpty,
            detail: "Output: '\(output)'"
        )
    }

    private static func testFormatTopicsPreservesAllEntries() -> TestResult {
        let topics = makeSampleTopicList(count: 7)
        let output = PromptTemplates.formatTopicsForPrompt(topics)
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        return TestResult(
            name: "formatTopics preserves all 7 entries",
            passed: lines.count == 7,
            detail: "Expected 7 lines, got \(lines.count)"
        )
    }

    // MARK: - Prompt construction

    private static func testTopicExtractionPromptContainsChunkText() -> TestResult {
        let chunk = "Mitochondria are membrane-bound organelles."
        let prompt = PromptTemplates.topicExtractionPrompt(chunkText: chunk)
        return TestResult(
            name: "topicExtractionPrompt embeds chunk text",
            passed: prompt.contains(chunk),
            detail: "Chunk text \(prompt.contains(chunk) ? "found" : "missing")"
        )
    }

    private static func testTopicExtractionPromptHasBoundaryMarkers() -> TestResult {
        let prompt = PromptTemplates.topicExtractionPrompt(chunkText: "test")
        let hasStart = prompt.contains("--- STUDY NOTES ---")
        let hasEnd = prompt.contains("--- END ---")
        return TestResult(
            name: "topicExtractionPrompt has boundary markers",
            passed: hasStart && hasEnd,
            detail: "start: \(hasStart), end: \(hasEnd)"
        )
    }

    private static func testDialoguePromptContainsFormattedTopics() -> TestResult {
        let formatted = "1. Cells: Basic unit of life"
        let prompt = PromptTemplates.podcastDialoguePrompt(formattedTopics: formatted)
        return TestResult(
            name: "podcastDialoguePrompt embeds topics",
            passed: prompt.contains(formatted),
            detail: "Topics \(prompt.contains(formatted) ? "found" : "missing")"
        )
    }

    private static func testSlidePromptContainsFormattedTopics() -> TestResult {
        let formatted = "1. DNA: Carries genetic information"
        let prompt = PromptTemplates.slideGenerationPrompt(formattedTopics: formatted)
        return TestResult(
            name: "slideGenerationPrompt embeds topics",
            passed: prompt.contains(formatted),
            detail: "Topics \(prompt.contains(formatted) ? "found" : "missing")"
        )
    }

    // MARK: - Instruction quality

    private static func testInstructionsAnchorToSourceText() -> TestResult {
        let anchor = "ONLY"
        let topicHasAnchor = PromptTemplates.topicExtractionInstruction.contains(anchor)
        let dialogueHasAnchor = PromptTemplates.podcastDialogueInstruction(moduleTitle: "X").contains(anchor)
        let slideHasAnchor = PromptTemplates.slideGenerationInstruction.contains(anchor)
        let allAnchored = topicHasAnchor && dialogueHasAnchor && slideHasAnchor
        return TestResult(
            name: "All instructions anchor to source text",
            passed: allAnchored,
            detail: "topic: \(topicHasAnchor), dialogue: \(dialogueHasAnchor), slide: \(slideHasAnchor)"
        )
    }

    private static func testDialogueInstructionIncludesModuleTitle() -> TestResult {
        let title = "Biology Chapter 4"
        let instruction = PromptTemplates.podcastDialogueInstruction(moduleTitle: title)
        return TestResult(
            name: "Dialogue instruction includes module title",
            passed: instruction.contains(title),
            detail: "Title \(instruction.contains(title) ? "found" : "missing")"
        )
    }

    private static func testNoEmojisInPrompts() -> TestResult {
        let allText = [
            PromptTemplates.topicExtractionInstruction,
            PromptTemplates.podcastDialogueInstruction(moduleTitle: "Test"),
            PromptTemplates.slideGenerationInstruction,
            PromptTemplates.topicExtractionPrompt(chunkText: "test"),
            PromptTemplates.podcastDialoguePrompt(formattedTopics: "test"),
            PromptTemplates.slideGenerationPrompt(formattedTopics: "test")
        ].joined()

        let hasEmoji = allText.unicodeScalars.contains { scalar in
            (0x1F600...0x1F64F).contains(scalar.value) ||
            (0x1F300...0x1F5FF).contains(scalar.value) ||
            (0x1F680...0x1F6FF).contains(scalar.value) ||
            (0x1F900...0x1F9FF).contains(scalar.value) ||
            (0x2600...0x26FF).contains(scalar.value)
        }

        return TestResult(
            name: "No emojis in any prompt",
            passed: !hasEmoji,
            detail: hasEmoji ? "Emoji detected" : "Clean"
        )
    }

    // MARK: - Factories

    private static func makeSampleTopicList(count: Int) -> TopicList {
        let topics = (0..<count).map { i in
            Topic(name: "Topic \(i + 1)", summary: "Summary for topic \(i + 1).")
        }
        return TopicList(topics: topics)
    }
}
