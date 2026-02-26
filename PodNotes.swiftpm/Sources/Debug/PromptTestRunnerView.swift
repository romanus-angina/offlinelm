import SwiftUI

@available(iOS 26, *)
struct PromptTestRunnerView: View {

    @State private var results: [PromptTemplateTests.TestResult] = []
    @State private var hasRun = false

    var body: some View {
        NavigationStack {
            List {
                if !hasRun {
                    Section {
                        Text("Tap Run to execute all prompt template tests.")
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                    }
                }

                if hasRun {
                    Section("Results: \(passCount)/\(results.count) passed") {
                        ForEach(results, id: \.name) { result in
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
            .navigationTitle("Prompt Tests")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Run") {
                        results = PromptTemplateTests.runAll()
                        hasRun = true
                    }
                }
            }
        }
    }

    private var passCount: Int {
        results.filter(\.passed).count
    }
}
