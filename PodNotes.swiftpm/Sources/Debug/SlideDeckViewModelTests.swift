//import Foundation
//
//@available(iOS 26, *)
//enum SlideDeckViewModelTests {
//
//    struct TestResult: Sendable {
//        let name: String
//        let passed: Bool
//        let detail: String
//    }
//
//    static func runAll() -> [TestResult] {
//        [
//            // Init
//            testInitialIndexIsZero(),
//            testInitSortsSlidesByOrder(),
//            testInitWithEmptySlides(),
//
//            // positionLabel
//            testPositionLabelAtFirstSlide(),
//            testPositionLabelAtLastSlide(),
//            testPositionLabelWithEmptySlides(),
//
//            // isOnFirstSlide / isOnLastSlide
//            testIsOnFirstSlideAtIndexZero(),
//            testIsOnFirstSlideNotAtIndexZero(),
//            testIsOnLastSlideAtFinalIndex(),
//            testIsOnLastSlideNotAtFinalIndex(),
//
//            // goToNext
//            testGoToNextAdvancesIndex(),
//            testGoToNextClampsAtLastSlide(),
//
//            // goToPrevious
//            testGoToPreviousDecrementsIndex(),
//            testGoToPreviousClampsAtFirstSlide(),
//
//            // goTo(index:)
//            testGoToValidIndexNavigates(),
//            testGoToOutOfBoundsDoesNotChange(),
//            testGoToNegativeIndexDoesNotChange(),
//
//            // currentSlide
//            testCurrentSlideMatchesCurrentIndex(),
//            testCurrentSlideIsNilWhenEmpty(),
//
//            // Quiz reveal
//            testAnswerNotRevealedByDefault(),
//            testRevealAnswerMarksSlideRevealed(),
//            testRevealAnswerDoesNotAffectOtherSlides(),
//            testRevealPersistsAcrossNavigation(),
//            testHideAllAnswersClearsAllRevealed(),
//            testHideAllAnswersOnFreshInstanceIsNoOp(),
//
//            // Mock data shape
//            testMockSlideCount(),
//            testMockSlidesAllHaveKeyPoints(),
//            testMockSlidesAllHaveQuizContent(),
//            testMockSlidesOrderIsContiguous(),
//        ]
//    }
//
//    // MARK: - Init
//
//    private static func testInitialIndexIsZero() -> TestResult {
//        let vm = makeFiveSlideVM()
//        return TestResult(
//            name: "Initial currentIndex is 0",
//            passed: vm.currentIndex == 0,
//            detail: "currentIndex=\(vm.currentIndex)"
//        )
//    }
//
//    private static func testInitSortsSlidesByOrder() -> TestResult {
//        // Pass slides in reverse order — VM must sort them.
//        let slides = [
//            makeSlide(order: 4),
//            makeSlide(order: 1),
//            makeSlide(order: 0),
//            makeSlide(order: 3),
//            makeSlide(order: 2),
//        ]
//        let vm = SlideDeckViewModel(slides: slides)
//        let orders = vm.slides.map(\.order)
//        return TestResult(
//            name: "init sorts slides by order regardless of input order",
//            passed: orders == [0, 1, 2, 3, 4],
//            detail: "orders=\(orders)"
//        )
//    }
//
//    private static func testInitWithEmptySlides() -> TestResult {
//        let vm = SlideDeckViewModel(slides: [])
//        return TestResult(
//            name: "init with empty array: slides.count == 0, currentIndex == 0",
//            passed: vm.slides.isEmpty && vm.currentIndex == 0,
//            detail: "count=\(vm.slides.count) index=\(vm.currentIndex)"
//        )
//    }
//
//    // MARK: - positionLabel
//
//    private static func testPositionLabelAtFirstSlide() -> TestResult {
//        let vm = makeFiveSlideVM()
//        return TestResult(
//            name: "positionLabel at index 0 of 5 is '1 / 5'",
//            passed: vm.positionLabel == "1 / 5",
//            detail: "label='\(vm.positionLabel)'"
//        )
//    }
//
//    private static func testPositionLabelAtLastSlide() -> TestResult {
//        let vm = makeFiveSlideVM()
//        vm.goTo(index: 4)
//        return TestResult(
//            name: "positionLabel at index 4 of 5 is '5 / 5'",
//            passed: vm.positionLabel == "5 / 5",
//            detail: "label='\(vm.positionLabel)'"
//        )
//    }
//
//    private static func testPositionLabelWithEmptySlides() -> TestResult {
//        let vm = SlideDeckViewModel(slides: [])
//        return TestResult(
//            name: "positionLabel with empty slides is '0 / 0'",
//            passed: vm.positionLabel == "0 / 0",
//            detail: "label='\(vm.positionLabel)'"
//        )
//    }
//
//    // MARK: - isOnFirstSlide / isOnLastSlide
//
//    private static func testIsOnFirstSlideAtIndexZero() -> TestResult {
//        let vm = makeFiveSlideVM()
//        return TestResult(
//            name: "isOnFirstSlide is true at index 0",
//            passed: vm.isOnFirstSlide == true,
//            detail: "isOnFirstSlide=\(vm.isOnFirstSlide)"
//        )
//    }
//
//    private static func testIsOnFirstSlideNotAtIndexZero() -> TestResult {
//        let vm = makeFiveSlideVM()
//        vm.goToNext()
//        return TestResult(
//            name: "isOnFirstSlide is false after goToNext()",
//            passed: vm.isOnFirstSlide == false,
//            detail: "index=\(vm.currentIndex) isOnFirstSlide=\(vm.isOnFirstSlide)"
//        )
//    }
//
//    private static func testIsOnLastSlideAtFinalIndex() -> TestResult {
//        let vm = makeFiveSlideVM()
//        vm.goTo(index: 4)
//        return TestResult(
//            name: "isOnLastSlide is true at index 4 of 5",
//            passed: vm.isOnLastSlide == true,
//            detail: "index=\(vm.currentIndex) isOnLastSlide=\(vm.isOnLastSlide)"
//        )
//    }
//
//    private static func testIsOnLastSlideNotAtFinalIndex() -> TestResult {
//        let vm = makeFiveSlideVM()
//        return TestResult(
//            name: "isOnLastSlide is false at index 0",
//            passed: vm.isOnLastSlide == false,
//            detail: "isOnLastSlide=\(vm.isOnLastSlide)"
//        )
//    }
//
//    // MARK: - goToNext
//
//    private static func testGoToNextAdvancesIndex() -> TestResult {
//        let vm = makeFiveSlideVM()
//        vm.goToNext()
//        return TestResult(
//            name: "goToNext() advances currentIndex from 0 to 1",
//            passed: vm.currentIndex == 1,
//            detail: "currentIndex=\(vm.currentIndex)"
//        )
//    }
//
//    private static func testGoToNextClampsAtLastSlide() -> TestResult {
//        let vm = makeFiveSlideVM()
//        // Advance to the last slide then call goToNext() one extra time.
//        for _ in 0..<5 { vm.goToNext() }
//        return TestResult(
//            name: "goToNext() at last slide clamps to last index without crash",
//            passed: vm.currentIndex == 4,
//            detail: "currentIndex=\(vm.currentIndex)"
//        )
//    }
//
//    // MARK: - goToPrevious
//
//    private static func testGoToPreviousDecrementsIndex() -> TestResult {
//        let vm = makeFiveSlideVM()
//        vm.goTo(index: 3)
//        vm.goToPrevious()
//        return TestResult(
//            name: "goToPrevious() decrements currentIndex from 3 to 2",
//            passed: vm.currentIndex == 2,
//            detail: "currentIndex=\(vm.currentIndex)"
//        )
//    }
//
//    private static func testGoToPreviousClampsAtFirstSlide() -> TestResult {
//        let vm = makeFiveSlideVM()
//        // Already at 0 — calling goToPrevious must not underflow.
//        vm.goToPrevious()
//        return TestResult(
//            name: "goToPrevious() at index 0 clamps to 0 without crash",
//            passed: vm.currentIndex == 0,
//            detail: "currentIndex=\(vm.currentIndex)"
//        )
//    }
//
//    // MARK: - goTo(index:)
//
//    private static func testGoToValidIndexNavigates() -> TestResult {
//        let vm = makeFiveSlideVM()
//        vm.goTo(index: 3)
//        return TestResult(
//            name: "goTo(index: 3) sets currentIndex to 3",
//            passed: vm.currentIndex == 3,
//            detail: "currentIndex=\(vm.currentIndex)"
//        )
//    }
//
//    private static func testGoToOutOfBoundsDoesNotChange() -> TestResult {
//        let vm = makeFiveSlideVM()
//        vm.goTo(index: 99)
//        return TestResult(
//            name: "goTo(index: 99) leaves currentIndex unchanged at 0",
//            passed: vm.currentIndex == 0,
//            detail: "currentIndex=\(vm.currentIndex)"
//        )
//    }
//
//    private static func testGoToNegativeIndexDoesNotChange() -> TestResult {
//        let vm = makeFiveSlideVM()
//        vm.goTo(index: -1)
//        return TestResult(
//            name: "goTo(index: -1) leaves currentIndex unchanged at 0",
//            passed: vm.currentIndex == 0,
//            detail: "currentIndex=\(vm.currentIndex)"
//        )
//    }
//
//    // MARK: - currentSlide
//
//    private static func testCurrentSlideMatchesCurrentIndex() -> TestResult {
//        let vm = makeFiveSlideVM()
//        vm.goTo(index: 2)
//        let match = vm.currentSlide?.id == vm.slides[2].id
//        return TestResult(
//            name: "currentSlide returns the slide at currentIndex",
//            passed: match,
//            detail: "currentSlide.order=\(vm.currentSlide?.order ?? -1)"
//        )
//    }
//
//    private static func testCurrentSlideIsNilWhenEmpty() -> TestResult {
//        let vm = SlideDeckViewModel(slides: [])
//        return TestResult(
//            name: "currentSlide is nil when slides is empty",
//            passed: vm.currentSlide == nil,
//            detail: vm.currentSlide == nil ? "nil" : "non-nil"
//        )
//    }
//
//    // MARK: - Quiz reveal
//
//    private static func testAnswerNotRevealedByDefault() -> TestResult {
//        let vm = makeFiveSlideVM()
//        let allHidden = vm.slides.allSatisfy { !vm.isAnswerRevealed(for: $0) }
//        return TestResult(
//            name: "No answers revealed on fresh init",
//            passed: allHidden,
//            detail: "revealedCount=\(vm.revealedAnswers.count)"
//        )
//    }
//
//    private static func testRevealAnswerMarksSlideRevealed() -> TestResult {
//        let vm = makeFiveSlideVM()
//        let target = vm.slides[1]
//        vm.revealAnswer(for: target)
//        return TestResult(
//            name: "revealAnswer marks that slide as revealed",
//            passed: vm.isAnswerRevealed(for: target),
//            detail: "revealed=\(vm.isAnswerRevealed(for: target))"
//        )
//    }
//
//    private static func testRevealAnswerDoesNotAffectOtherSlides() -> TestResult {
//        let vm = makeFiveSlideVM()
//        vm.revealAnswer(for: vm.slides[1])
//        let othersHidden = vm.slides
//            .filter { $0.id != vm.slides[1].id }
//            .allSatisfy { !vm.isAnswerRevealed(for: $0) }
//        return TestResult(
//            name: "Revealing slide 1 does not reveal any other slide",
//            passed: othersHidden,
//            detail: "revealedCount=\(vm.revealedAnswers.count), expected 1"
//        )
//    }
//
//    private static func testRevealPersistsAcrossNavigation() -> TestResult {
//        let vm = makeFiveSlideVM()
//        let target = vm.slides[2]
//        vm.revealAnswer(for: target)
//        // Navigate away and back.
//        vm.goToNext()
//        vm.goToPrevious()
//        vm.goToPrevious()
//        vm.goTo(index: 2)
//        return TestResult(
//            name: "Revealed answer persists after navigating away and back",
//            passed: vm.isAnswerRevealed(for: target),
//            detail: "stillRevealed=\(vm.isAnswerRevealed(for: target))"
//        )
//    }
//
//    private static func testHideAllAnswersClearsAllRevealed() -> TestResult {
//        let vm = makeFiveSlideVM()
//        vm.slides.forEach { vm.revealAnswer(for: $0) }
//        vm.hideAllAnswers()
//        let allHidden = vm.slides.allSatisfy { !vm.isAnswerRevealed(for: $0) }
//        return TestResult(
//            name: "hideAllAnswers() clears all revealed answers",
//            passed: allHidden && vm.revealedAnswers.isEmpty,
//            detail: "revealedCount=\(vm.revealedAnswers.count)"
//        )
//    }
//
//    private static func testHideAllAnswersOnFreshInstanceIsNoOp() -> TestResult {
//        let vm = makeFiveSlideVM()
//        vm.hideAllAnswers()
//        return TestResult(
//            name: "hideAllAnswers() on fresh instance is a no-op (no crash)",
//            passed: vm.revealedAnswers.isEmpty,
//            detail: "revealedCount=\(vm.revealedAnswers.count)"
//        )
//    }
//
//    // MARK: - Mock data shape
//
//    private static func testMockSlideCount() -> TestResult {
//        let count = SlideDeckViewModel.mockSlides.count
//        return TestResult(
//            name: "mockSlides contains 5 slides",
//            passed: count == 5,
//            detail: "count=\(count)"
//        )
//    }
//
//    private static func testMockSlidesAllHaveKeyPoints() -> TestResult {
//        let allHavePoints = SlideDeckViewModel.mockSlides
//            .allSatisfy { $0.keyPoints.count >= 3 }
//        return TestResult(
//            name: "Every mock slide has at least 3 key points",
//            passed: allHavePoints,
//            detail: "counts=\(SlideDeckViewModel.mockSlides.map { $0.keyPoints.count })"
//        )
//    }
//
//    private static func testMockSlidesAllHaveQuizContent() -> TestResult {
//        let allHaveQuiz = SlideDeckViewModel.mockSlides.allSatisfy {
//            !$0.quizQuestion.isEmpty && !$0.quizAnswer.isEmpty
//        }
//        return TestResult(
//            name: "Every mock slide has a non-empty quiz question and answer",
//            passed: allHaveQuiz,
//            detail: allHaveQuiz ? "all non-empty" : "some empty"
//        )
//    }
//
//    private static func testMockSlidesOrderIsContiguous() -> TestResult {
//        let orders = SlideDeckViewModel.mockSlides
//            .sorted { $0.order < $1.order }
//            .map(\.order)
//        let expected = Array(0..<SlideDeckViewModel.mockSlides.count)
//        return TestResult(
//            name: "mockSlides have contiguous zero-based order values",
//            passed: orders == expected,
//            detail: "orders=\(orders)"
//        )
//    }
//
//    // MARK: - Factories
//
//    private static func makeFiveSlideVM() -> SlideDeckViewModel {
//        SlideDeckViewModel(slides: SlideDeckViewModel.mockSlides)
//    }
//
//    private static func makeSlide(order: Int) -> Slide {
//        Slide(
//            title: "Slide \(order)",
//            keyPoints: ["Point A", "Point B", "Point C"],
//            quizQuestion: "Question for slide \(order)?",
//            quizAnswer: "Answer for slide \(order).",
//            order: order
//        )
//    }
//}
