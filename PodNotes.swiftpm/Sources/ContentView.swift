import SwiftUI
import SwiftData

@available(iOS 26, *)
struct ContentView: View {

    @State private var router = AppRouter()

    var body: some View {
            // Swap in PodcastPlayerView(viewModel: .mock) to test the player,
            // or restore NavigationSplitView + DashboardView for the full app flow.
        PodcastPlayerView(viewModel: .mock)
                .environment(router)
        }

    private var detailPlaceholder: some View {
        ZStack {
            AppTheme.Colors.backgroundPrimary.ignoresSafeArea()
            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "waveform.and.mic")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(AppTheme.Gradients.spectrum)
                Text("Select or import a module to begin.")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.Colors.textTertiary)
            }
        }
    }
}
