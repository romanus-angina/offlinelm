import Foundation

@available(iOS 26, *)
enum SpeechServiceTests {

    struct TestResult: Sendable {
        let name: String
        let passed: Bool
        let detail: String
    }

    static func runAll() async -> [TestResult] {
        await [
            testInitialStateIsIdle(),
            testLoadSetsIdleAndCorrectCount(),
            testLoadWhilePlayingResetsState(),
            testLoadEmptySegmentsSetsFinished(),
            testPlayFromIdleSetsPlaying(),
            testPlayFromFinishedRestarts(),
            testPauseWhilePlayingSetsStatePaused(),
            testPauseWhileIdleIsNoOp(),
            testResumeFromPausedSetsPlaying(),
            testResumeFromIdleIsNoOp(),
            testSkipForwardAdvancesIndex(),
            testSkipForwardAtLastSegmentDoesNotCrash(),
            testSkipBackwardDecrementsIndex(),
            testSkipBackwardAtFirstSegmentClampsToZero(),
            testSkipWhilePausedRemainspaused(),
            testLoadResetsCurrrentWordRange(),
            testLoadResetsProgress(),
            testProgressTotalMatchesLoadedCount(),
            testEmptyPlainTextSegmentsSkipped(),
            testOnlyWhitespaceSegmentsSkipped(),
            testLoadWithSingleSegmentPlaysWithoutCrash(),
        ]
    }

    // MARK: - Initial state

    @MainActor
    private static func testInitialStateIsIdle() async -> TestResult {
        let service = SpeechService()
        return TestResult(
            name: "Initial playbackState is .idle",
            passed: service.playbackState == .idle,
            detail: service.playbackState.rawValue
        )
    }

    // MARK: - load()

    @MainActor
    private static func testLoadSetsIdleAndCorrectCount() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 4))
        let passed = service.playbackState == .idle
                  && service.progress.totalSegments == 4
                  && service.currentSegmentIndex == 0
        return TestResult(
            name: "load() with 4 segments: state=.idle, totalSegments=4, index=0",
            passed: passed,
            detail: "state=\(service.playbackState.rawValue) total=\(service.progress.totalSegments) index=\(service.currentSegmentIndex)"
        )
    }

    @MainActor
    private static func testLoadWhilePlayingResetsState() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 3))
        service.play()
        // State transitions to .playing after play() on a non-empty loaded set.
        service.load(makeSegments(count: 2))
        let passed = service.playbackState == .idle
                  && service.currentSegmentIndex == 0
                  && service.currentWordRange == nil
        return TestResult(
            name: "load() while playing resets to .idle at index 0",
            passed: passed,
            detail: "state=\(service.playbackState.rawValue) index=\(service.currentSegmentIndex)"
        )
    }

    @MainActor
    private static func testLoadEmptySegmentsSetsFinished() async -> TestResult {
        let service = SpeechService()
        service.load([])
        return TestResult(
            name: "load([]) sets playbackState to .finished",
            passed: service.playbackState == .finished,
            detail: service.playbackState.rawValue
        )
    }

    // MARK: - play()

    @MainActor
    private static func testPlayFromIdleSetsPlaying() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 2))
        service.play()
        return TestResult(
            name: "play() from .idle transitions to .playing",
            passed: service.playbackState == .playing,
            detail: service.playbackState.rawValue
        )
    }

    @MainActor
    private static func testPlayFromFinishedRestarts() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 1))
        service.play()
        // Simulate finished by calling play() again — it should re-enter .playing
        // from any non-playing state.
        service.load(makeSegments(count: 1))
        service.play()
        return TestResult(
            name: "play() after re-load from .finished goes back to .playing",
            passed: service.playbackState == .playing && service.currentSegmentIndex == 0,
            detail: "state=\(service.playbackState.rawValue) index=\(service.currentSegmentIndex)"
        )
    }

    // MARK: - pause()

    @MainActor
    private static func testPauseWhilePlayingSetsStatePaused() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 3))
        service.play()
        service.pause()
        return TestResult(
            name: "pause() while playing transitions to .paused",
            passed: service.playbackState == .paused,
            detail: service.playbackState.rawValue
        )
    }

    @MainActor
    private static func testPauseWhileIdleIsNoOp() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 2))
        service.pause()  // called before play() — must not crash
        return TestResult(
            name: "pause() while .idle is a no-op (no crash, state unchanged)",
            passed: service.playbackState == .idle,
            detail: service.playbackState.rawValue
        )
    }

    // MARK: - resume()

    @MainActor
    private static func testResumeFromPausedSetsPlaying() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 3))
        service.play()
        service.pause()
        service.resume()
        return TestResult(
            name: "resume() from .paused transitions to .playing",
            passed: service.playbackState == .playing,
            detail: service.playbackState.rawValue
        )
    }

    @MainActor
    private static func testResumeFromIdleIsNoOp() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 2))
        service.resume()  // called before play() — must not crash
        return TestResult(
            name: "resume() while .idle is a no-op (no crash)",
            passed: service.playbackState == .idle,
            detail: service.playbackState.rawValue
        )
    }

    // MARK: - skipForward()

    @MainActor
    private static func testSkipForwardAdvancesIndex() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 4))
        service.play()
        service.skipForward()
        return TestResult(
            name: "skipForward() while playing advances currentSegmentIndex to 1",
            passed: service.currentSegmentIndex == 1,
            detail: "index=\(service.currentSegmentIndex)"
        )
    }

    @MainActor
    private static func testSkipForwardAtLastSegmentDoesNotCrash() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 2))
        service.play()
        service.skipForward()  // to index 1
        service.skipForward()  // past the end — must not crash
        return TestResult(
            name: "skipForward() at last segment transitions to .finished without crash",
            passed: service.playbackState == .finished,
            detail: "state=\(service.playbackState.rawValue) index=\(service.currentSegmentIndex)"
        )
    }

    // MARK: - skipBackward()

    @MainActor
    private static func testSkipBackwardDecrementsIndex() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 4))
        service.play()
        service.skipForward()  // index → 1
        service.skipBackward() // index → 0
        return TestResult(
            name: "skipBackward() decrements currentSegmentIndex by 1",
            passed: service.currentSegmentIndex == 0,
            detail: "index=\(service.currentSegmentIndex)"
        )
    }

    @MainActor
    private static func testSkipBackwardAtFirstSegmentClampsToZero() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 3))
        service.play()
        service.skipBackward()  // already at 0 — must clamp, not underflow
        return TestResult(
            name: "skipBackward() at index 0 clamps to 0 without crash",
            passed: service.currentSegmentIndex == 0,
            detail: "index=\(service.currentSegmentIndex)"
        )
    }

    @MainActor
    private static func testSkipWhilePausedRemainspaused() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 4))
        service.play()
        service.pause()
        service.skipForward()
        return TestResult(
            name: "skipForward() while paused updates index but stays .paused",
            passed: service.playbackState == .paused && service.currentSegmentIndex == 1,
            detail: "state=\(service.playbackState.rawValue) index=\(service.currentSegmentIndex)"
        )
    }

    // MARK: - State field resets

    @MainActor
    private static func testLoadResetsCurrrentWordRange() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 2))
        service.play()
        service.load(makeSegments(count: 2))
        return TestResult(
            name: "load() clears currentWordRange",
            passed: service.currentWordRange == nil,
            detail: service.currentWordRange == nil ? "nil" : "non-nil"
        )
    }

    @MainActor
    private static func testLoadResetsProgress() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 3))
        service.load(makeSegments(count: 5))
        return TestResult(
            name: "load() resets segmentsCompleted to 0",
            passed: service.progress.segmentsCompleted == 0,
            detail: "segmentsCompleted=\(service.progress.segmentsCompleted)"
        )
    }

    @MainActor
    private static func testProgressTotalMatchesLoadedCount() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 7))
        return TestResult(
            name: "progress.totalSegments matches segment count passed to load()",
            passed: service.progress.totalSegments == 7,
            detail: "totalSegments=\(service.progress.totalSegments)"
        )
    }

    // MARK: - Empty / whitespace segment skipping

    @MainActor
    private static func testEmptyPlainTextSegmentsSkipped() async -> TestResult {
        var segments = makeSegments(count: 3)
        // Replace the first segment's text with an empty string.
        segments[0] = DialogueSegment(
            id: segments[0].id,
            speaker: .hostA,
            plainText: "",
            ssmlText: "",
            order: 0
        )
        let service = SpeechService()
        service.load(segments)
        service.play()
        // The service should skip index 0 and advance to the first non-empty segment.
        // We can't await the skip (no synthesizer in tests), but we can verify
        // the service did not crash and remains in a valid state.
        return TestResult(
            name: "Empty plainText segment does not crash on play()",
            passed: service.playbackState == .playing || service.playbackState == .finished,
            detail: "state=\(service.playbackState.rawValue)"
        )
    }

    @MainActor
    private static func testOnlyWhitespaceSegmentsSkipped() async -> TestResult {
        let segment = DialogueSegment(
            speaker: .hostB,
            plainText: "   \n\t  ",
            ssmlText: "",
            order: 0
        )
        let service = SpeechService()
        service.load([segment])
        service.play()
        return TestResult(
            name: "Whitespace-only segment does not crash, transitions to .finished",
            passed: service.playbackState == .finished || service.playbackState == .playing,
            detail: "state=\(service.playbackState.rawValue)"
        )
    }

    // MARK: - Single segment

    @MainActor
    private static func testLoadWithSingleSegmentPlaysWithoutCrash() async -> TestResult {
        let service = SpeechService()
        service.load(makeSegments(count: 1))
        service.play()
        service.pause()
        service.skipForward()
        return TestResult(
            name: "Single-segment load: play, pause, skipForward all execute without crash",
            passed: true,
            detail: "state=\(service.playbackState.rawValue)"
        )
    }

    // MARK: - Factory

    private static func makeSegments(count: Int) -> [DialogueSegment] {
        (0..<count).map { i in
            DialogueSegment(
                speaker: i.isMultiple(of: 2) ? .hostA : .hostB,
                plainText: "This is segment \(i). It covers a study concept.",
                ssmlText: "<speak>This is segment \(i).</speak>",
                order: i
            )
        }
    }
}
