import SwiftUI

@available(iOS 26, *)
struct SlideCardDebugView: View {

    @State private var currentIndex = 0
    @State private var revealedIDs: Set<UUID> = []

    private let slides: [Slide] = [
        Slide(
            title: "Cell Structure and Function",
            keyPoints: [
                "Every living organism is composed of one or more cells.",
                "The cell membrane regulates what enters and exits the cell.",
                "Organelles carry out specialised functions within the cell.",
                "Prokaryotic cells lack a membrane-bound nucleus."
            ],
            quizQuestion: "What is the primary role of the cell membrane?",
            quizAnswer: "The cell membrane acts as a selective barrier, controlling the movement of substances into and out of the cell.",
            order: 0
        ),
        Slide(
            title: "ATP and Cellular Respiration",
            keyPoints: [
                "ATP is the primary energy currency of the cell.",
                "Glucose is oxidised through glycolysis, the Krebs cycle, and the electron transport chain.",
                "Mitochondria are the primary site of ATP production in eukaryotes.",
                "Up to 30-32 ATP molecules are produced per glucose in aerobic respiration."
            ],
            quizQuestion: "Why are mitochondria described as the powerhouse of the cell?",
            quizAnswer: "Mitochondria produce the majority of a cell's ATP through aerobic cellular respiration, converting chemical energy from glucose into a usable form.",
            order: 1
        ),
        Slide(
            title: "DNA and Genetic Information",
            keyPoints: [
                "DNA stores genetic instructions in a double-helix structure.",
                "Genes are segments of DNA that encode specific proteins.",
                "DNA replication occurs before a cell divides.",
                "Mutations are permanent changes to the DNA sequence."
            ],
            quizQuestion: "What is the relationship between DNA, genes, and proteins?",
            quizAnswer: "Genes are sequences within DNA that are transcribed into RNA and then translated into proteins, which carry out most cellular functions.",
            order: 2
        ),
    ]

    private var currentSlide: Slide { slides[currentIndex] }
    private var isCurrentRevealed: Bool { revealedIDs.contains(currentSlide.id) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
                VStack(spacing: 0) {
                    debugStatusBar
                    SlideCardScroller(
                        slide: currentSlide,
                        isRevealed: isCurrentRevealed,
                        onReveal: {
                            withAnimation(AppTheme.Motion.standard) {
                                _ = revealedIDs.insert(currentSlide.id)
                            }
                        }
                    )
                    debugNavBar
                }
            }
            .navigationTitle("SlideCard Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: debugToolbar)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private func debugToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Reset") {
                withAnimation(AppTheme.Motion.standard) {
                    revealedIDs.removeAll()
                    currentIndex = 0
                }
            }
            .foregroundStyle(AppTheme.Colors.ana4)
        }
    }

    // MARK: - Status bar

    private var debugStatusBar: some View {
        HStack {
            Text("Slide \(currentIndex + 1) of \(slides.count)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.textTertiary)
            Spacer()
            Text(isCurrentRevealed ? "Answer revealed" : "Answer hidden")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundStyle(
                    isCurrentRevealed
                        ? AppTheme.Colors.ana4
                        : AppTheme.Colors.textTertiary
                )
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundSecondary)
    }

    // MARK: - Nav bar

    private var debugNavBar: some View {
        HStack(spacing: AppTheme.Spacing.xl) {
            Button {
                withAnimation(AppTheme.Motion.standard) {
                    currentIndex = max(0, currentIndex - 1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        currentIndex == 0
                            ? AppTheme.Colors.textTertiary
                            : AppTheme.Colors.textPrimary
                    )
                    .frame(width: 52, height: 52)
            }
            .buttonStyle(.plain)
            .disabled(currentIndex == 0)

            Spacer()

            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(slides.indices, id: \.self) { i in
                    Circle()
                        .fill(
                            i == currentIndex
                                ? AppTheme.Colors.ana4
                                : AppTheme.Colors.textTertiary
                        )
                        .frame(
                            width:  i == currentIndex ? 8 : 5,
                            height: i == currentIndex ? 8 : 5
                        )
                        .animation(AppTheme.Motion.snappy, value: currentIndex)
                }
            }

            Spacer()

            Button {
                withAnimation(AppTheme.Motion.standard) {
                    currentIndex = min(slides.count - 1, currentIndex + 1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        currentIndex == slides.count - 1
                            ? AppTheme.Colors.textTertiary
                            : AppTheme.Colors.textPrimary
                    )
                    .frame(width: 52, height: 52)
            }
            .buttonStyle(.plain)
            .disabled(currentIndex == slides.count - 1)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
        .background(AppTheme.Colors.backgroundSecondary)
    }
}

// MARK: - SlideCardScroller
// Dedicated struct so SwiftUI resolves ScrollView unambiguously.

@available(iOS 26, *)
private struct SlideCardScroller: View {

    let slide: Slide
    let isRevealed: Bool
    let onReveal: () -> Void

    var body: some View {
        ScrollView {
            SlideCardView(
                slide: slide,
                isAnswerRevealed: isRevealed,
                onReveal: onReveal
            )
            .padding(AppTheme.Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }
}
