import SwiftUI
import Observation

// MARK: - AppDestination

@available(iOS 26, *)
enum AppDestination: Hashable {
    case processing(StudyModule)
    case podcast(StudyModule)
    case slides(StudyModule)

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

    // The single destination that NavigationStack pushes on top of
    // DashboardView. Setting this to a value pushes; nil pops back
    // to the dashboard. Bound via navigationDestination(item:).
    var destination: AppDestination?

    func navigate(to destination: AppDestination) {
        withAnimation(AppTheme.Motion.snappy) {
            self.destination = destination
        }
    }

    func goToDashboard() {
        withAnimation(AppTheme.Motion.standard) {
            destination = nil
        }
    }

    // Convenience shortcuts used throughout the codebase.
    func showProcessing(for module: StudyModule) { navigate(to: .processing(module)) }
    func showPodcast(for module: StudyModule)    { navigate(to: .podcast(module)) }
    func showSlides(for module: StudyModule)     { navigate(to: .slides(module)) }
}
