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

        // Bridge context flows from chunk N to chunk N+1 for continuity.
        // nil for the first chunk.
        var bridgeContext: String? = nil

        for chunk in chunks {
            let chunkResult = try await processChunk(
                chunk,
                moduleTitle: moduleTitle,
                bridgeContext: bridgeContext
            )

            // Convert dialogue turns to segments.
            for turn in chunkResult.script.turns {
                let speaker: Speaker = switch turn.speaker {
                case .hostA: .hostA
                case .hostB: .hostB
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

            // Convert slide entries to slides.
            for entry in chunkResult.slides.slides {
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

            // Build bridge context for the next chunk (deterministic, no LLM call).
            bridgeContext = PromptTemplates.buildBridgeSummary(
                topics: chunkResult.topics,
                lastTurns: Array(chunkResult.script.turns.suffix(2))
            )

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

    /// Holds all outputs from a single chunk so the caller can build
    /// bridge context and convert to domain models.
    private struct ChunkOutput: Sendable {
        let topics: TopicList
        let script: PodcastScript
        let slides: SlideSet
    }

    /// Per-chunk pipeline:
    /// 1. Extract topics (+ hookIdea)
    /// 2. Generate dialogue draft + slides in parallel
    /// 3. Refine dialogue (sequential after draft)
    private func processChunk(
        _ chunk: TextChunk,
        moduleTitle: String,
        bridgeContext: String?
    ) async throws -> ChunkOutput {

        // Call 1: Topic extraction (includes hookIdea).
        let topics = try await extractTopics(from: chunk)

        guard !topics.topics.isEmpty else {
            throw GenerationError.emptyOutput(chunkIndex: chunk.order)
        }

        let formatted = PromptTemplates.formatTopicsForPrompt(topics)

        // Slides run in parallel with dialogue + refinement.
        // The async let starts immediately; we await it after refinement.
        async let slidesTask = generateSlides(
            formattedTopics: formatted,
            chunkIndex: chunk.order
        )

        // Call 2: Generate dialogue draft.
        let draftScript = try await generateDialogue(
            formattedTopics: formatted,
            hookIdea: topics.hookIdea,
            moduleTitle: moduleTitle,
            bridgeContext: bridgeContext,
            chunkIndex: chunk.order
        )

        // Call 2b: Refine dialogue (self-critique pass).
        // Falls back to the draft if refinement fails (network of safety net).
        let refinedScript = await refineDialogue(
            draft: draftScript,
            moduleTitle: moduleTitle,
            chunkIndex: chunk.order
        )

        // Await slides (may already be done by now).
        let slides = try await slidesTask

        return ChunkOutput(
            topics: topics,
            script: refinedScript,
            slides: slides
        )
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

    // MARK: - Call 2: Podcast dialogue (draft)

    private func generateDialogue(
        formattedTopics: String,
        hookIdea: String,
        moduleTitle: String,
        bridgeContext: String?,
        chunkIndex: Int
    ) async throws(GenerationError) -> PodcastScript {
        let session = LanguageModelSession(
            instructions: PromptTemplates.podcastDialogueInstruction(moduleTitle: moduleTitle)
        )
        let prompt = PromptTemplates.podcastDialoguePrompt(
            formattedTopics: formattedTopics,
            hookIdea: hookIdea,
            bridgeContext: bridgeContext
        )

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

    // MARK: - Call 2b: Dialogue refinement (self-critique)

    /// Sends the draft script through a refinement pass on a fresh session.
    /// Returns the refined version, or falls back to the draft if
    /// refinement fails for any reason. This ensures the pipeline never
    /// breaks due to an optional quality pass.
    private func refineDialogue(
        draft: PodcastScript,
        moduleTitle: String,
        chunkIndex: Int
    ) async -> PodcastScript {
        do {
            let session = LanguageModelSession(
                instructions: PromptTemplates.dialogueRefinementInstruction(
                    moduleTitle: moduleTitle
                )
            )
            let prompt = PromptTemplates.dialogueRefinementPrompt(draftScript: draft)

            let response = try await session.respond(to: prompt, generating: PodcastScript.self)
            let refined = response.content

            // Sanity check: refinement should not return an empty script.
            guard !refined.turns.isEmpty else {
                return draft
            }
            return refined
        } catch {
            // Refinement is best-effort. If it fails (context window,
            // guardrail, timeout), we use the draft as-is.
            return draft
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
