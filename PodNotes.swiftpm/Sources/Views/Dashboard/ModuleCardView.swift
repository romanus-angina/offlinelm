import SwiftUI

@available(iOS 26, *)
struct ModuleCardView: View {
    let module: StudyModule
    let namespace: Namespace.ID
    let onPlay: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            cardHeader
            Spacer(minLength: AppTheme.Spacing.md)
            cardFooter
        }
        .padding(AppTheme.Spacing.md)
        .frame(minHeight: 160)
        .cardSurface()
        .matchedGeometryEffect(id: "card-bg-\(module.id)", in: namespace)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(AppTheme.Motion.snappy, value: isPressed)
        ._onButtonGesture(pressing: { pressing in isPressed = pressing }, perform: {})
    }

    private var cardHeader: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                waveformDecoration
                Spacer()
                StatusPillView(status: module.status)
            }
            Text(module.title)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.Colors.textPrimary)
                .matchedGeometryEffect(id: "card-title-\(module.id)", in: namespace)
                .lineLimit(2)
        }
    }

    private var cardFooter: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(module.formattedDate)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(AppTheme.Colors.textTertiary)
                if module.isPlayable {
                    Text("\(module.estimatedDurationMinutes) min listen")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(AppTheme.Colors.textTertiary)
                }
            }
            Spacer()
            if module.isPlayable { playButton }
        }
    }

    private var playButton: some View {
        Button(action: onPlay) {
            ZStack {
                Circle()
                    .fill(AppTheme.Gradients.primary)
                    .frame(width: 44, height: 44)
                Image(systemName: "play.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.white)
                    .offset(x: 1)
            }
        }
        .buttonStyle(.plain)
        .shadow(color: AppTheme.Colors.glowAna1, radius: 8, x: 0, y: 4)
    }

    private var waveformDecoration: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach([0.4, 0.7, 1.0, 0.6, 0.85] as [Double], id: \.self) { h in
                Capsule()
                    .fill(AppTheme.Colors.ana4.opacity(0.45))
                    .frame(width: 3, height: 18 * h)
            }
        }
        .frame(height: 18)
    }
}
