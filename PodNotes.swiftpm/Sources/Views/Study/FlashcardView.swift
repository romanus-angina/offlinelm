import SwiftUI

@available(iOS 26, *)
struct FlashcardView: View {

    let module: StudyModule
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex = 0
    @State private var revealedIDs: Set<UUID> = []
    @State private var showCompletion = false

    private var slides: [Slide] {
        module.slides.sorted()
    }

    private var currentSlide: Slide? {
        guard slides.indices.contains(currentIndex) else { return nil }
        return slides[currentIndex]
    }

    private var isCurrentRevealed: Bool {
        guard let slide = currentSlide else { return false }
        return revealedIDs.contains(slide.id)
    }

    private var progressFraction: Double {
        guard !slides.isEmpty else { return 0 }
        return Double(revealedIDs.count) / Double(slides.count)
    }

    var body: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if slides.isEmpty {
                emptyState
            } else if showCompletion {
                completionView
            } else {
                flashcardContent
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Flashcard content

    private var flashcardContent: some View {
        VStack(spacing: 0) {
            flashcardHeader
            progressBar
            cardArea
            navigationFooter
        }
    }

    // MARK: - Header

    private var flashcardHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(AppTheme.Colors.textSecondary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(module.title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineLimit(1)

            Spacer()

            Text("\(currentIndex + 1) / \(slides.count)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.textTertiary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(AppTheme.Colors.backgroundTertiary)
                    .frame(height: 3)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.Colors.ana1, AppTheme.Colors.ana5],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(0, geo.size.width * progressFraction), height: 3)
                    .animation(AppTheme.Motion.gentle, value: progressFraction)
            }
        }
        .frame(height: 3)
    }

    // MARK: - Card area

    private var cardArea: some View {
        TabView(selection: $currentIndex) {
            ForEach(slides.indices, id: \.self) { index in
                let slide = slides[index]
                let revealed = revealedIDs.contains(slide.id)

                ScrollView {
                    FlashcardCardView(
                        slide: slide,
                        cardNumber: index + 1,
                        totalCards: slides.count,
                        isRevealed: revealed,
                        onReveal: {
                            withAnimation(AppTheme.Motion.standard) {
                                revealedIDs.insert(slide.id)
                            }
                            // Check if all revealed
                            if revealedIDs.count == slides.count {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    withAnimation(AppTheme.Motion.standard) {
                                        showCompletion = true
                                    }
                                }
                            }
                        }
                    )
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.lg)
                }
                .scrollIndicators(.hidden)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }

    // MARK: - Navigation footer

    private var navigationFooter: some View {
        HStack(spacing: AppTheme.Spacing.xl) {
            Button {
                withAnimation(AppTheme.Motion.standard) {
                    currentIndex = max(0, currentIndex - 1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        currentIndex == 0
                            ? AppTheme.Colors.textTertiary
                            : AppTheme.Colors.textPrimary
                    )
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(currentIndex == 0)

            Spacer()

            // Dot indicators
            HStack(spacing: AppTheme.Spacing.xs) {
                ForEach(slides.indices, id: \.self) { i in
                    let isAnswered = revealedIDs.contains(slides[i].id)
                    Capsule()
                        .fill(
                            i == currentIndex
                                ? AppTheme.Colors.ana4
                                : isAnswered
                                    ? AppTheme.Colors.ana4.opacity(0.4)
                                    : AppTheme.Colors.textTertiary.opacity(0.3)
                        )
                        .frame(
                            width: i == currentIndex ? 16 : 6,
                            height: 6
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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        currentIndex >= slides.count - 1
                            ? AppTheme.Colors.textTertiary
                            : AppTheme.Colors.textPrimary
                    )
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(currentIndex >= slides.count - 1)
        }
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.vertical, AppTheme.Spacing.md)
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

    // MARK: - Completion view

    private var completionView: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.Colors.ana1.opacity(0.15))
                    .frame(width: 120, height: 120)

                Circle()
                    .strokeBorder(AppTheme.Colors.ana4, lineWidth: 2)
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(AppTheme.Colors.ana4)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("All Done!")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)

                Text("You reviewed all \(slides.count) cards\nfor \(module.title).")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            HStack(spacing: AppTheme.Spacing.md) {
                Button {
                    withAnimation(AppTheme.Motion.standard) {
                        revealedIDs.removeAll()
                        currentIndex = 0
                        showCompletion = false
                    }
                } label: {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Study Again")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(AppTheme.Colors.ana4)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .frame(height: 48)
                    .background(
                        Capsule()
                            .strokeBorder(AppTheme.Colors.ana4.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, AppTheme.Spacing.xl)
                        .frame(height: 48)
                        .background(AppTheme.Gradients.primary)
                        .clipShape(Capsule())
                        .shadow(color: AppTheme.Colors.glowAna1, radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.xl)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "rectangle.on.rectangle.slash")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(AppTheme.Colors.textTertiary)
            Text("No flashcards available")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
    }
}

// MARK: - FlashcardCardView

@available(iOS 26, *)
private struct FlashcardCardView: View {

    let slide: Slide
    let cardNumber: Int
    let totalCards: Int
    let isRevealed: Bool
    let onReveal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Accent bar
            LinearGradient(
                colors: [AppTheme.Colors.ana1, AppTheme.Colors.ana5],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 3)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                // Topic badge
                Text(slide.title)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.Colors.ana4)
                    .textCase(.uppercase)
                    .tracking(0.8)
                    .padding(.top, AppTheme.Spacing.lg)

                // Question
                Text(slide.quizQuestion)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                // Key points hint
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("HINTS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                        .tracking(1.2)

                    ForEach(Array(slide.keyPoints.enumerated()), id: \.offset) { index, point in
                        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                            Text("\(index + 1)")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(
                                    index.isMultiple(of: 2)
                                        ? AppTheme.Colors.ana4
                                        : AppTheme.Colors.ana5
                                )
                                .frame(width: 16, alignment: .trailing)

                            Text(point)
                                .font(.system(size: 14))
                                .foregroundStyle(AppTheme.Colors.textSecondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                // Divider
                Rectangle()
                    .fill(AppTheme.Colors.borderMedium)
                    .frame(height: 1)

                // Answer section
                if isRevealed {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("ANSWER")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(AppTheme.Colors.ana4)
                            .tracking(1.5)

                        Text(slide.quizAnswer)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.Colors.textPrimary)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(AppTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                            .fill(AppTheme.Colors.ana1.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                    .strokeBorder(AppTheme.Colors.ana1.opacity(0.20), lineWidth: 1)
                            )
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Button(action: onReveal) {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Image(systemName: "eye")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Reveal Answer")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(AppTheme.Colors.ana5)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                .fill(AppTheme.Colors.ana5.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                        .strokeBorder(AppTheme.Colors.ana5.opacity(0.25), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.lg)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.13, green: 0.14, blue: 0.13),
                            Color(red: 0.09, green: 0.10, blue: 0.09)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
                .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 12)
        .frame(maxWidth: 600)
    }
}
