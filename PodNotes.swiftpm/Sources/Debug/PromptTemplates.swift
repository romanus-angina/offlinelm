import Foundation

@available(iOS 26.0, *)
enum PromptTemplates {

    // MARK: - Session instructions

    static let topicExtractionInstruction = """
    You are a study-note analyst. Extract the core topics from the provided text.
    Rules:
    - Use ONLY information present in the text. Do not add external knowledge.
    - Each topic name must be 2-5 words.
    - Each summary must be exactly one sentence drawn from the text.
    - Return between 5 and 8 topics.
    """

    static func podcastDialogueInstruction(moduleTitle: String) -> String {
        """
        You are a script writer for a two-host educational podcast called "\(moduleTitle)".
        Hosts: Alex (explains concepts) and Sam (asks clarifying questions and adds examples).
        Rules:
        - Use ONLY the topics provided. Do not add external facts.
        - Alternate speakers. Alex speaks first.
        - Each turn is 1-3 conversational sentences.
        - No filler phrases: avoid "Certainly!", "Great question!", "Absolutely!", "That's right!".
        - Cover every provided topic at least once.
        - Return 12 to 20 turns total.
        """
    }

    static let slideGenerationInstruction = """
    You are a study-slide creator. Produce one slide per topic provided.
    Rules:
    - Use ONLY the topics provided. Do not add external facts.
    - Slide title must match the topic name.
    - Exactly 3-4 key points per slide, each under 12 words.
    - One quiz question per slide that tests understanding of that topic.
    - Quiz answer must be a single concise sentence.
    """

    // MARK: - User prompts

    static func topicExtractionPrompt(chunkText: String) -> String {
        """
        Extract the core topics from the following study notes.

        --- STUDY NOTES ---
        \(chunkText)
        --- END ---
        """
    }

    static func podcastDialoguePrompt(formattedTopics: String) -> String {
        """
        Write a podcast dialogue covering these topics:

        \(formattedTopics)
        """
    }

    static func slideGenerationPrompt(formattedTopics: String) -> String {
        """
        Create study slides for these topics:

        \(formattedTopics)
        """
    }

    // MARK: - Helpers

    static func formatTopicsForPrompt(_ list: TopicList) -> String {
        list.topics.enumerated().map { index, topic in
            "\(index + 1). \(topic.name): \(topic.summary)"
        }
        .joined(separator: "\n")
    }
}
