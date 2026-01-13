//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Matches journey step sequences against expected patterns.
///
/// Provides algorithms for validating whether a sequence of user steps matches
/// an expected pattern. Used by ``TrackJourneyStep`` to validate multi-step
/// journey patterns before incrementing policy counters.
///
/// ## Overview
///
/// ``SequenceMatcher`` supports two matching modes to handle different use cases:
///
/// **Strict mode**: Steps must occur in exact consecutive order without any
/// intermediate steps. Use this for strict user flows where every step matters.
///
/// **Loose mode**: Steps must occur in the correct order but can have other
/// steps between them. Use this for flexible user flows where intermediate
/// actions are acceptable.
///
/// ## Matching Modes
///
/// ### Strict Matching
///
/// The last N steps must match the expected sequence exactly:
///
///     Expected: [A, B, C]
///     Recent:   [A, B, C]     → Match ✅
///     Recent:   [A, X, B, C]  → No Match ❌ (has intermediate step X)
///     Recent:   [A, B]        → No Match ❌ (incomplete)
///
/// ### Loose Matching
///
/// Expected steps must appear in order but can have intermediates:
///
///     Expected: [A, B, C]
///     Recent:   [A, B, C]     → Match ✅
///     Recent:   [A, X, B, C]  → Match ✅ (X is allowed intermediate)
///     Recent:   [X, A, Y, B, Z, C] → Match ✅
///     Recent:   [A, C, B]     → No Match ❌ (wrong order)
///
/// ## Usage
///
/// Create a matcher:
///
///     let matcher = SequenceMatcher()
///
/// Check strict sequence:
///
///     let steps = [
///         JourneyStep(name: "welcome"),
///         JourneyStep(name: "profile"),
///         JourneyStep(name: "home")
///     ]
///     let matches = matcher.matchesStrictSequence(
///         recentSteps: steps,
///         expectedSequence: ["welcome", "profile", "home"]
///     )
///     print(matches) // true
///
/// Check loose sequence:
///
///     let steps = [
///         JourneyStep(name: "search"),
///         JourneyStep(name: "filter"),  // Intermediate step
///         JourneyStep(name: "results"),
///         JourneyStep(name: "detail")
///     ]
///     let matches = matcher.matchesLooseSequence(
///         recentSteps: steps,
///         expectedSequence: ["search", "results", "detail"]
///     )
///     print(matches) // true
///
/// Use convenience method with pattern:
///
///     let pattern = JourneyPattern(steps: ["A", "B", "C"], strictSequence: false)
///     let matches = matcher.matches(
///         recentSteps: steps,
///         expectedSequence: pattern.steps,
///         strict: pattern.strictSequence
///     )
///
/// ## Performance
///
/// - **Strict matching**: O(n) where n is the expected sequence length
/// - **Loose matching**: O(m) where m is the number of recent steps
///
/// Both algorithms are efficient and suitable for real-time validation.
///
/// - SeeAlso: ``JourneyPattern`` for pattern configuration
/// - SeeAlso: ``TrackJourneyStep`` for usage in step tracking
public struct SequenceMatcher: Sendable {
    /// Creates a new sequence matcher.
    public init() {}

    /// Checks if recent steps match the expected sequence in strict mode.
    ///
    /// In strict mode, the last N steps must match the expected sequence exactly,
    /// without any intermediate steps.
    ///
    /// - Parameters:
    ///   - recentSteps: List of recent journey steps (oldest first)
    ///   - expectedSequence: List of step names expected in exact order
    /// - Returns: true if the sequence matches strictly, false otherwise
    public func matchesStrictSequence(
        recentSteps: [JourneyStep],
        expectedSequence: [String],
    ) -> Bool {
        // Need at least as many steps as expected
        guard recentSteps.count >= expectedSequence.count else { return false }

        // Get the last N steps where N = expected sequence length
        let lastNSteps = recentSteps.suffix(expectedSequence.count)

        // Compare step names
        return lastNSteps.map(\.name) == expectedSequence
    }

    /// Checks if recent steps contain the expected sequence in loose mode.
    ///
    /// In loose mode, the expected steps must appear in order within the recent steps,
    /// but can have intermediate steps between them.
    ///
    /// Uses a subsequence matching algorithm: iterates through recent steps and
    /// advances through expected sequence when matches are found.
    ///
    /// - Parameters:
    ///   - recentSteps: List of recent journey steps (oldest first)
    ///   - expectedSequence: List of step names expected in order (can have gaps)
    /// - Returns: true if the sequence is found in order, false otherwise
    public func matchesLooseSequence(
        recentSteps: [JourneyStep],
        expectedSequence: [String],
    ) -> Bool {
        // Need at least as many steps as expected
        guard recentSteps.count >= expectedSequence.count else { return false }

        // Use subsequence matching algorithm
        var expectedIndex = 0

        for step in recentSteps {
            // If we've matched all expected steps, we're done
            if expectedIndex >= expectedSequence.count { break }

            // If current step matches the next expected step, advance
            if step.name == expectedSequence[expectedIndex] {
                expectedIndex += 1
            }
        }

        // Success if we matched all expected steps
        return expectedIndex == expectedSequence.count
    }

    /// Matches a sequence based on the strict flag.
    ///
    /// Convenience method that dispatches to the appropriate matching function.
    ///
    /// - Parameters:
    ///   - recentSteps: List of recent journey steps
    ///   - expectedSequence: List of expected step names
    ///   - strict: If true, uses strict matching; if false, uses loose matching
    /// - Returns: true if the sequence matches according to the mode
    public func matches(
        recentSteps: [JourneyStep],
        expectedSequence: [String],
        strict: Bool,
    ) -> Bool {
        if strict {
            matchesStrictSequence(recentSteps: recentSteps, expectedSequence: expectedSequence)
        } else {
            matchesLooseSequence(recentSteps: recentSteps, expectedSequence: expectedSequence)
        }
    }
}
