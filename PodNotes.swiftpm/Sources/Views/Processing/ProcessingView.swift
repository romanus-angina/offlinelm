import SwiftUI
import SwiftData
import UIKit

@available(iOS 26, *)
struct ProcessingView: View {

    let module: StudyModule

    @Environment(AppRouter.self)  private var router
    @Environment(\.modelContext)  private var context
    @State private var vm          = ProcessingViewModel()
    @State private var glowPulsing = false

    // Prepared once when the pipeline starts so the Taptic Engine
    // is warmed up well before the completion moment.
    private let haptic = UIImpactFeedbackGenerator(style: .heavy)

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.bottom, AppTheme.Spacing.lg)

                terminalWithGlow
                    .padding(.bottom, AppTheme.Spacing.md)

                progressSection
                    .padding(.bottom, AppTheme.Spacing.xl)

                actionSection
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.xl)
        }
        .navigationBarHidden(true)
        .task {
            haptic.prepare()
            await vm.runPipeline(module: module, context: context)
        }
        .onChange(of: vm.isComplete) { _, complete in
            guard complete else { return }
            stopGlow()
            haptic.impactOccurred(intensity: 1.0)
        }
        .onChange(of: vm.errorMessage) { _, message in
            guard message != nil else { return }
            stopGlow()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(module.title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text(statusSubtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .animation(AppTheme.Motion.standard, value: statusSubtitle)
        }
    }

    private var statusSubtitle: String {
        if vm.errorMessage != nil { return "Something went wrong." }
        if vm.isComplete          { return "Ready to listen." }
        return "Processing your document..."
    }

    // MARK: - Terminal + glow

    // The glow and the terminal scale together as one unit so the
    // shrink-on-complete feels physically cohesive.
    private var terminalWithGlow: some View {
        ZStack {
            glowLayer
            TerminalLogView(logs: vm.logs)
                .frame(maxHeight: 340)
        }
        .scaleEffect(vm.isComplete ? 0.97 : 1.0, anchor: .top)
        .animation(.spring(response: 0.50, dampingFraction: 0.72), value: vm.isComplete)
    }

    // A heavily blurred shape behind the terminal that pulses while
    // the pipeline is running, giving the impression of emitted energy.
    private var glowLayer: some View {
        RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
            .fill(AppTheme.Colors.ana1.opacity(0.45))
            .blur(radius: 36)
            .scaleEffect(glowPulsing ? 1.08 : 0.92)
            .opacity(glowPulsing ? 0.55 : 0.25)
            .padding(.horizontal, -AppTheme.Spacing.lg)
            // Glow fades away once the pipeline is no longer running.
            .opacity(vm.isRunning ? 1 : 0)
            .animation(AppTheme.Motion.gentle, value: vm.isRunning)
            .onAppear { startGlow() }
    }

    // MARK: - Progress

    private var progressSection: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            progressBar

            Text(stepLabel)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.textTertiary)
                .animation(AppTheme.Motion.standard, value: stepLabel)
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.Colors.backgroundTertiary)
                    .frame(height: 3)

                Capsule()
                    .fill(AppTheme.Gradients.primary)
                    .frame(width: geo.size.width * vm.progressFraction, height: 3)
                    .animation(.spring(response: 0.55, dampingFraction: 0.80), value: vm.progressFraction)
            }
        }
        .frame(height: 3)
    }

    private var stepLabel: String {
        if vm.isComplete { return "Complete" }
        let current = min(vm.currentStage.stepNumber, ProcessingStage.workingStages.count)
        let total   = ProcessingStage.workingStages.count
        return "Step \(current) of \(total)"
    }

    // MARK: - Action section

    private var actionSection: some View {
        ZStack {
            listenButton
            retrySection
        }
        .frame(height: 52)
    }

    private var listenButton: some View {
        Button {
            router.showPodcast(for: module)
        } label: {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "play.fill")
                    .font(.system(size: 15, weight: .bold))
                Text("Listen Now")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color.white)
            .frame(height: 52)
            .padding(.horizontal, AppTheme.Spacing.xl)
            .background(AppTheme.Gradients.primary)
            .clipShape(Capsule())
            .shadow(
                color: AppTheme.Colors.glowAna1,
                radius: vm.isComplete ? 18 : 0,
                x: 0, y: 6
            )
        }
        .buttonStyle(.plain)
        // Scale up from slightly small when it appears, giving a
        // counterweight feel against the terminal scaling down.
        .scaleEffect(vm.isComplete ? 1.0 : 0.88)
        .opacity(vm.isComplete ? 1.0 : 0.0)
        .offset(y: vm.isComplete ? 0 : 14)
        .animation(
            .spring(response: 0.48, dampingFraction: 0.68).delay(0.12),
            value: vm.isComplete
        )
        .disabled(!vm.isComplete)
    }

    private var retrySection: some View {
        let hasFailed = vm.errorMessage != nil

        return VStack(spacing: AppTheme.Spacing.sm) {
            if let message = vm.errorMessage {
                Text(message)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(AppTheme.Colors.statusFailed)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }

            Button {
                Task { await vm.retry(module: module, context: context) }
            } label: {
                Text("Retry")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.statusFailed)
                    .frame(height: 44)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .background(
                        Capsule()
                            .strokeBorder(AppTheme.Colors.statusFailed.opacity(0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .opacity(hasFailed ? 1 : 0)
        .offset(y: hasFailed ? 0 : 10)
        .animation(AppTheme.Motion.standard, value: hasFailed)
        .disabled(!hasFailed)
    }

    // MARK: - Glow animation

    private func startGlow() {
        withAnimation(
            .easeInOut(duration: 1.4).repeatForever(autoreverses: true)
        ) {
            glowPulsing = true
        }
    }

    // Stopping a repeatForever animation requires switching to a
    // non-repeating animation targeting the resting state, otherwise
    // the view snaps rather than settling.
    private func stopGlow() {
        withAnimation(.easeOut(duration: 0.6)) {
            glowPulsing = false
        }
    }
}
