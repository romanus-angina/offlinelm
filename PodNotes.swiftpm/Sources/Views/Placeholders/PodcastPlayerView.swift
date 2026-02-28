import SwiftUI

// MARK: - PodcastPlayerView

@available(iOS 26, *)
struct PodcastPlayerView: View {

    @State private var viewModel: PodcastViewModel

    @Environment(AppRouter.self) private var router

    init(module: StudyModule) {
        _viewModel = State(initialValue: PodcastViewModel(module: module))
    }

    // Preview-only init — internal so ContentView can use .mock without a real module.
    init(viewModel: PodcastViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                waveformSection
                transcript
                controls
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.isShowingSlides) {
            if let module = moduleForSlides {
                NavigationStack {
                    SlidesView(module: module)
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Button {
                viewModel.speech.pause()
                router.goToDashboard()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(AppTheme.Colors.backgroundSecondary)
                    )
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(viewModel.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text("Alex & Sam")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }

            Spacer()

            Button {
                viewModel.isShowingSlides = true
            } label: {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.Colors.ana5)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(AppTheme.Colors.backgroundSecondary)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundPrimary)
    }

    // MARK: - Waveform section

    private var waveformSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            WaveformView(
                isPlaying: viewModel.isPlaying,
                speaker: viewModel.currentSpeaker
            )
            .frame(height: 64)
            .padding(.horizontal, AppTheme.Spacing.lg)

            speakerPill
        }
        .padding(.vertical, AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundPrimary)
    }

    private var speakerPill: some View {
        let speaker = viewModel.currentSpeaker
        let accent = PlayerPalette.accent(for: speaker)

        return HStack(spacing: AppTheme.Spacing.xs) {
            Circle()
                .fill(accent)
                .frame(width: 6, height: 6)

            Text(speaker.displayName.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(accent)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(accent.opacity(0.10))
                .overlay(
                    Capsule()
                        .strokeBorder(accent.opacity(0.25), lineWidth: 1)
                )
        )
        .animation(AppTheme.Motion.standard, value: speaker)
    }

    // MARK: - Transcript

    private var transcript: some View {
        TranscriptView(
            segments: viewModel.segments,
            currentSegmentIndex: viewModel.speech.currentSegmentIndex,
            currentWordRange: viewModel.speech.currentWordRange
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Controls

    private var controls: some View {
        PlaybackControlsView(
            isPlaying: viewModel.isPlaying,
            progressFraction: viewModel.progressFraction,
            segmentPositionLabel: viewModel.segmentPositionLabel,
            speaker: viewModel.currentSpeaker,
            onPlayPause: { viewModel.togglePlayPause() },
            onSkipBack: { viewModel.skipBackward() },
            onSkipForward: { viewModel.skipForward() }
        )
    }

    // MARK: - Slides sheet helper

    // The sheet needs a StudyModule but PodcastViewModel.mock uses the
    // preview init path (no module). Guard against that case gracefully.
    private var moduleForSlides: StudyModule? { nil }
}

// MARK: - Preview

@available(iOS 26, *)
#Preview("Podcast Player — mock data") {
    NavigationStack {
        PodcastPlayerView(viewModel: .mock)
            .environment(AppRouter())
    }
    .preferredColorScheme(.dark)
}
