import SwiftUI
import Observation

// MARK: - AppDestination

@available(iOS 26, *)
enum AppDestination: Hashable {
    case processing(StudyModule)
    case podcast(StudyModule)
    case slides(StudyModule)

    // Equality and hashing are based on the module's id only so SwiftUI
    // can differentiate destinations without comparing full model state.
    func hash(into hasher: inout Hasher) {
        switch self {
        case .processing(let m): hasher.combine("processing"); hasher.combine(m.id)
        case .podcast(let m):    hasher.combine("podcast");    hasher.combine(m.id)
        case .slides(let m):     hasher.combine("slides");     hasher.combine(m.id)
        }
    }

    static func == (lhs: AppDestination, rhs: AppDestination) -> Bool {
        switch (lhs, rhs) {
        case (.processing(let a), .processing(let b)): return a.id == b.id
        case (.podcast(let a),    .podcast(let b)):    return a.id == b.id
        case (.slides(let a),     .slides(let b)):     return a.id == b.id
        default: return false
        }
    }
}

// MARK: - AppRouter

@available(iOS 26, *)
@Observable
final class AppRouter {
    var destination: AppDestination?
    var columnVisibility: NavigationSplitViewVisibility = .all

    func navigate(to destination: AppDestination) {
        withAnimation(AppTheme.Motion.snappy) {
            self.destination   = destination
            columnVisibility   = .detailOnly
        }
    }

    func goToDashboard() {
        withAnimation(AppTheme.Motion.standard) {
            destination      = nil
            columnVisibility = .all
        }
    }

    // Convenience shortcuts used throughout the codebase.
    func showProcessing(for module: StudyModule) { navigate(to: .processing(module)) }
    func showPodcast(for module: StudyModule)    { navigate(to: .podcast(module)) }
    func showSlides(for module: StudyModule)     { navigate(to: .slides(module)) }
}
