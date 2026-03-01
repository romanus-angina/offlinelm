import SwiftUI
import SwiftData

@available(iOS 26, *)
struct MainTabView: View {

    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            Tab(AppTab.library.rawValue, systemImage: AppTab.library.icon, value: .library) {
                NavigationStack(path: $router.libraryPath) {
                    DashboardView()
                        .navigationDestination(for: AppDestination.self) { dest in
                            destinationView(for: dest)
                        }
                }
            }

            Tab(AppTab.settings.rawValue, systemImage: AppTab.settings.icon, value: .settings) {
                NavigationStack {
                    AppSettingsView()
                }
            }
        }
        .tint(AppTheme.Colors.ana4)
    }

    // MARK: - Shared destination resolver

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        switch destination {
        case .processing(let module):
            ProcessingView(module: module)
        case .hub(let module):
            ModuleHubView(module: module)
        case .podcast(let module):
            PodcastPlayerView(module: module)
        case .slides(let module):
            SlidesView(module: module)
        case .flashcard(let module):
            FlashcardView(module: module)
        }
    }
}
