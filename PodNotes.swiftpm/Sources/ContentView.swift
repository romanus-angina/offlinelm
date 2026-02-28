import SwiftUI
import SwiftData

@available(iOS 26, *)
struct ContentView: View {

    @State private var router = AppRouter()

    #if DEBUG
    @State private var isShowingDebug = false
    @State private var debugTab = 0
    #endif

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            NavigationStack {
                DashboardView()
                    .environment(router)
                    .navigationDestination(item: Bindable(router).destination) { destination in
                        destinationView(for: destination)
                            .environment(router)
                    }
            }

            #if DEBUG
            Button {
                isShowingDebug = true
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
            #endif
        }
        #if DEBUG
        .sheet(isPresented: $isShowingDebug) {
            TabView(selection: $debugTab) {
                PromptTestRunnerView()
                    .tabItem { Label("Tests", systemImage: "checkmark.circle") }
                    .tag(0)
                SlideCardDebugView()
                    .tabItem { Label("SlideCard", systemImage: "rectangle.on.rectangle") }
                    .tag(1)
                SlideDeckView(viewModel: SlideDeckViewModel.mock)
                    .tabItem { Label("SlideDeck", systemImage: "menucard") }
                    .tag(2)
            }
            .environment(AppRouter())
            .preferredColorScheme(.dark)
        }
        #endif
    }

    // MARK: - Destination routing

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .processing(let module):
            ProcessingView(module: module)
        case .podcast(let module):
            PodcastPlayerView(module: module)
        case .slides(let module):
            SlidesView(module: module)
        }
    }
}
