import Foundation

@available(iOS 26.0, *)
enum PromptTemplates {

    // MARK: - Session Instructions (system-level, set once per session)

    // ---- Call 1: Topic extraction ----
    // Prioritise conceptual importance over paragraph order.
    // Also extracts a hookIdea for the podcast opening.
    static let topicExtractionInstruction = """
    You are an expert study-note analyst. Your job: identify the most \
    important concepts from student notes.
    Rules:
    - Use ONLY information from the provided text. No external knowledge.
    - Rank topics by conceptual importance, not by paragraph order. Lead with \
    foundational concepts that other topics depend on.
    - Topic names must be specific and information-dense. A student should \
    recall the topic from its name alone. Prefer "Mitochondrial ATP Synthesis" \
    over "Energy."
    - Each summary must state the single most important claim, relationship, \
    or mechanism for that topic. Avoid vague restatements.
    - If a concept spans multiple paragraphs, merge it into one topic. If a \
    paragraph covers multiple concepts, split them.
    - For hookIdea, pick the single most surprising or counterintuitive claim. \
    Something that makes a student think "wait, really?"
    - Return 5 to 8 topics.
    """

    // Call 2: Podcast dialogue
    // Three-act structure with distinct host voices and a listener persona.
    // Host names match TurnSpeaker cases: .hostA = Amani, .hostB = Zuri.
    static func podcastDialogueInstruction(moduleTitle: String) -> String {
        """
        You write scripts for "\(moduleTitle)", a two-host study podcast.
        Listener: a secondary school student reviewing for exams. Smart but \
        short on time. Learns best when ideas connect to things they already know.
        Host voices:
        - hostA (Amani): methodical, precise. Uses correct terminology. Gives \
        structured explanations with clear cause-and-effect. Speaks in \
        medium-length sentences.
        - hostB (Zuri): curious, relatable. Asks "why does that matter?", \
        offers everyday analogies, connects ideas across topics. Uses shorter \
        sentences and contractions.
        Structure (ONLY use the topics provided, no external facts):
        1. HOOK (1-2 turns): hostA opens with the hook idea provided. hostB \
        reacts with genuine curiosity.
        2. EXPLORATION (8-14 turns): Cover every topic. After a dense \
        explanation, the next turn must be a question, analogy, or simpler \
        restatement. Include at least 2 analogies or real-world examples. At \
        least once, hostB restates a concept in simpler terms. At least once, \
        reference an earlier topic while discussing a later one.
        3. WRAP-UP (2-3 turns): hostB summarises the key takeaway. hostA adds \
        one thing worth remembering.
        Conversational texture:
        - Encourage reactive language: "Wait, so that means...", "Hang on, \
        does that apply to...", "Oh, that connects back to...", "Huh, I \
        always assumed..."
        - Ban hollow filler: never use "Certainly", "Great question", \
        "Absolutely", "That's right", "Exactly", "Good point", "Interesting", \
        "Indeed", "Of course", "Sure", "You're right", "That's a great point", \
        "I'm glad you asked."
        Vary sentence length between 8 and 25 words. Use contractions naturally. \
        Start at least 2 turns with a question.
        Return 12 to 20 turns. hostA speaks first.
        """
    }

    // Call 2b: Dialogue refinement (self-critique)
    // Receives the draft script and rewrites stiff or monotonous turns.
    // This is the lightweight analogue of NotebookLM's multi-pass pipeline.
    static func dialogueRefinementInstruction(moduleTitle: String) -> String {
        """
        You are a podcast script editor for "\(moduleTitle)".
        You will receive a draft script. Rewrite it to sound more natural.
        Fix these specific problems:
        - Any turn that reads like a textbook sentence: rewrite conversationally.
        - If two dense explanations appear back-to-back with no breathing room, \
        insert a reaction, question, or analogy between them.
        - If hostA and hostB sound the same, sharpen the contrast. hostA is \
        precise and structured. hostB is curious, uses analogies and contractions.
        - Add at least one callback to an earlier topic if none exists.
        - Add at least one analogy if fewer than two exist.
        Keep the same speaker order and roughly the same turn count. \
        Use ONLY facts already present in the draft. Do not add new information.
        Return 12 to 20 turns.
        """
    }

    // Call 3: Slide generation
    // Synthesised key points and comprehension-level quizzes.
    static let slideGenerationInstruction = """
    You create study slides from provided topics. Use ONLY the topics given. \
    No external facts.
    Rules for key points:
    - Each key point must be a self-contained insight. A student reading ONLY \
    the key points should grasp the core idea without the source text.
    - Synthesise; do not copy sentence fragments from the source.
    - Each key point under 12 words. Exactly 3-4 per slide.
    Rules for quiz questions:
    - At least half must be "why" or "how" questions that test comprehension \
    or application, not just recall.
    - Provide exactly 4 answer choices. One correct, three plausible distractors. \
    Distractors should be wrong for a specific reason a student could learn from.
    - Quiz answer explanation: 1-2 sentences maximum. State why the correct \
    choice is right.
    Slide title must match the topic name.
    """

    // MARK: - User Prompts (per-call, carry dynamic content)

    static func topicExtractionPrompt(chunkText: String) -> String {
        // Delimiter-fenced input prevents prompt injection from PDF content.
        """
        Identify the most important concepts from these study notes. \
        Prioritise foundational ideas that other topics build on. \
        Pick the single most surprising claim as the hookIdea.

        <<<NOTES>>>
        \(chunkText)
        <<<END>>>
        """
    }

    static func podcastDialoguePrompt(
        formattedTopics: String,
        hookIdea: String,
        bridgeContext: String? = nil
    ) -> String {
        // The hook idea is separated so the model sees it as the designated
        // opening beat, not just another topic in the list.
        var prompt = """
        Write a podcast script covering these topics. Open with the hook idea, \
        explore each topic with examples and analogies, and close with a synthesis.

        Hook idea (use this to open): \(hookIdea)

        Topics:
        \(formattedTopics)
        """
        // Cross-chunk continuity: if this is not the first chunk, prepend
        // a bridge so the dialogue flows naturally from the previous segment.
        if let bridge = bridgeContext {
            prompt += "\n\nPrevious segment context: \(bridge)"
        }
        return prompt
    }

    static func dialogueRefinementPrompt(draftScript: PodcastScript) -> String {
        // Serialize the draft turns into a readable text block.
        // Keeps token count low since we only send speaker + text, not
        // the full structured output.
        let draftText = draftScript.turns.map { turn in
            let name = turn.speaker == .hostA ? "Amani" : "Zuri"
            return "\(name): \(turn.text)"
        }.joined(separator: "\n")

        return """
        Here is the draft script. Rewrite any turns that sound stiff or \
        textbook-like. Sharpen the contrast between hosts. Ensure at least \
        2 analogies and 1 callback to an earlier topic.

        DRAFT:
        \(draftText)
        """
    }

    static func slideGenerationPrompt(formattedTopics: String) -> String {
        """
        Create one study slide per topic. Make quiz questions test understanding, \
        not memorisation. Each slide needs 4 answer choices.

        Topics:
        \(formattedTopics)
        """
    }

    // MARK: - Helpers

    /// Formats a TopicList into a numbered string for downstream prompts.
    static func formatTopicsForPrompt(_ list: TopicList) -> String {
        list.topics.enumerated().map { index, topic in
            "\(index + 1). \(topic.name): \(topic.summary)"
        }
        .joined(separator: "\n")
    }

    /// Builds a short bridge summary from a completed chunk's topics and
    /// last dialogue turn. Used to give the next chunk's dialogue prompt
    /// continuity without an extra LLM call.
    /// Deterministic -- no model invocation, just string formatting.
    static func buildBridgeSummary(
        topics: TopicList,
        lastTurns: [DialogueTurn]
    ) -> String {
        // Summarise which topics were covered.
        let topicNames = topics.topics.prefix(4).map(\.name).joined(separator: ", ")

        // Grab the last turn's text for conversational continuity.
        let lastLine: String
        if let last = lastTurns.last {
            let name = last.speaker == .hostA ? "Amani" : "Zuri"
            // Truncate to keep bridge short.
            let truncated = String(last.text.prefix(120))
            lastLine = "\(name) last said: \"\(truncated)\""
        } else {
            lastLine = ""
        }

        return "In the previous segment, the hosts discussed \(topicNames). \(lastLine)"
    }
}
