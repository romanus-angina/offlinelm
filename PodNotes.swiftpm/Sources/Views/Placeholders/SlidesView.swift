import SwiftUI

@available(iOS 26, *)
struct SlidesView: View {
    let module: StudyModule
    @Environment(AppRouter.self) private var router

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()
                deckIcon
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text(module.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    Text("\(module.slides.count) slides generated")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
                placeholderCard
                Spacer()
                Button(action: { router.showPodcast(for: module) }) {
                    Label("Back to Podcast", systemImage: "waveform")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.ana1)
                }
                .buttonStyle(.plain)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding(AppTheme.Spacing.xl)
        }
        .navigationTitle("Slides")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var deckIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                .fill(AppTheme.Colors.backgroundTertiary)
                .frame(width: 80, height: 80)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                        .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                )
            Image(systemName: "rectangle.on.rectangle.angled")
                .font(.system(size: 32, weight: .thin))
                .foregroundStyle(AppTheme.Colors.ana5)
        }
    }

    private var placeholderCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("Slide deck viewer")
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.ana5)
            Text("Key concepts, bullet points, and\nquiz questions will appear here once\nthe generation pipeline is wired up.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.lg)
        .cardSurface()
    }
}
