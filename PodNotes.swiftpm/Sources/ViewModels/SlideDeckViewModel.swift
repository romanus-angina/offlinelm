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
            choices: [
                "It acts as a selective barrier controlling substance movement.",
                "It produces energy for the cell through respiration.",
                "It stores the genetic material needed for cell division.",
                "It synthesises proteins required by the organism."
            ],
            correctAnswerIndex: 0,
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
            quizQuestion: "What is the relationship between genes and proteins?",
            choices: [
                "Genes are translated directly into lipids that form cell membranes.",
                "Genes are segments of DNA transcribed into RNA and then translated into proteins.",
                "Genes provide the energy needed to assemble amino acids into proteins.",
                "Genes bind to ribosomes to catalyse protein folding."
            ],
            correctAnswerIndex: 1,
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
            choices: [
                "They store glucose for later use by the cell.",
                "They control gene expression during cellular stress.",
                "They produce the majority of the cell's ATP through aerobic respiration.",
                "They break down waste products and recycle damaged organelles."
            ],
            correctAnswerIndex: 2,
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
            quizQuestion: "Where does transcription occur in a eukaryotic cell?",
            choices: [
                "At the ribosome on the rough endoplasmic reticulum.",
                "In the cytoplasm near the cell membrane.",
                "Inside the mitochondrial matrix.",
                "In the nucleus where DNA is housed."
            ],
            correctAnswerIndex: 3,
            quizAnswer: "Transcription occurs in the nucleus, where the DNA template is read by RNA polymerase to produce messenger RNA.",
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
            choices: [
                "They accelerate cell division when nutrients are plentiful.",
                "They verify conditions are suitable before the cell advances to the next phase.",
                "They trigger apoptosis in every cell that completes mitosis.",
                "They transport chromosomes to opposite poles of the dividing cell."
            ],
            correctAnswerIndex: 1,
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
