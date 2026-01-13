//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Matches journey step sequences against expected patterns.
///
/// Supports two matching modes:
/// - **Strict**: Steps must occur in exact order without intermediates
/// - **Loose**: Steps must occur in order but can have intermediate steps
///
/// ## Examples
///
/// ### Strict Matching
/// ```
/// Expected: [A, B, C]
/// Recent:   [A, B, C]     → Match ✅
/// Recent:   [A, X, B, C]  → No Match ❌ (has intermediate step X)
/// Recent:   [A, B]        → No Match ❌ (incomplete)
/// ```
///
/// ### Loose Matching
/// ```
/// Expected: [A, B, C]
/// Recent:   [A, B, C]     → Match ✅
/// Recent:   [A, X, B, C]  → Match ✅ (X is allowed intermediate)
/// Recent:   [X, A, Y, B, Z, C] → Match ✅
/// Recent:   [A, C, B]     → No Match ❌ (wrong order)
/// ```
public struct SequenceMatcher: Sendable {
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
