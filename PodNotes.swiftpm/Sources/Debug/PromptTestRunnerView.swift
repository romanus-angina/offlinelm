import SwiftUI

@available(iOS 26, *)
struct PromptTestRunnerView: View {

    @State private var results: [(suite: String, tests: [RunnerTestResult])] = []
    @State private var hasRun = false

    var body: some View {
        NavigationStack {
            List {
                if !hasRun {
                    Section {
                        Text("Tap Run to execute all test suites.")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }

                ForEach(results, id: \.suite) { group in
                    let passed = group.tests.filter(\.passed).count
                    Section("\(group.suite) — \(passed)/\(group.tests.count)") {
                        ForEach(group.tests, id: \.name) { result in
                            HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
                                Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(result.passed ? AppTheme.Colors.statusReady : AppTheme.Colors.statusFailed)
                                    .font(.system(size: 16))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.name)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundStyle(AppTheme.Colors.textPrimary)
                                    Text(result.detail)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundStyle(AppTheme.Colors.textTertiary)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.Colors.backgroundPrimary)
            .navigationTitle("Test Runner")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Run") {
                        Task {
                            await runAllSuites()
                        }
                    }
                }
            }
        }
    }

    private func runAllSuites() async {
        let slideDeckResults = SlideDeckViewModelTests.runAll().map { r in
            RunnerTestResult(name: r.name, passed: r.passed, detail: r.detail)
        }
        let processingResults = ProcessingViewModelTests.runAll().map { r in
            RunnerTestResult(name: r.name, passed: r.passed, detail: r.detail)
        }
        let speechResults = await SpeechServiceTests.runAll().map { r in
            RunnerTestResult(name: r.name, passed: r.passed, detail: r.detail)
        }
        let ssmlResults = SSMLBuilderTests.runAll().map { r in
            RunnerTestResult(name: r.name, passed: r.passed, detail: r.detail)
        }
//        let promptResults = PromptTemplateTests.runAll().map { r in
//            RunnerTestResult(name: r.name, passed: r.passed, detail: r.detail)
//        }
        let fallbackResults = FallbackGeneratorTests.runAll().map { r in
            RunnerTestResult(name: r.name, passed: r.passed, detail: r.detail)
        }

        results = [
            (suite: "SlideDeckViewModel",  tests: slideDeckResults),
            (suite: "ProcessingViewModel", tests: processingResults),
            (suite: "SpeechService",       tests: speechResults),
            (suite: "SSMLBuilder",         tests: ssmlResults),
//            (suite: "PromptTemplates",     tests: promptResults),
            (suite: "FallbackGenerator",   tests: fallbackResults),
        ]
        hasRun = true
    }
}

struct RunnerTestResult: Sendable {
    let name: String
    let passed: Bool
    let detail: String
}
