//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Defines the journey step pattern that must be fulfilled to activate a policy.
///
/// A pattern specifies one or more steps in a user's journey that must occur
/// before a policy action can be triggered. Patterns support both single-step
/// counting and multi-step sequence validation.
///
/// ## Overview
///
/// Patterns come in two forms:
///
/// **Single-step patterns** count each individual occurrence:
/// - Used for simple frequency-based triggers
/// - Example: Show ad after user views 5 articles
///
/// **Multi-step patterns** validate sequences of steps:
/// - Used for behavior flow validation
/// - Support strict (exact order) or loose (allows intermediates) matching
/// - Example: Show tutorial after user completes onboarding flow
///
/// ## Pattern Types
///
/// ### Single Step Pattern
///
/// Counts each occurrence of a specific step:
///
///     let pattern = JourneyPattern(steps: ["article_viewed"])
///     // Triggers when step occurs N times (defined by policy threshold)
///
/// ### Strict Sequence Pattern
///
/// Steps must occur in exact order without intermediates:
///
///     let pattern = JourneyPattern(
///         steps: ["app_started", "tutorial_viewed", "profile_created"],
///         strictSequence: true
///     )
///     // Matches: [app_started, tutorial_viewed, profile_created] ✓
///     // Rejects: [app_started, home_viewed, tutorial_viewed, profile_created] ✗
///
/// ### Loose Sequence Pattern
///
/// Steps must occur in order but can have intermediate steps:
///
///     let pattern = JourneyPattern(
///         steps: ["search_started", "results_viewed", "item_selected"],
///         strictSequence: false
///     )
///     // Matches: [search_started, filter_applied, results_viewed, scroll, item_selected] ✓
///     // Rejects: [search_started, item_selected, results_viewed] ✗ (wrong order)
///
/// - Note: All patterns must contain at least one step name.
/// - SeeAlso: ``EventPolicy`` for defining trigger conditions based on patterns
/// - SeeAlso: ``SequenceMatcher`` for the sequence matching algorithm
public struct JourneyPattern: Sendable, Equatable {
    /// The list of step names that form this pattern.
    ///
    /// For single-step patterns, contains one step name.
    /// For multi-step patterns, contains the sequence of step names in expected order.
    ///
    /// - Precondition: Array must not be empty.
    public let steps: [String]

    /// Determines whether sequence matching is strict or loose.
    ///
    /// - `true`: Steps must occur in exact consecutive order (strict)
    /// - `false`: Steps must occur in order but can have intermediates (loose)
    ///
    /// Only applies to multi-step patterns. Ignored for single-step patterns.
    public let strictSequence: Bool

    /// Creates a new journey pattern.
    ///
    /// - Parameters:
    ///   - steps: List of step names forming the pattern
    ///   - strictSequence: Whether to use strict sequence matching (default: true)
    ///
    /// - Precondition: `steps` array must contain at least one element.
    public init(steps: [String], strictSequence: Bool = true) {
        precondition(!steps.isEmpty, "Pattern must have at least one step")
        self.steps = steps
        self.strictSequence = strictSequence
    }

    /// Indicates whether this pattern represents a single step.
    ///
    /// Single-step patterns trigger on each occurrence and don't require sequence validation.
    ///
    /// - Returns: `true` if the pattern contains exactly one step, `false` otherwise.
    public var isSingleStep: Bool {
        steps.count == 1
    }

    /// Returns the last step in the sequence.
    ///
    /// Used by the event tracker to index policies efficiently. Only policies
    /// whose pattern ends with the current step need to be evaluated.
    ///
    /// - Returns: The name of the last step in the pattern.
    public var lastStep: String {
        steps.last!
    }
}
