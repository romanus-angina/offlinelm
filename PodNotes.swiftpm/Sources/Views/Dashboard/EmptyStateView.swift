import SwiftUI

@available(iOS 26, *)
struct EmptyStateView: View {
    let onImport: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()
            iconStack
            VStack(spacing: AppTheme.Spacing.sm) {
                Text("No notes yet")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                Text("Import a PDF and PodNotes will turn it\ninto a podcast and study deck.")
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Button(action: onImport) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Import PDF")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundStyle(Color.white)
                .frame(height: 52)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .background(AppTheme.Gradients.primary)
                .clipShape(Capsule())
                .shadow(color: AppTheme.Colors.glowAna1, radius: 14, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(AppTheme.Spacing.xl)
    }

    private var iconStack: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Colors.backgroundTertiary)
                .frame(width: 120, height: 120)
            Circle()
                .strokeBorder(AppTheme.Colors.borderMedium, lineWidth: 1)
                .frame(width: 120, height: 120)
            Image(systemName: "waveform.and.mic")
                .font(.system(size: 44, weight: .thin))
                .foregroundStyle(AppTheme.Gradients.spectrum)
        }
    }
}
