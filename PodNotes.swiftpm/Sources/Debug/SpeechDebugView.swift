import SwiftUI
import AVFoundation

@available(iOS 26, *)
struct SpeechDebugView: View {

    @State private var service = SpeechService()

    // MARK: - Hardcoded segments

    private static let segments: [DialogueSegment] = [
        DialogueSegment(
            speaker: .hostA,
            plainText: "The cell is the fundamental unit of life. Every living organism is composed of one or more cells, and all cells arise from pre-existing cells.",
            ssmlText: "",
            order: 0
        ),
        DialogueSegment(
            speaker: .hostB,
            plainText: "So when we say DNA carries genetic information, what exactly does that mean? Is it just a blueprint, or does it actively do something?",
            ssmlText: "",
            order: 1
        ),
        DialogueSegment(
            speaker: .hostA,
            plainText: "DNA is more like a master instruction set. It does not build proteins directly — instead, the cell transcribes DNA into RNA, and then translates that RNA into proteins. ATP powers almost every step of this process.",
            ssmlText: "",
            order: 2
        ),
        DialogueSegment(
            speaker: .hostB,
            plainText: "That is a useful distinction. So the central dogma of molecular biology is: DNA to RNA to protein, in that order?",
            ssmlText: "",
            order: 3
        ),
        DialogueSegment(
            speaker: .hostA,
            plainText: "Exactly. The mitochondria produce ATP through cellular respiration, which is why they are described as the powerhouse of the cell. Without ATP, transcription and translation would halt entirely.",
            ssmlText: "",
            order: 4
        ),
        DialogueSegment(
            speaker: .hostB,
            plainText: "And what happens when the cell cycle goes wrong? Does that lead directly to problems like cancer?",
            ssmlText: "",
            order: 5
        ),
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
                VStack(spacing: 0) {
                    statusBar
                    transcriptScroll
                    Divider()
                        .background(AppTheme.Colors.borderMedium)
                    transportControls
                }
            }
            .navigationTitle("Speech Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            service.load(Self.segments)
        }
    }

    // MARK: - Status bar

    private var statusBar: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            stateIndicator
            Spacer()
            Text(progressLabel)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.textSecondary)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.Colors.backgroundSecondary)
    }

    private var stateIndicator: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Circle()
                .fill(stateColor)
                .frame(width: 8, height: 8)
                .overlay(
                    Circle()
                        .fill(stateColor)
                        .frame(width: 8, height: 8)
                        .scaleEffect(service.playbackState == .playing ? 1.4 : 1.0)
                        .opacity(service.playbackState == .playing ? 0.0 : 1.0)
                        .animation(
                            service.playbackState == .playing
                                ? .easeOut(duration: 0.8).repeatForever(autoreverses: false)
                                : .default,
                            value: service.playbackState
                        )
                )
            Text(service.playbackState.rawValue.uppercased())
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(stateColor)
        }
    }

    private var stateColor: Color {
        switch service.playbackState {
        case .idle:     return AppTheme.Colors.textTertiary
        case .playing:  return AppTheme.Colors.ana5
        case .paused:   return AppTheme.Colors.ana4
        case .finished: return AppTheme.Colors.statusReady
        }
    }

    private var progressLabel: String {
        let total = service.progress.totalSegments
        guard total > 0 else { return "No segments" }
        let current = service.currentSegmentIndex + 1
        return "Segment \(current) of \(total)"
    }

    // MARK: - Transcript scroll

    private var transcriptScroll: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: AppTheme.Spacing.md) {
                    ForEach(Self.segments) { segment in
                        segmentRow(segment, proxy: proxy)
                            .id(segment.id)
                    }
                }
                .padding(AppTheme.Spacing.md)
            }
            .scrollIndicators(.hidden)
            .onChange(of: service.currentSegmentIndex) { _, newIndex in
                guard let seg = Self.segments[safe: newIndex] else { return }
                withAnimation(AppTheme.Motion.gentle) {
                    proxy.scrollTo(seg.id, anchor: .center)
                }
            }
        }
    }

    // MARK: - Segment row

    private func segmentRow(_ segment: DialogueSegment, proxy: ScrollViewProxy) -> some View {
        let isActive = Self.segments[safe: service.currentSegmentIndex]?.id == segment.id

        return HStack(alignment: .top, spacing: AppTheme.Spacing.sm) {
            speakerTag(segment.speaker, isActive: isActive)
            transcriptText(segment, isActive: isActive)
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                .fill(isActive
                      ? segment.speaker.accentColor.opacity(0.08)
                      : AppTheme.Colors.backgroundSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .strokeBorder(
                            isActive ? segment.speaker.accentColor.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .animation(AppTheme.Motion.standard, value: isActive)
    }

    private func speakerTag(_ speaker: Speaker, isActive: Bool) -> some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: speaker.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isActive ? speaker.accentColor : AppTheme.Colors.textTertiary)
            Text(speaker.displayName)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(isActive ? speaker.accentColor : AppTheme.Colors.textTertiary)
        }
        .frame(width: 40)
        .animation(AppTheme.Motion.snappy, value: isActive)
    }

    // Renders plainText with the active word highlighted using currentWordRange.
    @ViewBuilder
    private func transcriptText(_ segment: DialogueSegment, isActive: Bool) -> some View {
        let text = segment.plainText
        let isCurrentSegment = Self.segments[safe: service.currentSegmentIndex]?.id == segment.id
        let wordRange = isCurrentSegment ? service.currentWordRange : nil

        if let range = wordRange, isCurrentSegment {
            // Build a Text from three pieces: before, highlighted word, after.
            let before  = String(text[text.startIndex..<range.lowerBound])
            let word    = String(text[range])
            let after   = String(text[range.upperBound..<text.endIndex])

            let highlightColor = segment.speaker == .hostA
                                 ? AppTheme.Colors.ana1
                                 : AppTheme.Colors.ana5

            (
                Text(before).foregroundStyle(AppTheme.Colors.textPrimary)
                + Text(word)
                    .foregroundStyle(highlightColor)
                    .fontWeight(.bold)
                    .underline(color: highlightColor.opacity(0.6))
                + Text(after).foregroundStyle(AppTheme.Colors.textPrimary)
            )
            .font(.system(size: 15))
            .lineSpacing(5)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(
                    isActive ? AppTheme.Colors.textPrimary : AppTheme.Colors.textSecondary
                )
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Transport controls

    private var transportControls: some View {
        HStack(spacing: AppTheme.Spacing.xl) {
            skipButton(icon: "backward.fill") {
                service.skipBackward()
            }
            playPauseButton
            skipButton(icon: "forward.fill") {
                service.skipForward()
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(AppTheme.Colors.backgroundSecondary)
    }

    private func skipButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .frame(width: 52, height: 52)
        }
        .buttonStyle(.plain)
    }

    private var playPauseButton: some View {
        let isPlaying = service.playbackState == .playing

        return Button {
            switch service.playbackState {
            case .playing:           service.pause()
            case .paused:            service.resume()
            case .idle, .finished:   service.play()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(AppTheme.Gradients.primary)
                    .frame(width: 68, height: 68)
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.white)
                    .offset(x: isPlaying ? 0 : 2)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .buttonStyle(.plain)
        .shadow(color: AppTheme.Colors.glowAna1, radius: 14, x: 0, y: 6)
        .animation(AppTheme.Motion.snappy, value: isPlaying)
    }
}

// MARK: - Collection helper

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
