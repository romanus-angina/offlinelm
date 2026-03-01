import SwiftUI

@available(iOS 26, *)
struct ChatPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Chat Coming Soon",
                systemImage: "bubble.left.and.text.bubble.right",
                description: Text("Ask questions about your notes using on-device AI. This feature is under development.")
            )
            .background(AppTheme.Colors.backgroundPrimary)
            .navigationTitle("Ask")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.Colors.textTertiary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
