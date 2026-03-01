import SwiftUI

@available(iOS 26, *)
struct FlashcardView: View {

    let module: StudyModule
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var currentIndex = 0
    @State private var selectedAnswers: [String: Int] = [:]
    @State private var showCompletion = false
    @State private var hasLoaded = false

    private var slides: [Slide] {
        module.slides.sorted()
    }

    private var currentSlide: Slide? {
        guard slides.indices.contains(currentIndex) else { return nil }
        return slides[currentIndex]
    }

    private var isCurrentAnswered: Bool {
        guard let slide = currentSlide else { return false }
        return selectedAnswers[slide.id.uuidString] != nil
    }

    private var progressFraction: Double {
        guard !slides.isEmpty else { return 0 }
        return Double(selectedAnswers.count) / Double(slides.count)
    }

    private var correctCount: Int {
        slides.reduce(0) { total, slide in
            guard let picked = selectedAnswers[slide.id.uuidString] else { return total }
            return total + (picked == slide.correctAnswerIndex ? 1 : 0)
        }
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
        .onAppear {
            guard !hasLoaded else { return }
            hasLoaded = true
            loadSavedProgress()
        }
    }

    // MARK: - Load / Save

    private func loadSavedProgress() {
        selectedAnswers = module.quizAnswers

        // If all questions are already answered, show completion.
        if !slides.isEmpty && selectedAnswers.count >= slides.count {
            showCompletion = true
            return
        }

        // Resume at the first unanswered question.
        if let firstUnanswered = slides.firstIndex(where: {
            selectedAnswers[$0.id.uuidString] == nil
        }) {
            currentIndex = firstUnanswered
        }
    }

    private func saveProgress() {
        module.quizAnswers = selectedAnswers
        try? context.save()
    }

    private func resetQuiz() {
        withAnimation(AppTheme.Motion.standard) {
            selectedAnswers.removeAll()
            currentIndex = 0
            showCompletion = false
            module.resetQuiz()
            try? context.save()
        }
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
                let picked = selectedAnswers[slide.id.uuidString]

                ScrollView {
                    FlashcardCardView(
                        slide: slide,
                        cardNumber: index + 1,
                        totalCards: slides.count,
                        selectedChoiceIndex: picked,
                        onSelectChoice: { choiceIndex in
                            withAnimation(AppTheme.Motion.standard) {
                                selectedAnswers[slide.id.uuidString] = choiceIndex
                            }
                            saveProgress()

                            if selectedAnswers.count == slides.count {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
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
                    let answered = selectedAnswers[slides[i].id.uuidString] != nil
                    let correct = selectedAnswers[slides[i].id.uuidString] == slides[i].correctAnswerIndex
                    Capsule()
                        .fill(
                            i == currentIndex
                                ? AppTheme.Colors.ana4
                                : answered
                                    ? (correct
                                        ? AppTheme.Colors.ana4.opacity(0.5)
                                        : AppTheme.Colors.statusFailed.opacity(0.5))
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

                Text("You got \(correctCount) out of \(slides.count) correct")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(
                        correctCount == slides.count
                            ? AppTheme.Colors.ana4
                            : AppTheme.Colors.ana5
                    )
                    .padding(.top, AppTheme.Spacing.xs)
            }

            HStack(spacing: AppTheme.Spacing.md) {
                Button {
                    resetQuiz()
                } label: {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Try Again")
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
    let selectedChoiceIndex: Int?
    let onSelectChoice: (Int) -> Void

    @State private var hintsExpanded = false

    private var hasAnswered: Bool { selectedChoiceIndex != nil }
    private var isCorrect: Bool { selectedChoiceIndex == slide.correctAnswerIndex }

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

                // Collapsible hints
                hintsSection

                // Divider
                Rectangle()
                    .fill(AppTheme.Colors.borderMedium)
                    .frame(height: 1)

                // Choices
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(Array(slide.choices.enumerated()), id: \.offset) { index, choice in
                        ChoiceButton(
                            index: index,
                            text: choice,
                            isCorrectAnswer: index == slide.correctAnswerIndex,
                            selectedIndex: selectedChoiceIndex,
                            onTap: {
                                onSelectChoice(index)
                            }
                        )
                    }
                }

                // Answer explanation (shown after answering)
                if hasAnswered {
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
                }
            }
            .padding(.horizontal, AppTheme.Spacing.lg)
            .padding(.bottom, AppTheme.Spacing.lg)
        }
        .cardSurface(cornerRadius: AppTheme.Radius.xl)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
        .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 12)
        .frame(maxWidth: 600)
    }

    // MARK: - Collapsible hints

    private var hintsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(AppTheme.Motion.snappy) {
                    hintsExpanded.toggle()
                }
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "lightbulb.max")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.ana5)

                    Text("HINTS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                        .tracking(1.2)

                    Spacer()

                    Image(systemName: hintsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
                .padding(.vertical, AppTheme.Spacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if hintsExpanded {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
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
                .padding(.bottom, AppTheme.Spacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - ChoiceButton

@available(iOS 26, *)
private struct ChoiceButton: View {

    let index: Int
    let text: String
    let isCorrectAnswer: Bool
    let selectedIndex: Int?
    let onTap: () -> Void

    private static let letters = ["A", "B", "C", "D"]

    private var isSelected: Bool {
        selectedIndex == index
    }

    private var isRevealed: Bool {
        selectedIndex != nil
    }

    // MARK: - Visual state

    private var fillColor: Color {
        guard isRevealed else {
            return AppTheme.Colors.backgroundTertiary
        }
        if isSelected && isCorrectAnswer {
            return AppTheme.Colors.ana4.opacity(0.15)
        }
        if isSelected && !isCorrectAnswer {
            return AppTheme.Colors.statusFailed.opacity(0.15)
        }
        if !isSelected && isCorrectAnswer {
            return AppTheme.Colors.ana4.opacity(0.15)
        }
        return AppTheme.Colors.backgroundTertiary
    }

    private var borderColor: Color {
        guard isRevealed else { return Color.clear }
        if isCorrectAnswer {
            return AppTheme.Colors.ana4.opacity(0.4)
        }
        if isSelected {
            return AppTheme.Colors.statusFailed.opacity(0.4)
        }
        return Color.clear
    }

    private var rowOpacity: Double {
        guard isRevealed else { return 1.0 }
        if isSelected || isCorrectAnswer { return 1.0 }
        return 0.35
    }

    private var statusIcon: String? {
        guard isRevealed else { return nil }
        if isSelected && isCorrectAnswer { return "checkmark" }
        if isSelected && !isCorrectAnswer { return "xmark" }
        if !isSelected && isCorrectAnswer { return "checkmark" }
        return nil
    }

    private var statusIconColor: Color {
        isCorrectAnswer ? AppTheme.Colors.ana4 : AppTheme.Colors.statusFailed
    }

    private var letterColor: Color {
        guard isRevealed else { return AppTheme.Colors.textPrimary }
        if isCorrectAnswer { return AppTheme.Colors.ana4 }
        if isSelected { return AppTheme.Colors.statusFailed }
        return AppTheme.Colors.textTertiary
    }

    private var letterBackground: Color {
        guard isRevealed else { return AppTheme.Colors.backgroundSecondary }
        if isCorrectAnswer { return AppTheme.Colors.ana4.opacity(0.2) }
        if isSelected { return AppTheme.Colors.statusFailed.opacity(0.2) }
        return AppTheme.Colors.backgroundSecondary
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.sm) {
                // Letter badge
                Text(Self.letters[index])
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(letterColor)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(letterBackground)
                    )

                // Choice text
                Text(text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: AppTheme.Spacing.xs)

                // Status icon
                if let icon = statusIcon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(statusIconColor)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .fill(fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .strokeBorder(borderColor, lineWidth: 1.5)
                    )
            )
            .opacity(rowOpacity)
        }
        .buttonStyle(.plain)
        .disabled(isRevealed)
    }
}
