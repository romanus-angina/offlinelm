import SwiftUI
import Observation

// MARK: - Tab

@available(iOS 26, *)
enum AppTab: String, CaseIterable, Sendable {
    case library  = "Library"
    case podcasts = "Podcasts"
    case study    = "Study"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .library:  return "books.vertical"
        case .podcasts: return "headphones"
        case .study:    return "brain.head.profile"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - AppDestination

@available(iOS 26, *)
enum AppDestination: Hashable {
    case processing(StudyModule)
    case podcast(StudyModule)
    case slides(StudyModule)
    case flashcard(StudyModule)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .processing(let m): hasher.combine("processing"); hasher.combine(m.id)
        case .podcast(let m):    hasher.combine("podcast");    hasher.combine(m.id)
        case .slides(let m):     hasher.combine("slides");     hasher.combine(m.id)
        case .flashcard(let m):  hasher.combine("flashcard");  hasher.combine(m.id)
        }
    }

    static func == (lhs: AppDestination, rhs: AppDestination) -> Bool {
        switch (lhs, rhs) {
        case (.processing(let a), .processing(let b)): return a.id == b.id
        case (.podcast(let a),    .podcast(let b)):    return a.id == b.id
        case (.slides(let a),     .slides(let b)):     return a.id == b.id
        case (.flashcard(let a),  .flashcard(let b)):  return a.id == b.id
        default: return false
        }
    }
}

// MARK: - AppRouter

@available(iOS 26, *)
@Observable
final class AppRouter {

    // MARK: - Tab state

    var selectedTab: AppTab = .library

    // MARK: - Per-tab navigation paths

    // Each tab owns its own NavigationPath so pushing/popping
    // in one tab never disturbs another tab's stack.
    var libraryPath:  [AppDestination] = []
    var podcastsPath: [AppDestination] = []
    var studyPath:    [AppDestination] = []

    // MARK: - Navigate within current tab

    func push(_ destination: AppDestination) {
        withAnimation(AppTheme.Motion.snappy) {
            switch selectedTab {
            case .library:  libraryPath.append(destination)
            case .podcasts: podcastsPath.append(destination)
            case .study:    studyPath.append(destination)
            case .settings: break
            }
        }
    }

    func popToRoot() {
        withAnimation(AppTheme.Motion.standard) {
            switch selectedTab {
            case .library:  libraryPath.removeAll()
            case .podcasts: podcastsPath.removeAll()
            case .study:    studyPath.removeAll()
            case .settings: break
            }
        }
    }

    // MARK: - Cross-tab navigation

    func switchToTab(_ tab: AppTab) {
        withAnimation(AppTheme.Motion.standard) {
            selectedTab = tab
        }
    }

    // Jump to a specific module's podcast in the Podcasts tab.
    func playPodcast(for module: StudyModule) {
        selectedTab = .podcasts
        podcastsPath = [.podcast(module)]
    }

    // Jump to a specific module's flashcards in the Study tab.
    func studyModule(_ module: StudyModule) {
        selectedTab = .study
        studyPath = [.flashcard(module)]
    }

    // MARK: - Convenience shortcuts

    func showProcessing(for module: StudyModule) { push(.processing(module)) }
    func showPodcast(for module: StudyModule)    { push(.podcast(module)) }
    func showSlides(for module: StudyModule)     { push(.slides(module)) }
    func showFlashcard(for module: StudyModule)  { push(.flashcard(module)) }

    func goToDashboard() { popToRoot() }
}
