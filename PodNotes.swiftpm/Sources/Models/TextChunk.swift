import Foundation

/// A self-contained slice of extracted PDF text that fits within the
/// context window of an on-device language model.
///
/// `TextChunker` produces an ordered array of these. Each chunk is
/// intended to be processed independently through the generation
/// pipeline; the `order` field lets callers stitch results back together.
struct TextChunk: Identifiable, Sendable {

    let id: UUID

    /// The text content of this chunk. Paragraphs inside a chunk are
    /// separated by double newlines, matching the source document structure.
    let text: String

    /// Zero-based position within the full sequence of chunks.
    let order: Int

    /// The 1-based PDF page numbers this chunk's content was sourced from,
    /// when page tracking was available during chunking. `nil` when the
    /// chunker was called with plain text rather than page-tagged input.
    let pageRange: ClosedRange<Int>?
}
