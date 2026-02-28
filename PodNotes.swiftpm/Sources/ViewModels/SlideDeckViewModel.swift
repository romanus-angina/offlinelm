import Foundation
import Observation

// MARK: - SlideDeckViewModel

@available(iOS 26, *)
@Observable
final class SlideDeckViewModel {

    // MARK: - Public state

    /// The slides to display, sorted by their order field.
    let slides: [Slide]

    /// Zero-based index of the currently visible card.
    /// Bound directly to the TabView page index.
    var currentIndex: Int = 0

    /// Tracks which slide IDs have had their quiz answer revealed.
    /// Using a Set means reveal state is O(1) to read and write.
    private(set) var revealedAnswers: Set<UUID> = []

    // MARK: - Computed

    var currentSlide: Slide? {
        slides[safe: currentIndex]
    }

    /// Human-readable position label, e.g. "3 / 7".
    var positionLabel: String {
        guard !slides.isEmpty else { return "0 / 0" }
        return "\(currentIndex + 1) / \(slides.count)"
    }

    var isOnFirstSlide: Bool { currentIndex == 0 }
    var isOnLastSlide:  Bool { currentIndex == slides.count - 1 }

    // MARK: - Init

    /// Production path: pass in a StudyModule's slides array.
    init(slides: [Slide]) {
        self.slides = slides.sorted()
    }

    // MARK: - Navigation

    func goToNext() {
        guard !isOnLastSlide else { return }
        currentIndex += 1
    }

    func goToPrevious() {
        guard !isOnFirstSlide else { return }
        currentIndex -= 1
    }

    func goTo(index: Int) {
        guard slides.indices.contains(index) else { return }
        currentIndex = index
    }

    // MARK: - Quiz reveal

    func revealAnswer(for slide: Slide) {
        revealedAnswers.insert(slide.id)
    }

    func isAnswerRevealed(for slide: Slide) -> Bool {
        revealedAnswers.contains(slide.id)
    }

    // When the user navigates away and returns, the answer stays revealed.
    // Call this if you want a "reset quiz" feature later.
    func hideAllAnswers() {
        revealedAnswers.removeAll()
    }
}

// MARK: - Mock data (for previews and debug builds)

@available(iOS 26, *)
extension SlideDeckViewModel {

    static let mockSlides: [Slide] = [
        Slide(
            title: "Cell Structure and Function",
            keyPoints: [
                "Every living organism is composed of one or more cells.",
                "The cell membrane regulates what enters and exits the cell.",
                "Organelles carry out specialised functions within the cell.",
                "Prokaryotic cells lack a membrane-bound nucleus."
            ],
            quizQuestion: "What is the primary role of the cell membrane?",
            quizAnswer: "The cell membrane acts as a selective barrier, controlling the movement of substances into and out of the cell.",
            order: 0
        ),
        Slide(
            title: "DNA and Genetic Information",
            keyPoints: [
                "DNA stores genetic instructions in a double-helix structure.",
                "Genes are segments of DNA that encode specific proteins.",
                "DNA replication occurs before a cell divides.",
                "Mutations are permanent changes to the DNA sequence."
            ],
            quizQuestion: "What is the relationship between DNA, genes, and proteins?",
            quizAnswer: "Genes are sequences within DNA that are transcribed into RNA and then translated into proteins, which carry out most cellular functions.",
            order: 1
        ),
        Slide(
            title: "ATP and Cellular Respiration",
            keyPoints: [
                "ATP is the primary energy currency of the cell.",
                "Glucose is oxidised through glycolysis, the Krebs cycle, and the electron transport chain.",
                "Mitochondria are the primary site of ATP production in eukaryotes.",
                "Up to 30-32 ATP molecules are produced per glucose in aerobic respiration."
            ],
            quizQuestion: "Why are mitochondria described as the powerhouse of the cell?",
            quizAnswer: "Mitochondria produce the majority of a cell's ATP through aerobic cellular respiration, converting chemical energy from glucose into a usable form.",
            order: 2
        ),
        Slide(
            title: "Protein Synthesis Overview",
            keyPoints: [
                "Transcription converts DNA into messenger RNA in the nucleus.",
                "Translation converts mRNA into an amino acid chain at the ribosome.",
                "The sequence of codons in mRNA determines the protein's amino acid order.",
                "Post-translational modifications can alter a protein's final structure."
            ],
            quizQuestion: "What are the two main stages of protein synthesis and where do they occur?",
            quizAnswer: "Transcription occurs in the nucleus, converting DNA to mRNA. Translation occurs at ribosomes, converting mRNA into a polypeptide chain.",
            order: 3
        ),
        Slide(
            title: "Cell Division and the Cell Cycle",
            keyPoints: [
                "The cell cycle consists of interphase and the mitotic phase.",
                "Interphase includes DNA replication during the S phase.",
                "Mitosis produces two genetically identical daughter cells.",
                "Checkpoints regulate progression through the cell cycle to prevent errors."
            ],
            quizQuestion: "What is the purpose of cell cycle checkpoints?",
            quizAnswer: "Checkpoints verify that conditions are suitable to proceed to the next phase, preventing the propagation of damaged or incompletely replicated DNA.",
            order: 4
        ),
    ]

    static var mock: SlideDeckViewModel {
        SlideDeckViewModel(slides: mockSlides)
    }
}

// MARK: - Safe subscript helper

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
