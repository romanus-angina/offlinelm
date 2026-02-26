import SwiftUI
import UniformTypeIdentifiers

@available(iOS 26, *)
struct GenerationDebugView: View {

    @State private var log = ""
    @State private var isShowingPicker = false
    @State private var isRunning = false

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(log.isEmpty ? "Import a PDF to run the full pipeline." : log)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(AppTheme.Colors.textPrimary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(AppTheme.Colors.backgroundPrimary)
            .navigationTitle("Generation Debug")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Load PDF") { isShowingPicker = true }
                        .disabled(isRunning)
                }
            }
        }
        .fileImporter(
            isPresented: $isShowingPicker,
            allowedContentTypes: [.pdf]
        ) { result in
            guard case .success(let url) = result else {
                appendLog("File picker cancelled or failed.")
                return
            }
            let secured = url.startAccessingSecurityScopedResource()
            defer { if secured { url.stopAccessingSecurityScopedResource() } }

            guard let data = try? Data(contentsOf: url) else {
                appendLog("Failed to read file data.")
                return
            }

            Task { await runPipeline(data: data) }
        }
    }

    // MARK: - Pipeline

    private func runPipeline(data: Data) async {
        isRunning = true
        log = ""
        let startTime = ContinuousClock.now

        appendLog("=== PDF Ingestion ===")
        let ingestion = PDFIngestionService(ocrRenderScale: 2.0)
        let extraction: PDFIngestionService.ExtractionResult
        do {
            extraction = try ingestion.extract(from: data)
        } catch {
            appendLog("Ingestion failed: \(error.localizedDescription)")
            isRunning = false
            return
        }
        appendLog("Title: \(extraction.suggestedTitle)")
        appendLog("Pages: \(extraction.pageTexts.count)")

        appendLog("\n=== Chunking ===")
        let chunker = TextChunker()
        let chunks = chunker.chunk(pageTexts: extraction.pageTexts)
        appendLog("Chunks: \(chunks.count)")
        for chunk in chunks {
            let words = chunk.text.split { $0.isWhitespace }.count
            let tokens = TextChunker.estimatedTokenCount(for: chunk.text)
            appendLog("  [\(chunk.order)] \(words)w ~\(tokens)t")
        }

        appendLog("\n=== Generation ===")
        let service = GenerationService()
        var result: GenerationResult?

        do {
            result = try await service.generate(
                from: chunks,
                moduleTitle: extraction.suggestedTitle
            ) { progress in
                Task { @MainActor in
                    switch progress {
                    case .started(let total):
                        appendLog("Started: \(total) chunks to process")
                    case .chunkCompleted(let done, let total):
                        appendLog("Chunk \(done)/\(total) complete")
                    case .finished(let segs, let slides):
                        appendLog("Finished: \(segs) segments, \(slides) slides")
                    case .failed(let err):
                        appendLog("Progress error: \(err.localizedDescription)")
                    }
                }
            }
            appendLog("GenerationService succeeded.")
        } catch {
            appendLog("GenerationService failed: \(error.localizedDescription)")
            appendLog("Falling back to FallbackGenerator...")
            let fallback = FallbackGenerator().generate(from: chunks)
            result = GenerationResult(segments: fallback.segments, slides: fallback.slides)
            appendLog("Fallback produced \(fallback.segments.count) segments, \(fallback.slides.count) slides.")
        }

        guard let output = result else {
            appendLog("No output produced.")
            isRunning = false
            return
        }

        let elapsed = ContinuousClock.now - startTime

        appendLog("\n=== Dialogue (\(output.segments.count) segments) ===")
        for segment in output.segments.prefix(30) {
            let speaker = segment.speaker.displayName
            let preview = String(segment.plainText.prefix(80))
            appendLog("[\(segment.order)] \(speaker): \(preview)")
        }
        if output.segments.count > 30 {
            appendLog("  ... \(output.segments.count - 30) more segments")
        }

        appendLog("\n=== Slides (\(output.slides.count) slides) ===")
        for slide in output.slides {
            appendLog("[\(slide.order)] \(slide.title)")
            for point in slide.keyPoints {
                appendLog("  - \(point)")
            }
            appendLog("  Q: \(slide.quizQuestion)")
            appendLog("  A: \(slide.quizAnswer)")
        }

        appendLog("\n=== Done in \(elapsed) ===")
        isRunning = false
    }

    // MARK: - Logging

    private func appendLog(_ line: String) {
        log += line + "\n"
    }
}
