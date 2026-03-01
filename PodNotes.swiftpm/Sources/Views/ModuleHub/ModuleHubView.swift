import SwiftUI

@available(iOS 26, *)
struct ModuleHubView: View {

    let module: StudyModule

    @Environment(AppRouter.self) private var router
    @State private var isShowingChat = false

    private let gridColumns = [
        GridItem(.flexible(), spacing: AppTheme.Spacing.md),
        GridItem(.flexible(), spacing: AppTheme.Spacing.md)
    ]

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    headerSection
                    quickActionsGrid
                    statsRow
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $isShowingChat) {
            ChatView(module: module)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            // Back button
            HStack {
                Button {
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
            }

            Text(module.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .lineLimit(3)

            // Subtitle row
            HStack(spacing: AppTheme.Spacing.sm) {
                Text(module.formattedDate)

                Text("|")

                let segCount = module.dialogueSegments.count
                Text(segCount > 0 ? "\(segCount) segments" : "No segments")

                Text("|")

                let slideCount = module.slides.count
                Text(slideCount > 0 ? "\(slideCount) slides" : "No slides")
            }
            .font(.system(size: 12, weight: .medium, design: .monospaced))
            .foregroundStyle(AppTheme.Colors.textTertiary)

            // Accent bar
            AppTheme.Gradients.spectrum
                .frame(height: 3)
                .clipShape(Capsule())
        }
    }

    // MARK: - Quick Actions Grid

    private var quickActionsGrid: some View {
        LazyVGrid(columns: gridColumns, spacing: AppTheme.Spacing.md) {
            HubActionCard(
                icon: "headphones",
                label: "Listen",
                isDisabled: module.dialogueSegments.isEmpty
            ) {
                router.push(.podcast(module))
            }

            HubActionCard(
                icon: "questionmark.circle",
                label: "Quizzes",
                isDisabled: module.slides.isEmpty
            ) {
                router.push(.flashcard(module))
            }

            HubActionCard(
                icon: "text.book.closed",
                label: "Review",
                isDisabled: module.slides.isEmpty
            ) {
                router.push(.slides(module))
            }

            HubActionCard(
                icon: "bubble.left.and.text.bubble.right",
                label: "Ask",
                isDisabled: false
            ) {
                isShowingChat = true
            }
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            StatPill(
                icon: "clock",
                text: "\(module.estimatedDurationMinutes) min"
            )

            let wordCount = module.sourceText
                .split { $0.isWhitespace }
                .count
            if wordCount > 0 {
                StatPill(
                    icon: "text.word.spacing",
                    text: "\(formattedWordCount(wordCount)) words"
                )
            }
        }
    }

    // MARK: - Helpers

    private func formattedWordCount(_ count: Int) -> String {
        if count >= 1000 {
            let k = Double(count) / 1000.0
            return String(format: "%.1fk", k)
        }
        return "\(count)"
    }
}

// MARK: - HubActionCard

@available(iOS 26, *)
private struct HubActionCard: View {

    let icon: String
    let label: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(AppTheme.Gradients.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                            .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(HubCardButtonStyle())
        .opacity(isDisabled ? 0.40 : 1.0)
        .disabled(isDisabled)
    }
}

// MARK: - HubCardButtonStyle

private struct HubCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.85), value: configuration.isPressed)
    }
}

// MARK: - StatPill

@available(iOS 26, *)
private struct StatPill: View {

    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(text)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
        }
        .foregroundStyle(AppTheme.Colors.textTertiary)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(AppTheme.Colors.backgroundTertiary)
        )
    }
}
