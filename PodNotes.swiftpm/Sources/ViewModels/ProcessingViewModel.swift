import Foundation
import Observation
import SwiftData
import FoundationModels

// MARK: - ProcessingStage

enum ProcessingStage: CaseIterable, Sendable {
    case extractingText
    case analyzingStructure
    case initializingModel
    case generatingTopics
    case generatingDialogue
    case generatingSlides
    case synthesizingAudio
    case complete

    var label: String {
        switch self {
        case .extractingText:     return "Extracting text from PDF..."
        case .analyzingStructure: return "Analyzing document structure..."
        case .initializingModel:  return "Initializing language model..."
        case .generatingTopics:   return "Identifying key topics..."
        case .generatingDialogue: return "Writing podcast script..."
        case .generatingSlides:   return "Building study slides..."
        case .synthesizingAudio:  return "Preparing audio synthesis..."
        case .complete:           return "Your podcast is ready."
        }
    }

    var stepNumber: Int {
        switch self {
        case .extractingText:     return 1
        case .analyzingStructure: return 2
        case .initializingModel:  return 3
        case .generatingTopics:   return 4
        case .generatingDialogue: return 5
        case .generatingSlides:   return 6
        case .synthesizingAudio:  return 7
        case .complete:           return 8
        }
    }

    static var totalSteps: Int { allCases.count }

    static var workingStages: [ProcessingStage] {
        allCases.filter { $0 != .complete }
    }
}

// MARK: - LogEntryStatus

enum LogEntryStatus: Sendable {
    case inProgress
    case completed
    case failed
}

// MARK: - LogEntry

struct LogEntry: Identifiable, Sendable {
    let id: UUID
    let stage: ProcessingStage
    let message: String
    var status: LogEntryStatus
    let startedAt: Date
    var elapsedSeconds: TimeInterval?

    init(
        id: UUID = UUID(),
        stage: ProcessingStage,
        message: String,
        status: LogEntryStatus,
        startedAt: Date = .now,
        elapsedSeconds: TimeInterval? = nil
    ) {
        self.id             = id
        self.stage          = stage
        self.message        = message
        self.status         = status
        self.startedAt      = startedAt
        self.elapsedSeconds = elapsedSeconds
    }

    var elapsedLabel: String? {
        guard let seconds = elapsedSeconds else { return nil }
        return String(format: "%.1fs", seconds)
    }
}

// MARK: - ProcessingViewModel

@available(iOS 26, *)
@MainActor
@Observable
final class ProcessingViewModel {

    // MARK: - Public state

    private(set) var logs: [LogEntry]              = []
    private(set) var currentStage: ProcessingStage = .extractingText
    private(set) var isComplete: Bool              = false
    private(set) var errorMessage: String?         = nil

    var progressFraction: Double {
        let workingCount = Double(ProcessingStage.workingStages.count)
        guard workingCount > 0 else { return 0 }
        let completed = Double(logs.filter { $0.status == .completed && $0.stage != .complete }.count)
        return min(completed / workingCount, 1.0)
    }

    var completedStepCount: Int {
        logs.filter { $0.status == .completed }.count
    }

    var isRunning: Bool {
        !isComplete && errorMessage == nil && !logs.isEmpty
    }

    // MARK: - Private

    // Tracks the log entry ID for the currently in-progress stage so
    // the pipeline can complete or fail it without a linear scan.
    private var activeEntryID: UUID?

    // Tracks which generation sub-stage we are visually displaying.
    // Generation is a single service call but we present it as three
    // sequential stages (topics, dialogue, slides) for visual clarity.
    private var lastReportedGenerationStage: ProcessingStage?

    // MARK: - Pipeline

    func runPipeline(module: StudyModule, context: ModelContext) async {
        resetState()

        // If already processed, jump straight to complete.
        if module.status == .ready && !module.dialogueSegments.isEmpty {
            currentStage = .complete
            isComplete = true
            return
        }

        updateModuleStatus(.processing, module: module, context: context)

        // --- Stage 1: Extract text from PDF ---

        guard let pdfData = module.pdfData else {
            failPipeline("No PDF data found. Please re-import the document.")
            updateModuleStatus(.failed, module: module, context: context)
            return
        }

        beginStage(.extractingText)

        let extraction: PDFIngestionService.ExtractionResult
        do {
            let service = PDFIngestionService(ocrRenderScale: 2.0)
            extraction = try service.extract(from: pdfData)
        } catch {
            failCurrentStage(error.localizedDescription)
            updateModuleStatus(.failed, module: module, context: context)
            return
        }
        completeCurrentStage()

        // Improve the title if the PDF metadata has something better
        // than the filename-derived one we set at import time.
        let extractedTitle = extraction.suggestedTitle
        if extractedTitle != "Untitled" && !extractedTitle.isEmpty {
            module.title = extractedTitle
        }
        module.sourceText = extraction.fullText

        // --- Stage 2: Analyze structure (chunking) ---

        beginStage(.analyzingStructure)

        let chunker = TextChunker()
        let chunks = chunker.chunk(pageTexts: extraction.pageTexts)

        if chunks.isEmpty {
            failCurrentStage("No usable text could be extracted from the PDF.")
            updateModuleStatus(.failed, module: module, context: context)
            return
        }
        completeCurrentStage()

        print("[Pipeline] Extracted \(extraction.pageTexts.count) pages into \(chunks.count) chunks")

        // --- Stage 3: Check model availability ---

        beginStage(.initializingModel)

        let modelReady = checkModelAvailability()
        if !modelReady {
            appendWarning("Apple Intelligence unavailable. Using basic generation.")
        }
        completeCurrentStage()

        // --- Stages 4-6: Generate content ---
        // GenerationService handles topics, dialogue, and slides internally
        // per chunk. We map chunk progress onto three visual stages so the
        // terminal animation shows meaningful forward movement.

        beginStage(.generatingTopics)
        lastReportedGenerationStage = .generatingTopics

        var allSegments: [DialogueSegment] = []
        var allSlides: [Slide] = []
        var usedFallback = false

        if modelReady {
            let result = await generateWithAI(
                chunks: chunks,
                moduleTitle: module.title
            )
            if let generated = result {
                allSegments = generated.segments
                allSlides = generated.slides
            } else {
                // AI generation failed part-way through or entirely.
                // Fall back to deterministic generation.
                appendWarning("AI generation failed. Falling back to basic mode.")
                let fallback = FallbackGenerator().generate(from: chunks)
                allSegments = fallback.segments
                allSlides = fallback.slides
                usedFallback = true
            }
        } else {
            let fallback = FallbackGenerator().generate(from: chunks)
            allSegments = fallback.segments
            allSlides = fallback.slides
            usedFallback = true
        }

        // Make sure all three generation stages show as completed.
        advanceGenerationStagesTo(.generatingSlides)
        completeCurrentStage()

        if allSegments.isEmpty && allSlides.isEmpty {
            failPipeline("Generation produced no content.")
            updateModuleStatus(.failed, module: module, context: context)
            return
        }

        print("[Pipeline] Generated \(allSegments.count) segments, \(allSlides.count) slides (fallback: \(usedFallback))")

        // --- Stage 7: SSML enrichment ---

        beginStage(.synthesizingAudio)

        for i in allSegments.indices {
            let enrichedSSML = SSMLBuilder.buildSSML(from: allSegments[i].plainText)
            allSegments[i] = DialogueSegment(
                id: allSegments[i].id,
                speaker: allSegments[i].speaker,
                plainText: allSegments[i].plainText,
                ssmlText: enrichedSSML,
                order: allSegments[i].order
            )
        }
        completeCurrentStage()

        // --- Save results to SwiftData ---

        module.dialogueSegments = allSegments
        module.slides = allSlides
        saveContext(context)

        updateModuleStatus(.ready, module: module, context: context)

        // --- Complete ---

        currentStage = .complete
        logs.append(LogEntry(
            stage: .complete,
            message: ProcessingStage.complete.label,
            status: .completed,
            elapsedSeconds: 0
        ))
        isComplete = true

        print("[Pipeline] Complete. Module status -> .ready")
    }

    func retry(module: StudyModule, context: ModelContext) async {
        await runPipeline(module: module, context: context)
    }

    // MARK: - AI generation with progress tracking

    private func generateWithAI(
        chunks: [TextChunk],
        moduleTitle: String
    ) async -> GenerationResult? {
        let service = GenerationService()
        let totalChunks = chunks.count

        do {
            let result = try await service.generate(
                from: chunks,
                moduleTitle: moduleTitle
            ) { [weak self] progress in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    switch progress {
                    case .started:
                        break
                    case .chunkCompleted(let done, let total):
                        self.handleChunkProgress(completed: done, total: total)
                    case .finished:
                        break
                    case .failed(let error):
                        print("[Pipeline] Generation progress error: \(error.localizedDescription)")
                    }
                }
            }
            return result
        } catch {
            print("[Pipeline] GenerationService threw: \(error.localizedDescription)")
            return nil
        }
    }

    // Maps chunk completion count onto the three visual generation stages.
    // With 6 chunks the progression looks like:
    //   chunks 1-2 done  ->  .generatingTopics
    //   chunks 3-4 done  ->  .generatingDialogue
    //   chunks 5-6 done  ->  .generatingSlides
    private func handleChunkProgress(completed: Int, total: Int) {
        guard total > 0 else { return }
        let fraction = Double(completed) / Double(total)

        let targetStage: ProcessingStage
        if fraction <= 0.34 {
            targetStage = .generatingTopics
        } else if fraction <= 0.67 {
            targetStage = .generatingDialogue
        } else {
            targetStage = .generatingSlides
        }

        advanceGenerationStagesTo(targetStage)
    }

    // Advances from the current generation sub-stage to the target,
    // completing intermediate stages along the way. Ensures stages
    // only move forward, never backwards.
    private func advanceGenerationStagesTo(_ target: ProcessingStage) {
        let generationOrder: [ProcessingStage] = [
            .generatingTopics,
            .generatingDialogue,
            .generatingSlides
        ]

        guard let currentIdx = generationOrder.firstIndex(of: lastReportedGenerationStage ?? .generatingTopics),
              let targetIdx = generationOrder.firstIndex(of: target),
              targetIdx > currentIdx
        else { return }

        // Complete every stage between current and target, then begin the target.
        for i in (currentIdx + 1)...targetIdx {
            completeCurrentStage()
            beginStage(generationOrder[i])
            lastReportedGenerationStage = generationOrder[i]
        }
    }

    // MARK: - Model availability

    private func checkModelAvailability() -> Bool {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return true
        default:
            return false
        }
    }

    // MARK: - Stage lifecycle helpers

    private func beginStage(_ stage: ProcessingStage) {
        currentStage = stage
        let entry = LogEntry(
            stage: stage,
            message: stage.label,
            status: .inProgress
        )
        activeEntryID = entry.id
        logs.append(entry)
        print("[Pipeline] -> \(stage.label)")
    }

    private func completeCurrentStage() {
        guard let id = activeEntryID,
              let index = logs.firstIndex(where: { $0.id == id })
        else { return }

        logs[index].status = .completed
        logs[index].elapsedSeconds = Date().timeIntervalSince(logs[index].startedAt)
        activeEntryID = nil
    }

    private func failCurrentStage(_ message: String) {
        guard let id = activeEntryID,
              let index = logs.firstIndex(where: { $0.id == id })
        else { return }

        logs[index].status = .failed
        logs[index].elapsedSeconds = Date().timeIntervalSince(logs[index].startedAt)
        activeEntryID = nil
        errorMessage = message
    }

    private func failPipeline(_ message: String) {
        // If there is an active stage, fail it. Otherwise just record the error.
        if activeEntryID != nil {
            failCurrentStage(message)
        } else {
            errorMessage = message
        }
    }

    private func appendWarning(_ message: String) {
        // Insert a completed log entry as a non-stage informational line.
        // Reuses the current stage so it groups visually with the active work.
        let warning = LogEntry(
            stage: currentStage,
            message: message,
            status: .completed,
            elapsedSeconds: 0
        )
        logs.append(warning)
        print("[Pipeline] Warning: \(message)")
    }

    // MARK: - SwiftData helpers

    private func updateModuleStatus(
        _ status: ProcessingStatus,
        module: StudyModule,
        context: ModelContext
    ) {
        module.status = status
        saveContext(context)
    }

    private func saveContext(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            print("[Pipeline] SwiftData save error: \(error.localizedDescription)")
        }
    }

    // MARK: - Reset

    private func resetState() {
        logs = []
        currentStage = .extractingText
        isComplete = false
        errorMessage = nil
        activeEntryID = nil
        lastReportedGenerationStage = nil
    }
}
