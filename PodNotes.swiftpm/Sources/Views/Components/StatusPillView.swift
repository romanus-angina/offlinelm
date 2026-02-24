import SwiftUI

@available(iOS 26, *)
struct StatusPillView: View {
    let status: ProcessingStatus

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            if status.isInProgress {
                Image(systemName: status.icon)
                    .font(.system(size: 10, weight: .semibold))
                    .symbolEffect(.pulse, isActive: true)
            } else {
                Image(systemName: status.icon)
                    .font(.system(size: 10, weight: .semibold))
            }
            Text(status.label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(status.tintColor)
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(status.tintColor.opacity(0.12))
                .overlay(
                    Capsule().strokeBorder(status.tintColor.opacity(0.25), lineWidth: 1)
                )
        )
    }
}
