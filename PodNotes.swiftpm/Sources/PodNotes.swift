import SwiftUI
import SwiftData

@main
struct PodNotesApp: App {

    private let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([StudyModule.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("SwiftData container failed to initialise: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if #available(iOS 26, *) {
                ContentView()
                    .modelContainer(modelContainer)
                    .preferredColorScheme(.dark)
            } else {
                MinimumVersionView()
            }
        }
    }
}

// Shown on the rare chance the playground runs below iOS 26.
private struct MinimumVersionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.yellow)
            Text("PodNotes requires iOS 26 or later.")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
