import SwiftUI
import UniformTypeIdentifiers

@available(iOS 26, *)
struct IngestionDebugView: View {

    @State private var output = "No PDF loaded yet."
    @State private var isShowingPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(output)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(AppTheme.Colors.backgroundPrimary)
            .navigationTitle("Ingestion Debug")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Load PDF") { isShowingPicker = true }
                }
            }
        }
        .fileImporter(
            isPresented: $isShowingPicker,
            allowedContentTypes: [.pdf]
        ) { result in
            guard case .success(let url) = result else { return }
            let secured = url.startAccessingSecurityScopedResource()
            defer { if secured { url.stopAccessingSecurityScopedResource() } }

            guard let data = try? Data(contentsOf: url) else {
                output = "Failed to read file."
                return
            }

            Task.detached {
                let service = PDFIngestionService(ocrRenderScale: 2.0)
                do {
                    let extraction = try service.extract(from: data)
                    let chunker   = TextChunker()
                    let chunks    = chunker.chunk(pageTexts: extraction.pageTexts)

                    var report = ""
                    report += "Title:  \(extraction.suggestedTitle)\n"
                    report += "Pages:  \(extraction.pageTexts.count)\n"
                    report += "Chunks: \(chunks.count)\n\n"

                    for chunk in chunks {
                        let words  = chunk.text.split { $0.isWhitespace }.count
                        let tokens = TextChunker.estimatedTokenCount(for: chunk.text)
                        let pages  = chunk.pageRange.map { "pp.\($0)" } ?? "n/a"
                        report += "[\(chunk.order)] \(words)w ~\(tokens)t \(pages)\n"
                    }
                    
                    for (pageNumber, text) in extraction.pageTexts {
                        let words = text.split { $0.isWhitespace }.count
                        report += "Page \(pageNumber): \(words) words\n"
                    }
                    
                    report += "\n-- Chunk contents --\n"
                    for chunk in chunks {
                        report += "\n=== Chunk \(chunk.order) ===\n"
                        report += chunk.text
                        report += "\n"
                    }

                    await MainActor.run { output = report }
                } catch {
                    await MainActor.run { output = "Error: \(error.localizedDescription)" }
                }
            }
        }
    }
}
