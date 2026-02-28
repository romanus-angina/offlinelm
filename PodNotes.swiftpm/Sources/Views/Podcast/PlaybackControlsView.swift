import SwiftUI

// MARK: - PlaybackControlsView

@available(iOS 26, *)
struct PlaybackControlsView: View {

    let isPlaying: Bool
    let progressFraction: Double
    let segmentPositionLabel: String
    let speaker: Speaker
    let onPlayPause: () -> Void
    let onSkipBack: () -> Void
    let onSkipForward: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            scrubberStrip
            transportRow
            positionLabel
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.top, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.xl)
        .background(
            Rectangle()
                .fill(AppTheme.Colors.backgroundPrimary)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(AppTheme.Colors.borderSubtle),
                    alignment: .top
                )
        )
    }

    // MARK: - Scrubber strip

    private var scrubberStrip: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.Colors.backgroundTertiary)
                    .frame(height: 3)

                Capsule()
                    .fill(PlayerPalette.accent(for: speaker))
                    .frame(width: max(0, geo.size.width * progressFraction), height: 3)

                Circle()
                    .fill(PlayerPalette.accent(for: speaker))
                    .frame(width: 12, height: 12)
                    .shadow(
                        color: PlayerPalette.glow(for: speaker),
                        radius: 6
                    )
                    .offset(x: max(0, geo.size.width * progressFraction - 6))
            }
        }
        .frame(height: 12)
        .animation(AppTheme.Motion.gentle, value: progressFraction)
        .animation(AppTheme.Motion.standard, value: speaker)
    }

    // MARK: - Transport row

    private var transportRow: some View {
        HStack(spacing: AppTheme.Spacing.xxl) {
            skipButton(icon: "backward.end.fill", action: onSkipBack)
            playPauseButton
            skipButton(icon: "forward.end.fill", action: onSkipForward)
        }
    }

    private func skipButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var playPauseButton: some View {
        Button(action: onPlayPause) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                PlayerPalette.accent(for: speaker),
                                PlayerPalette.accent(for: speaker).opacity(0.70)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .shadow(
                        color: PlayerPalette.glow(for: speaker),
                        radius: isPlaying ? 18 : 10,
                        x: 0, y: 4
                    )

                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.backgroundPrimary)
                    .offset(x: isPlaying ? 0 : 2)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.94))
        .animation(AppTheme.Motion.snappy, value: isPlaying)
        .animation(AppTheme.Motion.standard, value: speaker)
    }

    // MARK: - Position label

    private var positionLabel: some View {
        Text(segmentPositionLabel)
            .font(.system(size: 12, weight: .semibold, design: .monospaced))
            .foregroundStyle(AppTheme.Colors.textTertiary)
            .animation(AppTheme.Motion.standard, value: segmentPositionLabel)
    }
}

// MARK: - ScaleButtonStyle

private struct ScaleButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.90

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(AppTheme.Motion.snappy, value: configuration.isPressed)
    }
}

// MARK: - Previews

@available(iOS 26, *)
#Preview("Playing — Host A") {
    ZStack {
        AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
        VStack {
            Spacer()
            PlaybackControlsView(
                isPlaying: true,
                progressFraction: 0.35,
                segmentPositionLabel: "3 / 7",
                speaker: .hostA,
                onPlayPause: {},
                onSkipBack: {},
                onSkipForward: {}
            )
        }
    }
}

@available(iOS 26, *)
#Preview("Paused — Host B") {
    ZStack {
        AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
        VStack {
            Spacer()
            PlaybackControlsView(
                isPlaying: false,
                progressFraction: 0.71,
                segmentPositionLabel: "5 / 7",
                speaker: .hostB,
                onPlayPause: {},
                onSkipBack: {},
                onSkipForward: {}
            )
        }
    }
}
