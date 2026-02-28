import SwiftUI
import SwiftData

@available(iOS 26, *)
struct PodcastsListView: View {

    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router

    @Query(sort: \StudyModule.createdAt, order: .reverse)
    private var allModules: [StudyModule]

    private var readyModules: [StudyModule] {
        allModules.filter { $0.status == .ready }
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if readyModules.isEmpty {
                emptyState
            } else {
                podcastFeed
            }
        }
        .navigationTitle("Podcasts")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Podcast feed

    private var podcastFeed: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.sm) {
                ForEach(readyModules) { module in
                    PodcastRowView(module: module) {
                        router.push(.podcast(module))
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.md)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.Colors.backgroundTertiary)
                    .frame(width: 100, height: 100)
                Circle()
                    .strokeBorder(AppTheme.Colors.borderMedium, lineWidth: 1)
                    .frame(width: 100, height: 100)
                Image(systemName: "headphones")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(AppTheme.Gradients.spectrum)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("No podcasts yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text("Import a PDF from the Library tab\nto generate your first podcast.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button {
                router.switchToTab(.library)
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Go to Library")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(AppTheme.Colors.ana4)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(
                    Capsule()
                        .fill(AppTheme.Colors.ana4.opacity(0.12))
                        .overlay(
                            Capsule()
                                .strokeBorder(AppTheme.Colors.ana4.opacity(0.25), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(AppTheme.Spacing.xl)
    }
}

// MARK: - PodcastRowView

@available(iOS 26, *)
private struct PodcastRowView: View {

    let module: StudyModule
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.md) {
                // Waveform thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .fill(AppTheme.Gradients.card)
                        .frame(width: 56, height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                        )

                    waveformIcon
                }

                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(module.title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: AppTheme.Spacing.sm) {
                        Label(
                            "\(module.estimatedDurationMinutes) min",
                            systemImage: "clock"
                        )

                        Text("  ")

                        Label(
                            "\(module.dialogueSegments.count) segments",
                            systemImage: "text.bubble"
                        )
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textTertiary)

                    Text(module.formattedDate)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }

                Spacer()

                // Play indicator
                ZStack {
                    Circle()
                        .fill(AppTheme.Gradients.primary)
                        .frame(width: 40, height: 40)
                    Image(systemName: "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Color.white)
                        .offset(x: 1)
                }
                .shadow(color: AppTheme.Colors.glowAna1, radius: 6, x: 0, y: 3)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Colors.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                            .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PressScaleButtonStyle())
    }

    private var waveformIcon: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach([0.5, 0.8, 1.0, 0.7, 0.6] as [Double], id: \.self) { h in
                Capsule()
                    .fill(AppTheme.Colors.ana4.opacity(0.6))
                    .frame(width: 2.5, height: 16 * h)
            }
        }
    }
}

// MARK: - Press scale button style

private struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.85), value: configuration.isPressed)
    }
}
