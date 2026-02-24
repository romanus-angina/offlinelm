import SwiftUI
import SwiftData

@available(iOS 26, *)
struct ContentView: View {

    @State private var router = AppRouter()

    var body: some View {
        NavigationSplitView(columnVisibility: $router.columnVisibility) {
            DashboardView()
                .environment(router)
                .navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 500)
        } detail: {
            Group {
                switch router.destination {
                case .none:
                    detailPlaceholder
                case .processing(let module):
                    ProcessingView(module: module)
                case .podcast(let module):
                    PodcastPlayerView(module: module)
                case .slides(let module):
                    SlidesView(module: module)
                }
            }
            .environment(router)
        }
        .navigationSplitViewStyle(.balanced)
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
