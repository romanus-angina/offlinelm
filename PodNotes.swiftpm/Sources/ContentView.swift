import SwiftUI
import SwiftData

@available(iOS 26, *)
struct ContentView: View {

    @State private var router = AppRouter()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    #if DEBUG
    @State private var isShowingDebug = false
    @State private var debugTab = 0
    #endif

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if hasCompletedOnboarding {
                MainTabView()
                    .environment(router)
            } else {
                OnboardingView(onComplete: {
                    withAnimation(AppTheme.Motion.standard) {
                        hasCompletedOnboarding = true
                    }
                })
            }

            #if DEBUG
            if hasCompletedOnboarding {
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
                .padding(.bottom, 72)
            }
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
}
