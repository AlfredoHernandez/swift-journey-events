//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Defines the journey step pattern that must be fulfilled to activate a policy.
///
/// A pattern consists of one or more steps that must be fulfilled:
/// - Single step: `JourneyPattern(steps: ["line_viewed"])` - counts each occurrence
/// - Multiple steps: `JourneyPattern(steps: ["A", "B", "C"])` - validates sequence completion
///
/// The sequence validation can be:
/// - Strict (`strictSequence = true`): Steps must occur exactly in order [A, B, C]
/// - Loose (`strictSequence = false`): Steps can have intermediates [A, X, B, Y, C]
///
/// Example usage:
/// ```swift
/// // Single step pattern (counts each occurrence)
/// JourneyPattern(steps: ["line_viewed"])
///
/// // Strict sequence (must be exact order)
/// JourneyPattern(
///     steps: ["app_started", "line_viewed", "station_selected"],
///     strictSequence: true
/// )
///
/// // Loose sequence (allows intermediate steps)
/// JourneyPattern(
///     steps: ["search_started", "results_viewed", "item_selected"],
///     strictSequence: false
/// )
/// ```
public struct JourneyPattern: Sendable, Equatable {
    /// List of step names that form the pattern (must not be empty)
    public let steps: [String]

    /// Whether the sequence must be exact (true) or can have intermediate steps (false)
    public let strictSequence: Bool

    /// Creates a new journey pattern.
    /// - Parameters:
    ///   - steps: List of step names that form the pattern (must not be empty)
    ///   - strictSequence: Whether the sequence must be exact (default: true)
    public init(steps: [String], strictSequence: Bool = true) {
        precondition(!steps.isEmpty, "Pattern must have at least one step")
        self.steps = steps
        self.strictSequence = strictSequence
    }

    /// Returns true if this pattern represents a single step.
    /// Single-step patterns trigger on each occurrence of the step.
    public var isSingleStep: Bool {
        steps.count == 1
    }

    /// Returns the last step in the sequence.
    /// Useful for indexing policies that should only be evaluated when this step occurs.
    public var lastStep: String {
        steps.last!
    }
}
