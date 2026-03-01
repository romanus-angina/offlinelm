import SwiftUI
import Observation

// MARK: - Tab

@available(iOS 26, *)
enum AppTab: String, CaseIterable, Sendable {
    case library  = "Library"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .library:  return "books.vertical"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - AppDestination

@available(iOS 26, *)
enum AppDestination: Hashable {
    case processing(StudyModule)
    case hub(StudyModule)
    case podcast(StudyModule)
    case slides(StudyModule)
    case flashcard(StudyModule)

    func hash(into hasher: inout Hasher) {
        switch self {
        case .processing(let m): hasher.combine("processing"); hasher.combine(m.id)
        case .hub(let m):        hasher.combine("hub");        hasher.combine(m.id)
        case .podcast(let m):    hasher.combine("podcast");    hasher.combine(m.id)
        case .slides(let m):     hasher.combine("slides");     hasher.combine(m.id)
        case .flashcard(let m):  hasher.combine("flashcard");  hasher.combine(m.id)
        }
    }

    static func == (lhs: AppDestination, rhs: AppDestination) -> Bool {
        switch (lhs, rhs) {
        case (.processing(let a), .processing(let b)): return a.id == b.id
        case (.hub(let a),        .hub(let b)):        return a.id == b.id
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

    // MARK: - Navigation path (library only)

    var libraryPath: [AppDestination] = []

    // MARK: - Navigate

    func push(_ destination: AppDestination) {
        withAnimation(AppTheme.Motion.snappy) {
            libraryPath.append(destination)
        }
    }

    func popToRoot() {
        withAnimation(AppTheme.Motion.standard) {
            libraryPath.removeAll()
        }
    }

    func popBack() {
        withAnimation(AppTheme.Motion.standard) {
            if !libraryPath.isEmpty {
                libraryPath.removeLast()
            }
        }
    }

    // MARK: - Convenience shortcuts

    func showProcessing(for module: StudyModule) { push(.processing(module)) }
    func showHub(for module: StudyModule)        { push(.hub(module)) }
    func showPodcast(for module: StudyModule)    { push(.podcast(module)) }
    func showSlides(for module: StudyModule)     { push(.slides(module)) }
    func showFlashcard(for module: StudyModule)  { push(.flashcard(module)) }

    func goToDashboard() { popToRoot() }
}
