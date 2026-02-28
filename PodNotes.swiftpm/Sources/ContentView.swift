import SwiftUI
import SwiftData

@available(iOS 26, *)
struct ContentView: View {

    @State private var router = AppRouter()
    @State private var vm     = ProcessingViewModel()
    @State private var started = false

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                // Status readout
                VStack(alignment: .leading, spacing: 4) {
                    statusLine("isComplete",        vm.isComplete ? "true" : "false")
                    statusLine("isRunning",         vm.isRunning ? "true" : "false")
                    statusLine("progressFraction",  String(format: "%.2f", vm.progressFraction))
                    statusLine("completedSteps",    "\(vm.completedStepCount)")
                    statusLine("error",             vm.errorMessage ?? "none")
                }
                .padding(AppTheme.Spacing.md)
                .background(AppTheme.Colors.backgroundSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))

                // Terminal
                TerminalLogView(logs: vm.logs)
                    .frame(maxHeight: 420)

                // Controls
                if !started {
                    Button("Run pipeline") {
                        started = true
                        Task { await vm.simulatePipeline() }
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .frame(height: 48)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .background(AppTheme.Gradients.primary)
                    .clipShape(Capsule())
                } else if vm.isComplete {
                    Button("Run again") {
                        started = false
                        Task {
                            try? await Task.sleep(nanoseconds: 100_000_000)
                            started = true
                            await vm.retry()
                        }
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.ana5)
                }
            }
            .padding(AppTheme.Spacing.md)
        }
    }

    private func statusLine(_ key: String, _ value: String) -> some View {
        HStack(spacing: 0) {
            Text(key + ": ")
                .foregroundStyle(AppTheme.Colors.textTertiary)
            Text(value)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        }
        .font(.system(.caption, design: .monospaced))
    }
}
