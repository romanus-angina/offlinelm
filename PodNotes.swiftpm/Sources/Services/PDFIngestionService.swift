import Foundation
import PDFKit
import Vision
import UIKit

/// Extracts the text content of a PDF document using PDFKit.

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
        /// Title derived from document metadata, or the first meaningful
        /// line of body text, or "Untitled" as a final fallback.
        let suggestedTitle: String
        /// Full extracted text with pages joined by double newlines.
        let fullText: String
        /// Per-page text with 1-based page numbers, in reading order.
        /// Individual entries may be empty for blank or image-only pages.
        let pageTexts: [(pageNumber: Int, text: String)]
    }

    // MARK: - Configuration

    /// Pages whose PDFKit word count falls below this value trigger the
    /// Vision OCR fallback. Scanned or handwritten pages typically return
    /// zero words from PDFKit, so any small non-zero threshold works.
    let ocrThreshold: Int

    /// Scale multiplier applied when rasterising a page for OCR.
    /// A value of 2.0 doubles the pixel dimensions relative to the PDF's
    /// natural point size, improving recognition accuracy on small pages.
    let ocrRenderScale: CGFloat

    init(ocrThreshold: Int = 10, ocrRenderScale: CGFloat = 2.0) {
        self.ocrThreshold = ocrThreshold
        self.ocrRenderScale = ocrRenderScale
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

            let native = (page.string ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if wordCount(native) >= ocrThreshold {
                pageTexts.append((pageNumber, normalise(native)))
            } else {
                // PDFKit returned insufficient text — the page is likely
                // scanned or handwritten. Try Vision OCR before giving up.
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
            fullText: fullText,
            pageTexts: pageTexts
        )
    }

    // MARK: - Private helpers

    private func wordCount(_ text: String) -> Int {
        text.split { $0.isWhitespace }.count
    }

    /// Collapses runs of more than two consecutive blank lines and strips
    /// leading/trailing horizontal whitespace from each line. PDFKit
    /// sometimes emits excessive whitespace between columns or headers.
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

        return result.joined(separator: "\n")
    }

    private func metadataTitle(from document: PDFDocument) -> String? {
        guard let attrs = document.documentAttributes,
              let raw = attrs[PDFDocumentAttribute.titleAttribute] as? String
        else { return nil }

        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Returns the first line that contains at least three words. A bare
    /// URL, page number, or single-word header does not qualify.
    private func firstMeaningfulLine(in text: String) -> String? {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { $0.split { $0.isWhitespace }.count >= 3 }
    }

}
