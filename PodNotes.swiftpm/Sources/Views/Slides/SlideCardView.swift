import SwiftUI

// MARK: - SlideCardView

@available(iOS 26, *)
struct SlideCardView: View {

    let slide: Slide

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            accentBar
            cardBody
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.xl))
        .overlay(cardBorder)
        .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 12)
        .frame(maxWidth: 600)
    }

    // MARK: - Accent bar

    // A thin gradient strip at the very top of the card -- the only
    // colour-forward element, so it reads as a deliberate accent rather
    // than decoration.
    private var accentBar: some View {
        LinearGradient(
            colors: [AppTheme.Colors.ana1, AppTheme.Colors.ana5],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 3)
    }

    // MARK: - Card body

    private var cardBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            titleSection
                .padding(.top, AppTheme.Spacing.lg)
                .padding(.horizontal, AppTheme.Spacing.lg)

            keyPointsSection
                .padding(.top, AppTheme.Spacing.md)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.bottom, AppTheme.Spacing.lg)
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        Text(slide.title)
            .font(.system(size: 22, weight: .bold, design: .rounded))
            .foregroundStyle(AppTheme.Colors.textPrimary)
            .lineLimit(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Key points

    private var keyPointsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            ForEach(Array(slide.keyPoints.enumerated()), id: \.offset) { index, point in
                KeyPointRow(index: index, text: point)
            }
        }
    }

    // MARK: - Card surface

    private var cardBackground: some View {
        // Subtle gradient: slightly lighter at top, darker at bottom.
        // Keeps the card from looking flat without competing with content.
        LinearGradient(
            colors: [
                Color(red: 0.13, green: 0.14, blue: 0.13),
                Color(red: 0.09, green: 0.10, blue: 0.09)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: AppTheme.Radius.xl)
            .strokeBorder(AppTheme.Colors.borderSubtle, lineWidth: 1)
    }
}

// MARK: - KeyPointRow

@available(iOS 26, *)
private struct KeyPointRow: View {

    let index: Int
    let text: String

    // Number badge cycles through two accent colours to add rhythm
    // across the list without becoming noise.
    private var numberColor: Color {
        index.isMultiple(of: 2) ? AppTheme.Colors.ana4 : AppTheme.Colors.ana5
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(numberColor)
                .frame(width: 16, alignment: .trailing)

            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview helpers

@available(iOS 26, *)
private enum PreviewData {
    static let cellSlide = Slide(
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
    )

    static let atpSlide = Slide(
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
    )
}

// MARK: - Previews

@available(iOS 26, *)
#Preview("Cell Structure") {
    ZStack {
        AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
        ScrollView {
            SlideCardView(slide: PreviewData.cellSlide)
                .padding(AppTheme.Spacing.xl)
        }
    }
    .preferredColorScheme(.dark)
}

@available(iOS 26, *)
#Preview("ATP - Long content") {
    ZStack {
        AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
        ScrollView {
            SlideCardView(slide: PreviewData.atpSlide)
                .padding(AppTheme.Spacing.xl)
        }
    }
    .preferredColorScheme(.dark)
}
