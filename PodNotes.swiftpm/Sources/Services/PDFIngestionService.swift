import Foundation
import PDFKit
import Vision
import UIKit

/// Extracts the text content of a PDF document using PDFKit, with an
/// automatic Vision OCR fallback for pages that lack a real text layer.
struct PDFIngestionService: Sendable {

    // MARK: - Errors

    enum ExtractionError: LocalizedError, Sendable {
        case invalidData
        case passwordProtected
        case noExtractableText

        var errorDescription: String? {
            switch self {
            case .invalidData:
                return "The data could not be read as a valid PDF."
            case .passwordProtected:
                return "Password-protected PDFs are not supported."
            case .noExtractableText:
                return "No readable text was found in the PDF."
            }
        }
    }

    // MARK: - Result type

    struct ExtractionResult: Sendable {
        /// Title from document metadata, the first meaningful line of body
        /// text, or "Untitled" as a final fallback.
        let suggestedTitle: String
        /// Full extracted text with pages separated by double newlines.
        let fullText: String
        /// Per-page text with 1-based page numbers, in reading order.
        let pageTexts: [(pageNumber: Int, text: String)]
    }

    // MARK: - Configuration

    /// Minimum character-to-area density (chars per point²) for a page to
    /// be treated as having a real text layer.
    ///
    /// A standard A4 page of body text sits around 0.02-0.08. Anything below
    /// 0.005 is almost certainly a scan, a diagram, or a near-blank page.
    let minimumTextDensity: Double

    /// Scale multiplier when rasterising a page for Vision OCR. 3.0 triples
    /// pixel dimensions, which meaningfully improves recognition accuracy on
    /// dense or small handwriting.
    let ocrRenderScale: CGFloat

    init(minimumTextDensity: Double = 0.005, ocrRenderScale: CGFloat = 3.0) {
        self.minimumTextDensity = minimumTextDensity
        self.ocrRenderScale     = ocrRenderScale
    }

    // MARK: - Public

    func extract(from data: Data) throws -> ExtractionResult {
        guard let document = PDFDocument(data: data) else {
            throw ExtractionError.invalidData
        }
        guard !document.isLocked else {
            throw ExtractionError.passwordProtected
        }

        var pageTexts: [(pageNumber: Int, text: String)] = []

        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            let pageNumber = index + 1
            let rawText    = page.string ?? ""

            switch classifyPage(page, rawText: rawText) {
            case .textLayer:
                let cleaned = normalise(rawText)
                if !cleaned.isEmpty {
                    pageTexts.append((pageNumber, cleaned))
                }
            case .likelyScanned:
                let ocr = recognizeText(on: page)
                if !ocr.isEmpty {
                    pageTexts.append((pageNumber, normalise(ocr)))
                }
            }
        }

        let fullText = pageTexts.map(\.text).joined(separator: "\n\n")

        guard !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ExtractionError.noExtractableText
        }

        let title = metadataTitle(from: document)
            ?? firstMeaningfulLine(in: fullText)
            ?? "Untitled"

        return ExtractionResult(
            suggestedTitle: title,
            fullText:       fullText,
            pageTexts:      pageTexts
        )
    }

    // MARK: - Page classification

    private enum PageClassification {
        case textLayer
        case likelyScanned
    }

    private func classifyPage(_ page: PDFPage, rawText: String) -> PageClassification {
        let charCount = rawText.count
        guard charCount > 0 else { return .likelyScanned }

        // Signal 1 — density check.
        let bounds  = page.bounds(for: .mediaBox)
        let area    = Double(bounds.width * bounds.height)
        let density = Double(charCount) / area

        guard density >= minimumTextDensity else { return .likelyScanned }

        // Signal 2 — GlyphLessFont detection.
        // Acrobat stores its invisible OCR layer using a font named
        // "GlyphLessFont". Characters exist in the text stream but carry no
        // visible glyphs, so the page looks like a scan but reports as text.
        if containsGlyphlessFont(page) { return .likelyScanned }

        return .textLayer
    }

    private func containsGlyphlessFont(_ page: PDFPage) -> Bool {
        guard let attrString = page.attributedString else { return false }
        var found = false
        attrString.enumerateAttribute(
            .font,
            in: NSRange(location: 0, length: attrString.length)
        ) { value, _, stop in
            if let font = value as? UIFont,
               font.fontName.localizedCaseInsensitiveContains("GlyphLess") {
                found = true
                stop.pointee = true
            }
        }
        return found
    }

    // MARK: - Text normalisation

    /// Strips leading/trailing horizontal whitespace from each line and
    /// collapses runs of more than two consecutive blank lines. PDFKit
    /// frequently emits excessive whitespace around multi-column layouts
    /// and section headers.
    private func normalise(_ text: String) -> String {
        let lines = text
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .init(charactersIn: " \t")) }

        var result: [String] = []
        var blankRun = 0

        for line in lines {
            if line.isEmpty {
                blankRun += 1
                if blankRun <= 2 { result.append(line) }
            } else {
                blankRun = 0
                result.append(line)
            }
        }

        return result
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Title extraction

    private func metadataTitle(from document: PDFDocument) -> String? {
        guard let attrs = document.documentAttributes,
              let raw   = attrs[PDFDocumentAttribute.titleAttribute] as? String
        else { return nil }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Returns the first line that contains at least three whitespace-separated
    /// tokens. Filters out bare page numbers, URLs, and single-word headings.
    private func firstMeaningfulLine(in text: String) -> String? {
        text.components(separatedBy: .newlines)
            .map   { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { $0.split { $0.isWhitespace }.count >= 3 }
    }

    // MARK: - Vision OCR

    /// Rasterises a PDF page and runs VNRecognizeTextRequest against it.
    ///
    /// VNImageRequestHandler.perform(_:) is synchronous — the completion
    /// handler fires before the call returns — so no async wrappers are needed.
    /// The caller is responsible for dispatching off the main queue.
    private func recognizeText(on page: PDFPage) -> String {
        let mediaBox   = page.bounds(for: .mediaBox)
        let renderSize = CGSize(
            width:  mediaBox.width  * ocrRenderScale,
            height: mediaBox.height * ocrRenderScale
        )

        let image = page.thumbnail(of: renderSize, for: .mediaBox)
        guard let cgImage = image.cgImage else { return "" }

        var lines: [String] = []

        let request = VNRecognizeTextRequest { req, _ in
            guard let observations = req.results as? [VNRecognizedTextObservation]
            else { return }
            lines = observations.compactMap { $0.topCandidates(1).first?.string }
        }
        request.recognitionLevel       = .accurate
        request.recognitionLanguages   = ["en-US"]
        request.usesLanguageCorrection = false

        try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])

        return lines.joined(separator: "\n")
    }
}
