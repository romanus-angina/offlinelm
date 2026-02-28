import SwiftUI
import SwiftData

@available(iOS 26, *)
struct StudyTabView: View {

    @Environment(\.modelContext) private var context
    @Environment(AppRouter.self) private var router

    @Query(sort: \StudyModule.createdAt, order: .reverse)
    private var allModules: [StudyModule]

    private var readyModules: [StudyModule] {
        allModules.filter { $0.status == .ready }
    }

    // Tracks which quiz answers have been revealed across all modules.
    // Stored in memory for now; could be persisted via @AppStorage if needed.
    @State private var answeredQuizIDs: Set<String> = []

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if readyModules.isEmpty {
                emptyState
            } else {
                studyList
            }
        }
        .navigationTitle("Study")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Study list

    private var studyList: some View {
        ScrollView {
            // Stats header
            statsHeader
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.sm)

            LazyVStack(spacing: AppTheme.Spacing.md) {
                ForEach(readyModules) { module in
                    let slides = module.slides.sorted()
                    if !slides.isEmpty {
                        StudyModuleSection(
                            module: module,
                            slides: slides,
                            answeredIDs: answeredQuizIDs,
                            onStartFlashcards: {
                                router.push(.flashcard(module))
                            }
                        )
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.md)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Stats header

    private var statsHeader: some View {
        let totalQuizzes = readyModules.reduce(0) { $0 + $1.slides.count }
        let answeredCount = answeredQuizIDs.count
        let progressFraction = totalQuizzes > 0
            ? Double(min(answeredCount, totalQuizzes)) / Double(totalQuizzes)
            : 0.0

        return HStack(spacing: AppTheme.Spacing.lg) {
            StatCard(
                value: "\(readyModules.count)",
                label: "Modules",
                icon: "book.closed",
                color: AppTheme.Colors.ana1
            )

            StatCard(
                value: "\(totalQuizzes)",
                label: "Quizzes",
                icon: "questionmark.circle",
                color: AppTheme.Colors.ana5
            )

            StatCard(
                value: "\(Int(progressFraction * 100))%",
                label: "Progress",
                icon: "chart.bar.fill",
                color: AppTheme.Colors.ana4
            )
        }
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
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundStyle(AppTheme.Gradients.spectrum)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("No study material yet")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text("Import and process a PDF to generate\nquizzes and flashcards automatically.")
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

// MARK: - StatCard

@available(iOS 26, *)
private struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textPrimary)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(AppTheme.Colors.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
                )
        )
    }
}

// MARK: - StudyModuleSection

@available(iOS 26, *)
private struct StudyModuleSection: View {

    let module: StudyModule
    let slides: [Slide]
    let answeredIDs: Set<String>
    let onStartFlashcards: () -> Void

    private var answeredCount: Int {
        slides.filter { answeredIDs.contains($0.id.uuidString) }.count
    }

    private var progressFraction: Double {
        guard !slides.isEmpty else { return 0 }
        return Double(answeredCount) / Double(slides.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Module header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(module.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.Colors.textPrimary)
                        .lineLimit(2)

                    Text("\(slides.count) quiz questions")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }

                Spacer()

                Button(action: onStartFlashcards) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "rectangle.on.rectangle.angled")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Study")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .background(AppTheme.Gradients.primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(AppTheme.Colors.backgroundTertiary)
                        .frame(height: 4)

                    Capsule()
                        .fill(AppTheme.Colors.ana4)
                        .frame(width: max(0, geo.size.width * progressFraction), height: 4)
                }
            }
            .frame(height: 4)

            // Topic preview chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(slides.prefix(5)) { slide in
                        Text(slide.title)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.Colors.textSecondary)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .background(
                                Capsule()
                                    .fill(AppTheme.Colors.backgroundTertiary)
                            )
                            .lineLimit(1)
                    }
                    if slides.count > 5 {
                        Text("+\(slides.count - 5) more")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
            }
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
}
