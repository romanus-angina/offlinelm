import SwiftUI
import SwiftData

@available(iOS 26, *)
struct ContentView: View {

    @State private var router = AppRouter()

    #if DEBUG
    @State private var isShowingTests = false
    #endif

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            NavigationSplitView(columnVisibility: Bindable(router).columnVisibility) {
                DashboardView()
                    .environment(router)
            } detail: {
                detailView
                    .environment(router)
            }

            #if DEBUG
            debugButton
            #endif
        }
        #if DEBUG
        .sheet(isPresented: $isShowingTests) {
            PromptTestRunnerView()
                .preferredColorScheme(.dark)
        }
        #endif
    }

    // MARK: - Detail routing

    @ViewBuilder
    private var detailView: some View {
        switch router.destination {
        case .processing(let module):
            ProcessingView(module: module)
        case .podcast(let module):
            PodcastPlayerView(module: module)
        case .slides(let module):
            NavigationStack {
                SlidesView(module: module)
            }
        case nil:
            detailPlaceholder
        }
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

    // MARK: - Debug

    #if DEBUG
    private var debugButton: some View {
        Button {
            isShowingTests = true
        } label: {
            Text("Tests")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(AppTheme.Colors.backgroundPrimary)
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(AppTheme.Colors.ana4)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.leading, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.md)
    }
    #endif
}
