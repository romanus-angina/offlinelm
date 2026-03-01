import Foundation
import FoundationModels

@available(iOS 26.0, *)
enum GenerationError: LocalizedError, Sendable {
    case modelUnavailable(String)
    case contextWindowExceeded(chunkIndex: Int)
    case guardrailViolation(chunkIndex: Int)
    case emptyOutput(chunkIndex: Int)
    case unknown(chunkIndex: Int, underlying: any Error)

    var errorDescription: String? {
        switch self {
        case .modelUnavailable(let reason):
            return "On-device model unavailable: \(reason)"
        case .contextWindowExceeded(let i):
            return "Chunk \(i) exceeded the context window."
        case .guardrailViolation(let i):
            return "Chunk \(i) triggered a content guardrail."
        case .emptyOutput(let i):
            return "Model returned empty output for chunk \(i)."
        case .unknown(let i, let err):
            return "Chunk \(i) failed: \(err.localizedDescription)"
        }
    }
}

@available(iOS 26.0, *)
enum GenerationProgress: Sendable {
    case started(totalChunks: Int)
    case chunkCompleted(completedChunks: Int, totalChunks: Int)
    case finished(segmentCount: Int, slideCount: Int)
    case failed(GenerationError)
}

@available(iOS 26.0, *)
struct GenerationResult: Sendable {
    let segments: [DialogueSegment]
    let slides: [Slide]
}

@available(iOS 26.0, *)
struct GenerationService: Sendable {

    func generate(
        from chunks: [TextChunk],
        moduleTitle: String,
        onProgress: @Sendable @escaping (GenerationProgress) -> Void
    ) async throws -> GenerationResult {
        try checkAvailability()

        onProgress(.started(totalChunks: chunks.count))

        var allSegments: [DialogueSegment] = []
        var allSlides: [Slide] = []
        var segmentOrder = 0

        for chunk in chunks {
            let chunkResult = try await processChunk(
                chunk,
                moduleTitle: moduleTitle
            )

            for turn in chunkResult.script.turns {
                let speaker: Speaker = switch turn.speaker {
                case .alex: .hostA
                case .sam: .hostB
                }
                let segment = DialogueSegment(
                    speaker: speaker,
                    plainText: turn.text,
                    ssmlText: buildSSML(turn.text, speaker: speaker),
                    order: segmentOrder
                )
                allSegments.append(segment)
                segmentOrder += 1
            }

            for (slideIndex, entry) in chunkResult.slides.slides.enumerated() {
                let slide = Slide(
                    title: entry.title,
                    keyPoints: entry.keyPoints,
                    quizQuestion: entry.quizQuestion,
                    choices: entry.choices,
                    correctAnswerIndex: entry.correctAnswerIndex,
                    quizAnswer: entry.quizAnswer,
                    order: allSlides.count
                )
                allSlides.append(slide)
            }

            onProgress(.chunkCompleted(
                completedChunks: chunk.order + 1,
                totalChunks: chunks.count
            ))
        }

        onProgress(.finished(segmentCount: allSegments.count, slideCount: allSlides.count))
        return GenerationResult(segments: allSegments, slides: allSlides)
    }

    // MARK: - Availability

    private func checkAvailability() throws {
        let model = SystemLanguageModel.default
        guard model.availability == .available else {
            let reason: String
            switch model.availability {
            case .available:
                reason = ""
            case .unavailable(.deviceNotEligible):
                reason = "This device does not support Apple Intelligence."
            case .unavailable(.appleIntelligenceNotEnabled):
                reason = "Apple Intelligence is not enabled in Settings."
            case .unavailable(.modelNotReady):
                reason = "The model is still downloading or preparing."
            default:
                reason = "The on-device model is not available."
            }
            throw GenerationError.modelUnavailable(reason)
        }
    }

    // MARK: - Per-chunk pipeline

    private struct ChunkOutput: Sendable {
        let script: PodcastScript
        let slides: SlideSet
    }

    private func processChunk(
        _ chunk: TextChunk,
        moduleTitle: String
    ) async throws -> ChunkOutput {
        let topics = try await extractTopics(from: chunk)

        guard !topics.topics.isEmpty else {
            throw GenerationError.emptyOutput(chunkIndex: chunk.order)
        }

        let formatted = PromptTemplates.formatTopicsForPrompt(topics)

        async let script = generateDialogue(
            formattedTopics: formatted,
            moduleTitle: moduleTitle,
            chunkIndex: chunk.order
        )
        async let slides = generateSlides(
            formattedTopics: formatted,
            chunkIndex: chunk.order
        )

        return try await ChunkOutput(script: script, slides: slides)
    }

    // MARK: - Call 1: Topic extraction

    private func extractTopics(from chunk: TextChunk) async throws(GenerationError) -> TopicList {
        let session = LanguageModelSession(
            instructions: PromptTemplates.topicExtractionInstruction
        )
        let prompt = PromptTemplates.topicExtractionPrompt(chunkText: chunk.text)

        do {
            let response = try await session.respond(to: prompt, generating: TopicList.self)
            return response.content
        } catch let error as LanguageModelSession.GenerationError {
            throw mapSessionError(error, chunkIndex: chunk.order)
        } catch {
            throw .unknown(chunkIndex: chunk.order, underlying: error)
        }
    }

    // MARK: - Call 2: Podcast dialogue

    private func generateDialogue(
        formattedTopics: String,
        moduleTitle: String,
        chunkIndex: Int
    ) async throws(GenerationError) -> PodcastScript {
        let session = LanguageModelSession(
            instructions: PromptTemplates.podcastDialogueInstruction(moduleTitle: moduleTitle)
        )
        let prompt = PromptTemplates.podcastDialoguePrompt(formattedTopics: formattedTopics)

        do {
            let response = try await session.respond(to: prompt, generating: PodcastScript.self)
            let script = response.content
            guard !script.turns.isEmpty else {
                throw GenerationError.emptyOutput(chunkIndex: chunkIndex)
            }
            return script
        } catch let error as GenerationError {
            throw error
        } catch let error as LanguageModelSession.GenerationError {
            throw mapSessionError(error, chunkIndex: chunkIndex)
        } catch {
            throw .unknown(chunkIndex: chunkIndex, underlying: error)
        }
    }

    // MARK: - Call 3: Slides

    private func generateSlides(
        formattedTopics: String,
        chunkIndex: Int
    ) async throws(GenerationError) -> SlideSet {
        let session = LanguageModelSession(
            instructions: PromptTemplates.slideGenerationInstruction
        )
        let prompt = PromptTemplates.slideGenerationPrompt(formattedTopics: formattedTopics)

        do {
            let response = try await session.respond(to: prompt, generating: SlideSet.self)
            let slides = response.content
            guard !slides.slides.isEmpty else {
                throw GenerationError.emptyOutput(chunkIndex: chunkIndex)
            }
            return slides
        } catch let error as GenerationError {
            throw error
        } catch let error as LanguageModelSession.GenerationError {
            throw mapSessionError(error, chunkIndex: chunkIndex)
        } catch {
            throw .unknown(chunkIndex: chunkIndex, underlying: error)
        }
    }

    // MARK: - Error mapping

    private func mapSessionError(
        _ error: LanguageModelSession.GenerationError,
        chunkIndex: Int
    ) -> GenerationError {
        switch error {
        case .exceededContextWindowSize:
            return .contextWindowExceeded(chunkIndex: chunkIndex)
        case .guardrailViolation:
            return .guardrailViolation(chunkIndex: chunkIndex)
        default:
            return .unknown(chunkIndex: chunkIndex, underlying: error)
        }
    }

    // MARK: - SSML

    private func buildSSML(_ text: String, speaker: Speaker) -> String {
        let escaped = text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
        return "<speak><prosody rate=\"medium\">\(escaped)</prosody></speak>"
    }
}
