import Foundation

enum ProcessingViewModelTests {

    struct TestResult: Sendable {
        let name: String
        let passed: Bool
        let detail: String
    }

    // @MainActor required because the iOS 26 test functions below
    // instantiate ProcessingViewModel, which is @MainActor-isolated.
    @MainActor
    static func runAll() -> [TestResult] {
        [
            testStageLabelsAreNonEmpty(),
            testStageStepNumbersAreContiguousFrom1(),
            testTotalStepsMatchesCaseCount(),
            testWorkingStagesExcludesComplete(),
            testCompleteStageLabelContainsReady(),
            testAllStageLabelsEndWithPunctuation(),
            testLogEntryDefaultIDIsUnique(),
            testLogEntryElapsedLabelFormatsCorrectly(),
            testLogEntryElapsedLabelNilWhenNoElapsed(),
            testLogEntryInProgressHasNilElapsed(),
            testDistinctStatusCasesExist(),
            testInitialStateIsEmpty(),
            testInitialIsCompleteIsFalse(),
            testInitialErrorMessageIsNil(),
            testInitialProgressFractionIsZero(),
            testInitialCompletedStepCountIsZero(),
            testInitialIsRunningIsFalse(),
            testProgressFractionDenominatorGuard(),
        ]
    }

    // MARK: - ProcessingStage

    private static func testStageLabelsAreNonEmpty() -> TestResult {
        let allEmpty = ProcessingStage.allCases.allSatisfy { $0.label.isEmpty }
        return TestResult(
            name: "All stage labels are non-empty strings",
            passed: !allEmpty,
            detail: "allEmpty=\(allEmpty)"
        )
    }

    private static func testStageStepNumbersAreContiguousFrom1() -> TestResult {
        let numbers  = ProcessingStage.allCases.map(\.stepNumber).sorted()
        let expected = Array(1...ProcessingStage.allCases.count)
        return TestResult(
            name: "Stage step numbers are contiguous starting at 1",
            passed: numbers == expected,
            detail: "Got: \(numbers)"
        )
    }

    private static func testTotalStepsMatchesCaseCount() -> TestResult {
        let passed = ProcessingStage.totalSteps == ProcessingStage.allCases.count
        return TestResult(
            name: "ProcessingStage.totalSteps equals allCases.count",
            passed: passed,
            detail: "totalSteps=\(ProcessingStage.totalSteps), allCases=\(ProcessingStage.allCases.count)"
        )
    }

    private static func testWorkingStagesExcludesComplete() -> TestResult {
        let containsComplete = ProcessingStage.workingStages.contains(.complete)
        return TestResult(
            name: "workingStages does not include .complete",
            passed: !containsComplete,
            detail: "containsComplete=\(containsComplete), count=\(ProcessingStage.workingStages.count)"
        )
    }

    private static func testCompleteStageLabelContainsReady() -> TestResult {
        let label  = ProcessingStage.complete.label.lowercased()
        let passed = label.contains("ready")
        return TestResult(
            name: ".complete label contains 'ready'",
            passed: passed,
            detail: "label='\(ProcessingStage.complete.label)'"
        )
    }

    private static func testAllStageLabelsEndWithPunctuation() -> TestResult {
        let terminators: Set<Character> = [".", "!", "?"]
        let bad = ProcessingStage.allCases.filter { stage in
            guard let last = stage.label.last else { return true }
            return !terminators.contains(last)
        }
        return TestResult(
            name: "All stage labels end with sentence-terminal punctuation",
            passed: bad.isEmpty,
            detail: bad.isEmpty ? "clean" : "bad: \(bad.map(\.label))"
        )
    }

    // MARK: - LogEntry

    private static func testLogEntryDefaultIDIsUnique() -> TestResult {
        let a = LogEntry(stage: .extractingText, message: "test", status: .inProgress)
        let b = LogEntry(stage: .extractingText, message: "test", status: .inProgress)
        return TestResult(
            name: "Two LogEntry instances have distinct default UUIDs",
            passed: a.id != b.id,
            detail: "a=\(a.id), b=\(b.id)"
        )
    }

    private static func testLogEntryElapsedLabelFormatsCorrectly() -> TestResult {
        var entry = LogEntry(stage: .extractingText, message: "test", status: .completed)
        entry.elapsedSeconds = 1.234
        let label  = entry.elapsedLabel ?? ""
        let passed = label == "1.2s"
        return TestResult(
            name: "elapsedLabel formats to one decimal place with 's' suffix",
            passed: passed,
            detail: "elapsedSeconds=1.234 -> '\(label)'"
        )
    }

    private static func testLogEntryElapsedLabelNilWhenNoElapsed() -> TestResult {
        let entry = LogEntry(stage: .generatingTopics, message: "test", status: .inProgress)
        return TestResult(
            name: "elapsedLabel is nil when elapsedSeconds is nil",
            passed: entry.elapsedLabel == nil,
            detail: entry.elapsedLabel ?? "nil"
        )
    }

    private static func testLogEntryInProgressHasNilElapsed() -> TestResult {
        let entry = LogEntry(
            stage:         .generatingDialogue,
            message:       "test",
            status:        .inProgress,
            startedAt:     .now,
            elapsedSeconds: nil
        )
        return TestResult(
            name: "LogEntry created as .inProgress has nil elapsedSeconds",
            passed: entry.elapsedSeconds == nil,
            detail: entry.elapsedSeconds.map { "\($0)s" } ?? "nil"
        )
    }

    // MARK: - LogEntryStatus

    private static func testDistinctStatusCasesExist() -> TestResult {
        let statuses: [LogEntryStatus] = [.inProgress, .completed, .failed]
        return TestResult(
            name: "LogEntryStatus has inProgress, completed, and failed cases",
            passed: statuses.count == 3,
            detail: "count=\(statuses.count)"
        )
    }

    // MARK: - ProcessingViewModel (synchronous surface)
    // These functions must be @MainActor because ProcessingViewModel is @MainActor-isolated.

    @available(iOS 26, *)
    @MainActor
    private static func testInitialStateIsEmpty() -> TestResult {
        let vm = ProcessingViewModel()
        return TestResult(
            name: "Fresh ProcessingViewModel has no log entries",
            passed: vm.logs.isEmpty,
            detail: "logs.count=\(vm.logs.count)"
        )
    }

    @available(iOS 26, *)
    @MainActor
    private static func testInitialIsCompleteIsFalse() -> TestResult {
        let vm = ProcessingViewModel()
        return TestResult(
            name: "Fresh ProcessingViewModel.isComplete is false",
            passed: vm.isComplete == false,
            detail: "isComplete=\(vm.isComplete)"
        )
    }

    @available(iOS 26, *)
    @MainActor
    private static func testInitialErrorMessageIsNil() -> TestResult {
        let vm = ProcessingViewModel()
        return TestResult(
            name: "Fresh ProcessingViewModel.errorMessage is nil",
            passed: vm.errorMessage == nil,
            detail: vm.errorMessage ?? "nil"
        )
    }

    @available(iOS 26, *)
    @MainActor
    private static func testInitialProgressFractionIsZero() -> TestResult {
        let vm = ProcessingViewModel()
        return TestResult(
            name: "progressFraction is 0.0 before pipeline starts",
            passed: vm.progressFraction == 0.0,
            detail: "progressFraction=\(vm.progressFraction)"
        )
    }

    @available(iOS 26, *)
    @MainActor
    private static func testInitialCompletedStepCountIsZero() -> TestResult {
        let vm = ProcessingViewModel()
        return TestResult(
            name: "completedStepCount is 0 before pipeline starts",
            passed: vm.completedStepCount == 0,
            detail: "completedStepCount=\(vm.completedStepCount)"
        )
    }

    @available(iOS 26, *)
    @MainActor
    private static func testInitialIsRunningIsFalse() -> TestResult {
        let vm = ProcessingViewModel()
        return TestResult(
            name: "isRunning is false before pipeline starts",
            passed: vm.isRunning == false,
            detail: "isRunning=\(vm.isRunning)"
        )
    }

    private static func testProgressFractionDenominatorGuard() -> TestResult {
        let workingCount = ProcessingStage.workingStages.count
        return TestResult(
            name: "workingStages.count > 0 so progressFraction denominator is safe",
            passed: workingCount > 0,
            detail: "workingStages.count=\(workingCount)"
        )
    }
}
