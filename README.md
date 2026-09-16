# PodNotes

[![Swift Student Challenge 2026 Winner](https://img.shields.io/badge/Swift_Student_Challenge-2026_Winner-F05138?logo=swift&logoColor=white)](https://developer.apple.com/swift-student-challenge/)
[![Platform](https://img.shields.io/badge/platform-iOS_26-000000?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white)](https://www.swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green)](LICENSE)

An iOS app that turns a PDF into a two-host podcast, a slide deck, multiple-choice quizzes, and a chat you can ask about the material. Think NotebookLM, but offline. Every step runs on-device through Apple's Foundation Models framework, so there is no backend, no API keys, and no network calls.

## Swift Student Challenge

PodNotes was selected as one of the winners of Apple's [Swift Student Challenge](https://developer.apple.com/swift-student-challenge/) in 2026. The challenge asks students to submit an app built as a Swift Playgrounds app package, which is why this project ships as `PodNotes.swiftpm` (targeting iOS 26) rather than as a standard Xcode project, and why the whole flow is scoped to a short session.

Useful references:

- [Swift Student Challenge](https://developer.apple.com/swift-student-challenge/), including eligibility and submission requirements
- [Swift Playgrounds](https://www.apple.com/swift/playgrounds/), the environment app packages are built and run in
- [Foundation Models framework](https://developer.apple.com/documentation/foundationmodels), the on-device model API this app is built around

## Screens

### Library

<table>
<tr>
<td width="50%" align="center"><img src="media/library-dashboard.png" width="220" alt="Library with an imported module"></td>
<td width="50%" align="center"><img src="media/library-search.png" width="220" alt="Library with search field"></td>
</tr>
<tr>
<td valign="top">Every imported PDF becomes a module card showing its processing status, age, and estimated listen time. Opening a card leads to that module's hub.</td>
<td valign="top">The library is searchable by title once more than a few modules pile up. Import is a single button that opens the system file picker. Library and Settings are the only two tabs.</td>
</tr>
</table>

### Processing and module hub

<p align="center"><img src="media/processing-complete.png" width="220" alt="Processing complete summary"></p>

While the pipeline runs, a terminal-style log reports each stage as it completes. When it finishes it summarizes what was produced: dialogue segments, slides, and an estimated listen time. From there each module opens into its own hub, a four-way grid of Listen, Quizzes, Review, and Ask, with actions disabled when the matching content was not generated.

### Podcast

<table>
<tr>
<td width="50%" align="center"><img src="media/podcast-player.png" width="220" alt="Podcast player with transcript"></td>
<td width="50%" align="center"><img src="media/podcast-transcript.png" width="220" alt="Podcast transcript with speaker turns"></td>
</tr>
<tr>
<td valign="top">The player reads the script aloud through two distinct voices. The active turn is highlighted while earlier and upcoming turns stay visible, and the transport controls skip by segment.</td>
<td valign="top">Every turn is attributed to a host, so the transcript doubles as a readable summary when listening is not an option.</td>
</tr>
</table>

### Review and quizzes

<table>
<tr>
<td width="50%" align="center"><img src="media/study-slide.png" width="220" alt="Generated study slide"></td>
<td width="50%" align="center"><img src="media/quiz-flashcard.png" width="220" alt="Multiple-choice quiz card"></td>
</tr>
<tr>
<td valign="top">Review condenses the same source text into a swipeable deck, each slide a topic title with three or four key points.</td>
<td valign="top">Quizzes turn each slide into a multiple-choice card with four options and optional hints. Every question carries a written explanation of why the correct answer is right.</td>
</tr>
</table>

Answering reveals the correct option in place, with the explanation and a collapsible hints section attached to the same card.

### Ask

Every module also has a chat sheet. `ChatViewModel` builds its system instruction from that module's own content, so answers stay grounded in the source PDF rather than general knowledge. Responses are matched against slide titles to show which topics they came from, a follow-up question is suggested after each answer, and the conversation is persisted on the module so it survives app restarts. If the context window fills up, the session resets and retries the question instead of failing.

## What it does

1. Import a PDF from the Library tab. Scanned pages without a text layer are detected and run through Vision OCR.
2. Extracted text is chunked and passed through an on-device generation pipeline.
3. The module hub then offers four ways in: Listen to the podcast, Review the slides, take the Quizzes, or Ask questions about the material in chat.

If Apple Intelligence is unavailable or generation fails, a deterministic fallback generator builds the podcast and slides directly from the source paragraphs so the pipeline never dead-ends.

## Pipeline

1. `PDFIngestionService` extracts text with PDFKit, falling back to Vision OCR on pages that lack a real text layer.
2. `TextChunker` splits the text into roughly 1200-word chunks, tagged with their source page range.
3. `GenerationService` generates content per chunk, or `FallbackGenerator` takes over if the on-device model is unavailable.
4. `SSMLBuilder` marks up each dialogue turn for speech, and the results are saved to a single SwiftData `StudyModule`.
5. `SpeechService`, `SlideDeckView`, `FlashcardView`, and `ChatViewModel` all read from that module.

`GenerationService` runs one `LanguageModelSession` per call per chunk, using `@Generable` structs so the model returns typed output instead of free text:

| Call | Input | Output |
| --- | --- | --- |
| Topic extraction | Chunk text | 5-8 topics with one-sentence summaries, plus a hook idea used to open the episode |
| Podcast dialogue | Topics, hook, bridge from the previous chunk | 12-20 alternating turns between the two hosts |
| Dialogue refinement | Draft script | A self-critiqued rewrite, falling back to the draft if the pass fails |
| Slide generation | Topics | Title, 3-4 bullets, and a four-option quiz question with the correct index and an explanation |

Slides are generated concurrently with the dialogue draft and its refinement pass. Chunks run sequentially, each one handed a deterministic bridge summary of the previous chunk so the episode flows as one conversation rather than disconnected segments.

## Tech stack

- SwiftUI and SwiftData for UI and local persistence. Each module stores its source PDF, transcript, slides, and chat history in one record
- [FoundationModels](https://developer.apple.com/documentation/foundationmodels) for on-device structured generation and the module chat
- PDFKit and Vision for text extraction with OCR fallback
- AVFoundation (`AVSpeechSynthesizer`) for two-voice playback with SSML

## Requirements

- Xcode 16+ or Swift Playgrounds, targeting iOS 26
- Apple Intelligence enabled for the full AI pipeline, otherwise the fallback generator is used
- Open `PodNotes.swiftpm` directly and run

## Notes

- English only for now, both in prompting and voice selection
- Speech quality depends on which system voices are installed. The app detects this and points users to Settings when only default-quality voices are available. See [docs/voice-quality-guide.md](docs/voice-quality-guide.md)

## License

MIT. See [LICENSE](LICENSE).
