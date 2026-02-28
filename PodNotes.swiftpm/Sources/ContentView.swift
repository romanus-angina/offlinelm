import SwiftUI
import SwiftData

@available(iOS 26, *)
struct ContentView: View {

    @State private var router = AppRouter()

    var body: some View {
        PipelineRunnerView()
    }
}

@available(iOS 26, *)
struct PipelineRunnerView: View {

    @State private var vm      = ProcessingViewModel()
    @State private var started = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        Text("isComplete:         \(vm.isComplete ? "true" : "false")")
                        Text("isRunning:          \(vm.isRunning ? "true" : "false")")
                        Text("progressFraction:   \(String(format: "%.2f", vm.progressFraction))")
                        Text("completedStepCount: \(vm.completedStepCount)")
                        Text("error:              \(vm.errorMessage ?? "none")")
                    }
                    .font(.system(.body, design: .monospaced))

                    Divider().padding(.vertical, 4)

                    ForEach(vm.logs) { entry in
                        HStack(alignment: .top, spacing: 8) {
                            Text(statusSymbol(entry.status))
                            Text(entry.message)
                            Spacer()
                            if let label = entry.elapsedLabel {
                                Text(label)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.system(.body, design: .monospaced))
                    }

                    if !started {
                        Button("Run pipeline") {
                            started = true
                            Task {
                                await vm.simulatePipeline()
                            }
                        }
                        .padding(.top, 12)
                    }
                }
                .padding()
            }
            .navigationTitle("Pipeline Debug")
        }
    }

    private func statusSymbol(_ status: LogEntryStatus) -> String {
        switch status {
        case .inProgress: return "[ ]"
        case .completed:  return "[x]"
        case .failed:     return "[!]"
        }
    }
}
