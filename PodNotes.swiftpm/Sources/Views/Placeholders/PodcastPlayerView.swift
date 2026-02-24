import SwiftUI

@available(iOS 26, *)
struct PodcastPlayerView: View {
    let module: StudyModule
    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()
                albumArt
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text(module.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("Alex & Sam")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
                transportBar
                Spacer()
                Button(action: { router.showSlides(for: module) }) {
                    Label("View Slides", systemImage: "rectangle.on.rectangle")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.ana5)
                }
                .buttonStyle(.plain)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding(AppTheme.Spacing.xl)
        }
        .navigationTitle(module.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var albumArt: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(AppTheme.Gradients.card)
                .frame(width: 220, height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                        .strokeBorder(AppTheme.Colors.borderMedium, lineWidth: 1)
                )
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundStyle(AppTheme.Gradients.spectrum)
                Text("PodNotes")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
        .shadow(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 12)
    }

    private var transportBar: some View {
        HStack(spacing: AppTheme.Spacing.xl) {
            transportButton(icon: "backward.fill")
            playPauseButton
            transportButton(icon: "forward.fill")
        }
    }

    private func transportButton(icon: String) -> some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
    }

    private var playPauseButton: some View {
        Button(action: {}) {
            ZStack {
                Circle()
                    .fill(AppTheme.Gradients.primary)
                    .frame(width: 64, height: 64)
                Image(systemName: "play.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.white)
                    .offset(x: 2)
            }
        }
        .buttonStyle(.plain)
        .shadow(color: AppTheme.Colors.glowAna1, radius: 14, x: 0, y: 6)
    }
}
