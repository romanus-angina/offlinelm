import SwiftUI

// MARK: - TerminalPalette

@available(iOS 26, *)
private enum TerminalPalette {
    static let background  = Color(red: 0.09, green: 0.10, blue: 0.09)
    static let border      = Color(red: 0.20, green: 0.28, blue: 0.22)
    static let textPrimary = AppTheme.Colors.textPrimary
    static let textMuted   = AppTheme.Colors.textTertiary
    static let amber       = Color(red: 0.95, green: 0.72, blue: 0.25)
    static let green       = AppTheme.Colors.ana5
    static let red         = AppTheme.Colors.statusFailed
}

// MARK: - StatusIndicatorView

@available(iOS 26, *)
private struct StatusIndicatorView: View {

    let status: LogEntryStatus

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            switch status {
            case .inProgress:
                spinner
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TerminalPalette.green)
                    .transition(.scale.combined(with: .opacity))
            case .failed:
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(TerminalPalette.red)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(width: 16, height: 16)
        .animation(AppTheme.Motion.snappy, value: status == .completed)
        .animation(AppTheme.Motion.snappy, value: status == .failed)
    }

    private var spinner: some View {
        Circle()
            .trim(from: 0.15, to: 0.85)
            .stroke(
                TerminalPalette.amber,
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(
                    .linear(duration: 0.75).repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}

// MARK: - TerminalLogRowView

@available(iOS 26, *)
struct TerminalLogRowView: View {

    let entry: LogEntry

    @State private var visible = false

    private var labelColor: Color {
        switch entry.status {
        case .inProgress: return TerminalPalette.textPrimary
        case .completed:  return TerminalPalette.textMuted
        case .failed:     return TerminalPalette.red
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            StatusIndicatorView(status: entry.status)

            Text(entry.message)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(labelColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(AppTheme.Motion.standard, value: entry.status == .completed)

            if let elapsed = entry.elapsedLabel {
                Text(elapsed)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(TerminalPalette.textMuted)
                    .transition(.opacity)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .opacity(visible ? 1 : 0)
        .offset(y: visible ? 0 : 10)
        .onAppear {
            withAnimation(AppTheme.Motion.standard) {
                visible = true
            }
        }
    }
}

// MARK: - TerminalLogView

@available(iOS 26, *)
struct TerminalLogView: View {

    let logs: [LogEntry]

    // Only show entries that are still in progress, have failed, or are the
    // final completion marker. Completed working-stage entries vanish so the
    // terminal stays focused on what is happening right now.
    private var visibleLogs: [LogEntry] {
        logs.filter { entry in
            switch entry.status {
            case .inProgress: return true
            case .failed:     return true
            case .completed:  return entry.stage == .complete
            }
        }
    }

    // Fires both when a new entry is appended (count goes up) and when a
    // working stage completes and disappears from visibleLogs (completedCount
    // goes up). Watching only logs.count would miss the removal trigger.
    private var completedCount: Int {
        logs.filter { $0.status == .completed }.count
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(visibleLogs) { entry in
                        TerminalLogRowView(entry: entry)
                            .id(entry.id)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal:   .move(edge: .top).combined(with: .opacity)
                                )
                            )

                        if entry.stage != .complete {
                            Divider()
                                .background(TerminalPalette.border.opacity(0.4))
                                .padding(.horizontal, AppTheme.Spacing.sm)
                        }
                    }
                }
                .padding(.vertical, AppTheme.Spacing.sm)
                .animation(AppTheme.Motion.standard, value: completedCount)
            }
            .scrollIndicators(.hidden)
            .background(TerminalPalette.background)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .strokeBorder(TerminalPalette.border, lineWidth: 1)
            )
            .onChange(of: completedCount) { _, _ in
                guard let last = visibleLogs.last else { return }
                withAnimation(AppTheme.Motion.gentle) {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - Previews

@available(iOS 26, *)
#Preview("Mid-pipeline — two done, one running") {
    let entries: [LogEntry] = [
        LogEntry(
            stage: .extractingText,
            message: "Extracting text from PDF...",
            status: .completed,
            elapsedSeconds: 1.1
        ),
        LogEntry(
            stage: .analyzingStructure,
            message: "Analyzing document structure...",
            status: .completed,
            elapsedSeconds: 0.8
        ),
        LogEntry(
            stage: .initializingModel,
            message: "Initializing language model...",
            status: .inProgress
        ),
    ]

    return ZStack {
        AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
        TerminalLogView(logs: entries)
            .padding(AppTheme.Spacing.md)
            .frame(height: 200)
    }
    .preferredColorScheme(.dark)
}

@available(iOS 26, *)
#Preview("Complete") {
    let entries: [LogEntry] = [
        LogEntry(
            stage: .synthesizingAudio,
            message: "Preparing audio synthesis...",
            status: .completed,
            elapsedSeconds: 1.2
        ),
        LogEntry(
            stage: .complete,
            message: "Your podcast is ready.",
            status: .completed,
            elapsedSeconds: 0
        ),
    ]

    return ZStack {
        AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
        TerminalLogView(logs: entries)
            .padding(AppTheme.Spacing.md)
            .frame(height: 120)
    }
    .preferredColorScheme(.dark)
}

@available(iOS 26, *)
#Preview("Failed") {
    let entries: [LogEntry] = [
        LogEntry(
            stage: .extractingText,
            message: "Extracting text from PDF...",
            status: .completed,
            elapsedSeconds: 1.1
        ),
        LogEntry(
            stage: .generatingDialogue,
            message: "Writing podcast script...",
            status: .failed
        ),
    ]

    return ZStack {
        AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
        TerminalLogView(logs: entries)
            .padding(AppTheme.Spacing.md)
            .frame(height: 160)
    }
    .preferredColorScheme(.dark)
}
