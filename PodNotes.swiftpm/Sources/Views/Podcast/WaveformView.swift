import SwiftUI

// MARK: - WaveformView

@available(iOS 26, *)
struct WaveformView: View {

    let isPlaying: Bool
    let speaker: Speaker

    // Each bar has a unique combination of frequency and phase offset so the
    // overall shape looks organic rather than perfectly synchronised.
    private static let barCount = 38

    private static let configs: [(frequency: Double, phase: Double, baseAmplitude: Double)] = {
        var result: [(Double, Double, Double)] = []
        // Use a fixed seed sequence so the shape is deterministic across redraws.
        let frequencies: [Double] = [1.1, 1.7, 2.3, 1.5, 2.8, 1.3, 2.1, 1.9,
                                     2.6, 1.2, 1.8, 2.4, 1.6, 2.9, 1.4, 2.2,
                                     1.0, 2.7, 1.85, 2.05, 1.35, 2.55, 1.65, 2.15,
                                     1.75, 2.35, 1.25, 2.75, 1.55, 2.45, 1.95, 2.65,
                                     1.15, 2.25, 1.45, 1.05, 2.85, 1.45]
        let phases:      [Double] = [0.0, 0.4, 0.8, 1.2, 1.6, 2.0, 2.4, 2.8,
                                     3.2, 3.6, 0.2, 0.6, 1.0, 1.4, 1.8, 2.2,
                                     2.6, 3.0, 3.4, 3.8, 0.1, 0.5, 0.9, 1.3,
                                     1.7, 2.1, 2.5, 2.9, 3.3, 3.7, 0.3, 0.7,
                                     1.1, 1.5, 1.9, 2.3, 2.7, 3.1]
        // Amplitude envelope: bars in the centre are taller, edges shorter.
        for i in 0..<barCount {
            let t = Double(i) / Double(barCount - 1)
            let envelope = sin(t * .pi)            // peaks at centre
            let base = 0.25 + envelope * 0.65      // range [0.25, 0.90]
            result.append((
                frequency:     frequencies[i % frequencies.count],
                phase:         phases[i % phases.count],
                baseAmplitude: base
            ))
        }
        return result
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isPlaying)) { timeline in
            let phase = isPlaying
                ? timeline.date.timeIntervalSinceReferenceDate
                : 0.0

            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<Self.barCount, id: \.self) { index in
                    WaveformBar(
                        isPlaying:     isPlaying,
                        phase:         phase,
                        config:        Self.configs[index],
                        accentColor:   PlayerPalette.accent(for: speaker),
                        glowColor:     PlayerPalette.glow(for: speaker)
                    )
                }
            }
        }
        .animation(AppTheme.Motion.gentle, value: isPlaying)
        .animation(AppTheme.Motion.standard, value: speaker)
    }
}

// MARK: - WaveformBar

@available(iOS 26, *)
private struct WaveformBar: View {

    let isPlaying:   Bool
    let phase:       Double
    let config:      (frequency: Double, phase: Double, baseAmplitude: Double)
    let accentColor: Color
    let glowColor:   Color

    private static let maxHeight: CGFloat = 56
    private static let minHeight: CGFloat = 3

    private var height: CGFloat {
        guard isPlaying else { return Self.minHeight }
        let sine = sin(phase * config.frequency + config.phase)
        // Map [-1, 1] → [0.15, 1.0], scaled by the per-bar envelope.
        let normalised = (sine + 1.0) / 2.0
        let scaled = 0.15 + normalised * 0.85
        return CGFloat(scaled * config.baseAmplitude) * Self.maxHeight
    }

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [accentColor, accentColor.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 3, height: max(Self.minHeight, height))
            .shadow(color: glowColor, radius: isPlaying ? 5 : 0, x: 0, y: 0)
    }
}

// MARK: - Preview

@available(iOS 26, *)
#Preview("Playing — Host A") {
    ZStack {
        AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
        WaveformView(isPlaying: true, speaker: .hostA)
            .frame(height: 72)
            .padding(.horizontal, 24)
    }
}

@available(iOS 26, *)
#Preview("Paused — Host B") {
    ZStack {
        AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
        WaveformView(isPlaying: false, speaker: .hostB)
            .frame(height: 72)
            .padding(.horizontal, 24)
    }
}
