// ChatViewModel.swift

import Foundation
import Observation
import FoundationModels

@available(iOS 26, *)
@Observable
@MainActor
final class ChatViewModel {

    // MARK: - Public state

    private(set) var messages: [ChatMessage] = []
    private(set) var isGenerating = false
    private(set) var modelUnavailable = false
    private(set) var suggestedFollowUp: String?

    let starterQuestions: [String]

    // MARK: - Public actions

    func clearFollowUp() {
        suggestedFollowUp = nil
    }

    // MARK: - Private state

    private let module: StudyModule?
    private let systemInstruction: String
    private let slideTitles: [String]
    private var session: LanguageModelSession?

    // MARK: - Init (production)

    init(module: StudyModule) {
        self.module = module
        self.slideTitles = module.slides.sorted().map(\.title)
        self.systemInstruction = Self.buildContextInstruction(from: module)
        self.starterQuestions = Self.buildStarterQuestions(from: module.slides.sorted())

        // Load persisted chat history.
        let saved = module.chatMessages
        if !saved.isEmpty {
            self.messages = saved
        }

        // Check model availability eagerly so we can show the unavailable state.
        let model = SystemLanguageModel.default
        if model.availability != .available {
            self.modelUnavailable = true
        }
    }

    // MARK: - Init (preview / mock)

    private init(mockMessages: [ChatMessage], mockStarterQuestions: [String]) {
        self.module = nil
        self.slideTitles = ["Cell Structure and Function", "DNA and Genetic Information", "ATP and Cellular Respiration"]
        self.systemInstruction = ""
        self.starterQuestions = mockStarterQuestions
        self.messages = mockMessages
    }

    // MARK: - Send message

    func send(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Append user message.
        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        suggestedFollowUp = nil
        isGenerating = true

        // Create session lazily on first send.
        if session == nil {
            session = LanguageModelSession(instructions: systemInstruction)
        }

        do {
            let response = try await session!.respond(to: trimmed)
            let rawText = response.content

            // Extract follow-up question if present.
            let (cleanedText, followUp) = extractFollowUp(from: rawText)

            // Source grounding.
            let relatedTopics = findRelatedTopics(in: cleanedText)

            let assistantMessage = ChatMessage(
                role: .assistant,
                content: cleanedText,
                relatedTopics: relatedTopics
            )
            messages.append(assistantMessage)
            suggestedFollowUp = followUp
            isGenerating = false
            saveMessages()

        } catch let error as LanguageModelSession.GenerationError {
            await handleGenerationError(error, userText: trimmed)
        } catch {
            let errorMessage = ChatMessage(
                role: .assistant,
                content: "I had trouble answering that. Try rephrasing or ask a different question."
            )
            messages.append(errorMessage)
            isGenerating = false
            saveMessages()
        }
    }

    // MARK: - Error handling

    private func handleGenerationError(
        _ error: LanguageModelSession.GenerationError,
        userText: String
    ) async {
        switch error {
        case .exceededContextWindowSize:
            // Reset session and retry.
            session = LanguageModelSession(instructions: systemInstruction)

            let resetMessage = ChatMessage(
                role: .assistant,
                content: "This conversation got long, so I refreshed my memory. Your study material is still loaded -- keep asking!"
            )
            messages.append(resetMessage)
            saveMessages()

            // Retry the user's message on the fresh session.
            do {
                let response = try await session!.respond(to: userText)
                let rawText = response.content
                let (cleanedText, followUp) = extractFollowUp(from: rawText)
                let relatedTopics = findRelatedTopics(in: cleanedText)

                let assistantMessage = ChatMessage(
                    role: .assistant,
                    content: cleanedText,
                    relatedTopics: relatedTopics
                )
                messages.append(assistantMessage)
                suggestedFollowUp = followUp
                isGenerating = false
                saveMessages()
            } catch {
                let fallback = ChatMessage(
                    role: .assistant,
                    content: "I had trouble answering that. Try rephrasing or ask a different question."
                )
                messages.append(fallback)
                isGenerating = false
                saveMessages()
            }

        default:
            // Check if model became unavailable.
            let model = SystemLanguageModel.default
            if model.availability != .available {
                modelUnavailable = true
                isGenerating = false
                return
            }

            let errorMessage = ChatMessage(
                role: .assistant,
                content: "I had trouble answering that. Try rephrasing or ask a different question."
            )
            messages.append(errorMessage)
            isGenerating = false
            saveMessages()
        }
    }

    // MARK: - Follow-up extraction

    private func extractFollowUp(from text: String) -> (cleaned: String, followUp: String?) {
        let lines = text.components(separatedBy: "\n")
        guard let lastLine = lines.last else {
            return (text, nil)
        }

        let trimmedLast = lastLine.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmedLast.lowercased()

        if lowercased.hasPrefix("follow-up: ") || lowercased.hasPrefix("follow-up:") {
            let prefixLength = lowercased.hasPrefix("follow-up: ") ? 11 : 10
            let question = String(trimmedLast.dropFirst(prefixLength))
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let cleanedLines = lines.dropLast()
            let cleaned = cleanedLines
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return (cleaned.isEmpty ? text : cleaned, question.isEmpty ? nil : question)
        }

        return (text, nil)
    }

    // MARK: - Source grounding

    private func findRelatedTopics(in responseText: String) -> [String] {
        let lowercasedResponse = responseText.lowercased()
        var matched: [String] = []

        for title in slideTitles {
            let words = title.lowercased()
                .split(separator: " ")
                .map(String.init)
                .filter { $0.count >= 3 }

            let hasMatch = words.contains { word in
                lowercasedResponse.contains(word)
            }

            if hasMatch {
                matched.append(title)
            }

            if matched.count >= 2 { break }
        }

        return matched
    }

    // MARK: - Persistence

    private func saveMessages() {
        module?.chatMessages = messages
    }

    // MARK: - Context building

    private static func buildContextInstruction(from module: StudyModule) -> String {
        let sortedSlides = module.slides.sorted()

        var instruction = """
        You are a patient, encouraging study tutor helping a student review their notes \
        for "\(module.title)".

        Your personality:
        - Explain concepts clearly using everyday analogies when they help.
        - Connect ideas across topics when relevant ("This links back to X because...").
        - If a student seems confused, try a different angle rather than repeating yourself.
        - Be concise: 2-4 sentences unless the student asks for more detail.
        - Use ONLY the study material below. If the answer is not in the material, say \
        "That is not covered in your notes" and suggest what IS available.

        End every response with a single follow-up question on its own line, prefixed \
        with "Follow-up: ". The follow-up should naturally extend the topic or connect \
        to a related concept from the material.

        STUDY MATERIAL:
        """

        if !sortedSlides.isEmpty {
            for (index, slide) in sortedSlides.enumerated() {
                let keyPointsJoined = slide.keyPoints.joined(separator: "; ")
                instruction += "\n\(index + 1). \(slide.title)"
                instruction += "\nKey points: \(keyPointsJoined)"
                instruction += "\nExplanation: \(slide.quizAnswer)"
            }
        } else {
            // Fallback: truncated sourceText.
            let words = module.sourceText.split(separator: " ")
            let truncated = words.prefix(600).joined(separator: " ")
            instruction += "\n<<<NOTES>>>\n\(truncated)\n<<<END>>>"
        }

        return instruction
    }

    // MARK: - Starter questions

    private static func buildStarterQuestions(from slides: [Slide]) -> [String] {
        guard !slides.isEmpty else {
            return [
                "Summarize the main ideas",
                "What are the key concepts?",
                "What should I focus on for an exam?"
            ]
        }

        var questions: [String] = []

        questions.append("Explain \(slides[0].title)")

        if slides.count >= 2 {
            questions.append("Why is \(slides[1].title) important?")
            questions.append("How does \(slides[0].title) relate to \(slides[1].title)?")
        }

        return questions
    }

    // MARK: - Mock

    static var mock: ChatViewModel {
        let messages: [ChatMessage] = [
            ChatMessage(
                role: .user,
                content: "What is ATP and why does it matter?"
            ),
            ChatMessage(
                role: .assistant,
                content: "ATP (adenosine triphosphate) is the primary energy currency of the cell. Think of it like the coins in an arcade -- every machine (cellular process) needs them to run. Cells produce ATP mainly through cellular respiration in the mitochondria, breaking down glucose through glycolysis, the Krebs cycle, and the electron transport chain.",
                relatedTopics: ["ATP and Cellular Respiration"]
            ),
            ChatMessage(
                role: .user,
                content: "How many ATP molecules does one glucose produce?"
            ),
            ChatMessage(
                role: .assistant,
                content: "Under ideal aerobic conditions, one glucose molecule can yield up to 30-32 ATP molecules. The theoretical maximum used to be cited as 36-38, but more accurate measurements account for the energy cost of transporting molecules across mitochondrial membranes. Most of this ATP comes from the electron transport chain rather than from glycolysis or the Krebs cycle directly."
            ),
        ]

        return ChatViewModel(
            mockMessages: messages,
            mockStarterQuestions: [
                "Explain Cell Structure and Function",
                "Why is DNA and Genetic Information important?",
                "How does Cell Structure and Function relate to DNA and Genetic Information?"
            ]
        )
    }

    static var mockEmpty: ChatViewModel {
        ChatViewModel(
            mockMessages: [],
            mockStarterQuestions: [
                "Explain Cell Structure and Function",
                "Why is DNA and Genetic Information important?",
                "How does Cell Structure and Function relate to DNA and Genetic Information?"
            ]
        )
    }
}
