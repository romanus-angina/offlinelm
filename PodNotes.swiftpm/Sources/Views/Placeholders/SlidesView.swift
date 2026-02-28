import SwiftUI

// MARK: - SlidesView

@available(iOS 26, *)
struct SlidesView: View {

    let module: StudyModule

    var body: some View {
        SlideDeckView(module: module)
    }
}
