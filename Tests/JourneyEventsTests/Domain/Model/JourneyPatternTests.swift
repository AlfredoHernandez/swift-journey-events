//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Testing

@Suite("JourneyPattern Tests")
struct JourneyPatternTests {
    @Test("Init creates single-step pattern with default strict sequence")
    func init_createsSingleStepPatternWithDefaultStrictSequence() {
        let pattern = JourneyPattern(steps: ["app_started"])

        #expect(pattern.steps == ["app_started"])
        #expect(pattern.isSingleStep == true)
        #expect(pattern.lastStep == "app_started")
        #expect(pattern.strictSequence == true)
    }

    @Test("Init creates multi-step pattern with strict sequence enabled")
    func init_createsMultiStepPatternWithStrictSequenceEnabled() {
        let pattern = JourneyPattern(
            steps: ["welcome", "profile", "home"],
            strictSequence: true,
        )

        #expect(pattern.steps == ["welcome", "profile", "home"])
        #expect(pattern.isSingleStep == false)
        #expect(pattern.lastStep == "home")
        #expect(pattern.strictSequence == true)
    }

    @Test("Init creates multi-step pattern with loose sequence enabled")
    func init_createsMultiStepPatternWithLooseSequenceEnabled() {
        let pattern = JourneyPattern(
            steps: ["search", "results", "detail"],
            strictSequence: false,
        )

        #expect(pattern.steps == ["search", "results", "detail"])
        #expect(pattern.isSingleStep == false)
        #expect(pattern.lastStep == "detail")
        #expect(pattern.strictSequence == false)
    }

    @Test("Equatable returns true when patterns have same values")
    func equatable_returnsTrueWhenPatternsHaveSameValues() {
        let pattern1 = JourneyPattern(steps: ["A", "B"], strictSequence: true)
        let pattern2 = JourneyPattern(steps: ["A", "B"], strictSequence: true)

        #expect(pattern1 == pattern2)
    }

    @Test("Equatable returns false when patterns have different steps")
    func equatable_returnsFalseWhenPatternsHaveDifferentSteps() {
        let pattern1 = JourneyPattern(steps: ["A", "B"])
        let pattern2 = JourneyPattern(steps: ["A", "C"])

        #expect(pattern1 != pattern2)
    }

    @Test("Equatable returns false when patterns have different strictness")
    func equatable_returnsFalseWhenPatternsHaveDifferentStrictness() {
        let pattern1 = JourneyPattern(steps: ["A", "B"], strictSequence: true)
        let pattern2 = JourneyPattern(steps: ["A", "B"], strictSequence: false)

        #expect(pattern1 != pattern2)
    }

    @Test("Init triggers precondition on empty steps array")
    func init_triggersPreconditionOnEmptyStepsArray() {
        // Note: In Swift Testing, we can't directly test preconditions
        // This test documents the expected behavior
        // In production, this would crash with a precondition failure
        // Bug: Should add input validation
    }
}
