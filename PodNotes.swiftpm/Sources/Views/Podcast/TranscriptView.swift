import SwiftUI

// MARK: - TranscriptView

@available(iOS 26, *)
struct TranscriptView: View {

    let segments: [DialogueSegment]
    let currentSegmentIndex: Int
    let currentWordRange: Range<String.Index>?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(segments) { segment in
                        let isActive = segment.order == currentSegmentIndex
                        SegmentRow(
                            segment: segment,
                            isActive: isActive,
                            wordRange: isActive ? currentWordRange : nil
                        )
                        .id(segment.id)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.lg)
            }
            .scrollIndicators(.hidden)
            .onChange(of: currentSegmentIndex) { _, _ in
                guard let target = segments[safe: currentSegmentIndex] else { return }
                withAnimation(AppTheme.Motion.gentle) {
                    proxy.scrollTo(target.id, anchor: .center)
                }
            }
        }
    }
}

// MARK: - SegmentRow

@available(iOS 26, *)
private struct SegmentRow: View {

    let segment: DialogueSegment
    let isActive: Bool
    let wordRange: Range<String.Index>?

    private var accentColor: Color {
        PlayerPalette.accent(for: segment.speaker)
    }

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            speakerColumn
            textColumn
        }
        .padding(AppTheme.Spacing.md)
        .background(rowBackground)
        .animation(AppTheme.Motion.standard, value: isActive)
    }

    // MARK: - Speaker column

    private var speakerColumn: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Circle()
                .fill(isActive ? accentColor : accentColor.opacity(0.20))
                .frame(width: 8, height: 8)
                .shadow(
                    color: isActive ? PlayerPalette.glow(for: segment.speaker) : .clear,
                    radius: 6
                )
                .padding(.top, 6)

            Text(segment.speaker.displayName.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(isActive ? accentColor : AppTheme.Colors.textTertiary)
                .fixedSize()
        }
        .frame(width: 36)
        .animation(AppTheme.Motion.snappy, value: isActive)
    }

    // MARK: - Text column

    @ViewBuilder
    private var textColumn: some View {
        if let range = wordRange {
            highlightedText(range: range)
        } else {
            plainText
        }
    }

    private var plainText: some View {
        Text(segment.plainText)
            .font(.system(size: isActive ? 16 : 15))
            .foregroundStyle(
                isActive ? AppTheme.Colors.textPrimary : AppTheme.Colors.textTertiary
            )
            .lineSpacing(5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(AppTheme.Motion.standard, value: isActive)
    }

    private func highlightedText(range: Range<String.Index>) -> some View {
        let text   = segment.plainText
        let before = String(text[text.startIndex..<range.lowerBound])
        let word   = String(text[range])
        let after  = String(text[range.upperBound..<text.endIndex])

        return (
            Text(before)
                .foregroundStyle(AppTheme.Colors.textPrimary)
            + Text(word)
                .foregroundStyle(accentColor)
                .fontWeight(.semibold)
            + Text(after)
                .foregroundStyle(AppTheme.Colors.textPrimary)
        )
        .font(.system(size: 16))
        .lineSpacing(5)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Background

    private var rowBackground: some View {
        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
            .fill(
                isActive
                    ? accentColor.opacity(0.07)
                    : AppTheme.Colors.backgroundSecondary.opacity(0.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .strokeBorder(
                        isActive ? accentColor.opacity(0.20) : Color.clear,
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Previews

@available(iOS 26, *)
#Preview("Mid-playback — word highlighted") {
    let segments = PodcastViewModel.mockSegments
    let active   = segments[2]
    let text     = active.plainText
    let wordStart = text.index(text.startIndex, offsetBy: 22)
    let wordEnd   = text.index(wordStart, offsetBy: 8)

    return ZStack {
        AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
        TranscriptView(
            segments: segments,
            currentSegmentIndex: 2,
            currentWordRange: wordStart..<wordEnd
        )
    }
}

@available(iOS 26, *)
#Preview("Idle — no active segment") {
    ZStack {
        AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
        TranscriptView(
            segments: PodcastViewModel.mockSegments,
            currentSegmentIndex: 0,
            currentWordRange: nil
        )
    }
}
