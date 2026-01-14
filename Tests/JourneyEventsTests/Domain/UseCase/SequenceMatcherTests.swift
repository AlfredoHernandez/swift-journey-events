//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Testing

@Suite("SequenceMatcher Tests")
struct SequenceMatcherTests {
    let matcher = SequenceMatcher()

    // MARK: - Strict Sequence Matching Tests

    @Suite("Strict Sequence Matching")
    struct StrictSequenceTests {
        let matcher = SequenceMatcher()

        @Test("MatchesStrictSequence returns true on exact sequence match")
        func matchesStrictSequence_returnsTrueOnExactSequenceMatch() {
            let steps = [
                JourneyStep(name: "A", timestamp: 1),
                JourneyStep(name: "B", timestamp: 2),
                JourneyStep(name: "C", timestamp: 3),
            ]

            let matches = matcher.matchesStrictSequence(
                recentSteps: steps,
                expectedSequence: ["A", "B", "C"],
            )

            #expect(matches == true)
        }

        @Test("MatchesStrictSequence returns true when more steps than needed")
        func matchesStrictSequence_returnsTrueWhenMoreStepsThanNeeded() {
            let steps = [
                JourneyStep(name: "X", timestamp: 1),
                JourneyStep(name: "A", timestamp: 2),
                JourneyStep(name: "B", timestamp: 3),
                JourneyStep(name: "C", timestamp: 4),
            ]

            let matches = matcher.matchesStrictSequence(
                recentSteps: steps,
                expectedSequence: ["A", "B", "C"],
            )

            #expect(matches == true)
        }

        @Test("MatchesStrictSequence returns false on intermediate step")
        func matchesStrictSequence_returnsFalseOnIntermediateStep() {
            let steps = [
                JourneyStep(name: "A", timestamp: 1),
                JourneyStep(name: "X", timestamp: 2),
                JourneyStep(name: "B", timestamp: 3),
                JourneyStep(name: "C", timestamp: 4),
            ]

            let matches = matcher.matchesStrictSequence(
                recentSteps: steps,
                expectedSequence: ["A", "B", "C"],
            )

            #expect(matches == false)
        }

        @Test("MatchesStrictSequence returns false on incomplete sequence")
        func matchesStrictSequence_returnsFalseOnIncompleteSequence() {
            let steps = [
                JourneyStep(name: "A", timestamp: 1),
                JourneyStep(name: "B", timestamp: 2),
            ]

            let matches = matcher.matchesStrictSequence(
                recentSteps: steps,
                expectedSequence: ["A", "B", "C"],
            )

            #expect(matches == false)
        }

        @Test("MatchesStrictSequence returns false on wrong order")
        func matchesStrictSequence_returnsFalseOnWrongOrder() {
            let steps = [
                JourneyStep(name: "A", timestamp: 1),
                JourneyStep(name: "C", timestamp: 2),
                JourneyStep(name: "B", timestamp: 3),
            ]

            let matches = matcher.matchesStrictSequence(
                recentSteps: steps,
                expectedSequence: ["A", "B", "C"],
            )

            #expect(matches == false)
        }

        @Test("MatchesStrictSequence returns true on single step match")
        func matchesStrictSequence_returnsTrueOnSingleStepMatch() {
            let steps = [
                JourneyStep(name: "X", timestamp: 1),
                JourneyStep(name: "A", timestamp: 2),
            ]

            let matches = matcher.matchesStrictSequence(
                recentSteps: steps,
                expectedSequence: ["A"],
            )

            #expect(matches == true)
        }
    }

    // MARK: - Loose Sequence Matching Tests

    @Suite("Loose Sequence Matching")
    struct LooseSequenceTests {
        let matcher = SequenceMatcher()

        @Test("MatchesLooseSequence returns true on exact sequence match")
        func matchesLooseSequence_returnsTrueOnExactSequenceMatch() {
            let steps = [
                JourneyStep(name: "A", timestamp: 1),
                JourneyStep(name: "B", timestamp: 2),
                JourneyStep(name: "C", timestamp: 3),
            ]

            let matches = matcher.matchesLooseSequence(
                recentSteps: steps,
                expectedSequence: ["A", "B", "C"],
            )

            #expect(matches == true)
        }

        @Test("MatchesLooseSequence returns true with single intermediate step")
        func matchesLooseSequence_returnsTrueWithSingleIntermediateStep() {
            let steps = [
                JourneyStep(name: "A", timestamp: 1),
                JourneyStep(name: "X", timestamp: 2),
                JourneyStep(name: "B", timestamp: 3),
                JourneyStep(name: "C", timestamp: 4),
            ]

            let matches = matcher.matchesLooseSequence(
                recentSteps: steps,
                expectedSequence: ["A", "B", "C"],
            )

            #expect(matches == true)
        }

        @Test("MatchesLooseSequence returns true with multiple intermediate steps")
        func matchesLooseSequence_returnsTrueWithMultipleIntermediateSteps() {
            let steps = [
                JourneyStep(name: "X", timestamp: 1),
                JourneyStep(name: "A", timestamp: 2),
                JourneyStep(name: "Y", timestamp: 3),
                JourneyStep(name: "B", timestamp: 4),
                JourneyStep(name: "Z", timestamp: 5),
                JourneyStep(name: "C", timestamp: 6),
            ]

            let matches = matcher.matchesLooseSequence(
                recentSteps: steps,
                expectedSequence: ["A", "B", "C"],
            )

            #expect(matches == true)
        }

        @Test("MatchesLooseSequence returns false on wrong order with intermediates")
        func matchesLooseSequence_returnsFalseOnWrongOrderWithIntermediates() {
            let steps = [
                JourneyStep(name: "A", timestamp: 1),
                JourneyStep(name: "C", timestamp: 2),
                JourneyStep(name: "B", timestamp: 3),
            ]

            let matches = matcher.matchesLooseSequence(
                recentSteps: steps,
                expectedSequence: ["A", "B", "C"],
            )

            #expect(matches == false)
        }

        @Test("MatchesLooseSequence returns false on incomplete sequence")
        func matchesLooseSequence_returnsFalseOnIncompleteSequence() {
            let steps = [
                JourneyStep(name: "A", timestamp: 1),
                JourneyStep(name: "B", timestamp: 2),
            ]

            let matches = matcher.matchesLooseSequence(
                recentSteps: steps,
                expectedSequence: ["A", "B", "C"],
            )

            #expect(matches == false)
        }

        @Test("MatchesLooseSequence returns true on single step with intermediates")
        func matchesLooseSequence_returnsTrueOnSingleStepWithIntermediates() {
            let steps = [
                JourneyStep(name: "X", timestamp: 1),
                JourneyStep(name: "Y", timestamp: 2),
                JourneyStep(name: "A", timestamp: 3),
            ]

            let matches = matcher.matchesLooseSequence(
                recentSteps: steps,
                expectedSequence: ["A"],
            )

            #expect(matches == true)
        }
    }

    // MARK: - Convenience Method Tests

    @Suite("Convenience Method")
    struct ConvenienceMethodTests {
        let matcher = SequenceMatcher()

        @Test("Matches dispatches to strict matching when strict is true")
        func matches_dispatchesToStrictMatchingWhenStrictIsTrue() {
            let steps = [
                JourneyStep(name: "A", timestamp: 1),
                JourneyStep(name: "X", timestamp: 2),
                JourneyStep(name: "B", timestamp: 3),
            ]

            let matches = matcher.matches(
                recentSteps: steps,
                expectedSequence: ["A", "B"],
                strict: true,
            )

            #expect(matches == false)
        }

        @Test("Matches dispatches to loose matching when strict is false")
        func matches_dispatchesToLooseMatchingWhenStrictIsFalse() {
            let steps = [
                JourneyStep(name: "A", timestamp: 1),
                JourneyStep(name: "X", timestamp: 2),
                JourneyStep(name: "B", timestamp: 3),
            ]

            let matches = matcher.matches(
                recentSteps: steps,
                expectedSequence: ["A", "B"],
                strict: false,
            )

            #expect(matches == true)
        }
    }

    // MARK: - Edge Cases

    @Suite("Edge Cases")
    struct EdgeCaseTests {
        let matcher = SequenceMatcher()

        @Test("MatchesStrictSequence returns false on empty recent steps")
        func matchesStrictSequence_returnsFalseOnEmptyRecentSteps() {
            let matches = matcher.matchesStrictSequence(
                recentSteps: [],
                expectedSequence: ["A"],
            )

            #expect(matches == false)
        }

        @Test("MatchesStrictSequence returns false when expected exceeds recent steps")
        func matchesStrictSequence_returnsFalseWhenExpectedExceedsRecentSteps() {
            let steps = [
                JourneyStep(name: "A", timestamp: 1),
            ]

            let matches = matcher.matchesStrictSequence(
                recentSteps: steps,
                expectedSequence: ["A", "B", "C"],
            )

            #expect(matches == false)
        }
    }
}
