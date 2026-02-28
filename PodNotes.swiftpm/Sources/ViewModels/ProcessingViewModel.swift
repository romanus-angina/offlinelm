import Foundation
import Observation
import SwiftData

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

    private let simulatedDelays: [ProcessingStage: ClosedRange<Double>] = [
        .extractingText:     0.8...1.4,
        .analyzingStructure: 0.6...1.0,
        .initializingModel:  1.2...1.8,
        .generatingTopics:   1.5...2.2,
        .generatingDialogue: 2.0...3.0,
        .generatingSlides:   1.8...2.6,
        .synthesizingAudio:  0.9...1.5,
    ]

    // MARK: - Pipeline

    // module and context are optional so the VM can still be used
    // standalone (debug views, tests) without a SwiftData stack.
    func simulatePipeline(module: StudyModule? = nil, context: ModelContext? = nil) async {
        logs         = []
        isComplete   = false
        errorMessage = nil

        // Mark the module as actively processing so the dashboard card
        // updates immediately rather than staying stuck on .importing.
        updateModuleStatus(.processing, module: module, context: context)

        for stage in ProcessingStage.workingStages {
            guard errorMessage == nil else { break }

            currentStage  = stage
            let entryID   = UUID()
            let startDate = Date()

            logs.append(LogEntry(
                id:        entryID,
                stage:     stage,
                message:   stage.label,
                status:    .inProgress,
                startedAt: startDate
            ))

            print("[ProcessingViewModel] stage started: \(stage.label)")

            let range = simulatedDelays[stage] ?? (1.0...1.5)
            let delay = Double.random(in: range)

            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                markFailed(id: entryID, startDate: startDate, error: error)
                updateModuleStatus(.failed, module: module, context: context)
                return
            }

            if let index = logs.firstIndex(where: { $0.id == entryID }) {
                logs[index].status         = .completed
                logs[index].elapsedSeconds = Date().timeIntervalSince(startDate)
            }

            print("[ProcessingViewModel] stage done: \(stage.label) in \(String(format: "%.1f", delay))s")
        }

        guard errorMessage == nil else { return }

        currentStage = .complete
        logs.append(LogEntry(
            id:             UUID(),
            stage:          .complete,
            message:        ProcessingStage.complete.label,
            status:         .completed,
            startedAt:      .now,
            elapsedSeconds: 0
        ))
        isComplete = true

        // Mark the module ready so the dashboard card shows the play button.
        updateModuleStatus(.ready, module: module, context: context)
        print("[ProcessingViewModel] pipeline complete, module status -> .ready")
    }

    func retry(module: StudyModule? = nil, context: ModelContext? = nil) async {
        await simulatePipeline(module: module, context: context)
    }

    // MARK: - Private helpers

    private func updateModuleStatus(
        _ status: ProcessingStatus,
        module: StudyModule?,
        context: ModelContext?
    ) {
        guard let module, let context else { return }
        module.status = status
        try? context.save()
    }

    private func markFailed(id: UUID, startDate: Date, error: Error) {
        if let index = logs.firstIndex(where: { $0.id == id }) {
            logs[index].status         = .failed
            logs[index].elapsedSeconds = Date().timeIntervalSince(startDate)
        }
        errorMessage = error.localizedDescription
    }
}
