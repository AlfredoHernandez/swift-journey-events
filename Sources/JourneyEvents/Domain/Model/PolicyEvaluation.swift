//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// The result of evaluating an event policy against current journey state.
///
/// Contains all information needed to decide whether to trigger an action,
/// including the reason for the decision. Used by ``EvaluateEventPolicy``
/// to communicate evaluation results to the caller.
///
/// ## Overview
///
/// Each evaluation provides:
/// - A boolean decision on whether to trigger the action
/// - Complete context (policy ID, action key, counts)
/// - A human-readable reason for debugging and logging
///
/// ## Usage
///
/// Check if action should trigger:
///
///     let evaluation = await evaluatePolicy(myPolicy)
///     if evaluation.shouldTriggerAction {
///         // Perform action using evaluation.actionKey
///         performAction(evaluation.actionKey)
///     }
///
/// Log evaluation for debugging:
///
///     print("Policy \(evaluation.policyID): \(evaluation.reason)")
///     // Output: "Policy article_ad: Threshold reached (5/5)"
///
/// Monitor progress:
///
///     let progress = "\(evaluation.currentCount)/\(evaluation.threshold)"
///     print("Progress: \(progress)")
///     // Output: "Progress: 3/5"
///
/// - SeeAlso: ``EvaluateEventPolicy`` for the evaluation use case
/// - SeeAlso: ``EventPolicy`` for policy configuration
public struct PolicyEvaluation: Sendable, Equatable {
    /// Indicates whether the action should be triggered.
    ///
    /// `true` when all conditions are met:
    /// - Pattern count reaches or exceeds threshold
    /// - Cooldown period has expired (if applicable)
    ///
    /// `false` when conditions are not met:
    /// - Pattern count is below threshold
    /// - Cooldown period is still active
    public let shouldTriggerAction: Bool

    /// The unique identifier of the evaluated policy.
    ///
    /// Matches the ``EventPolicy/id`` that was evaluated.
    public let policyID: String

    /// The action identifier from the policy.
    ///
    /// Use this to determine which action to perform when
    /// ``shouldTriggerAction`` is `true`. Matches ``EventPolicy/actionKey``.
    public let actionKey: String

    /// The current count of pattern occurrences or completions.
    ///
    /// For single-step patterns: Number of step occurrences.
    /// For multi-step patterns: Number of sequence completions.
    public let currentCount: Int

    /// The threshold required to trigger the action.
    ///
    /// Matches ``EventPolicy/threshold`` from the evaluated policy.
    public let threshold: Int

    /// A human-readable explanation of the evaluation result.
    ///
    /// Examples:
    /// - "Threshold reached (5/5)"
    /// - "Threshold not reached (3/5, 2 remaining)"
    /// - "Cooldown active (5/15 min elapsed, 10m 0s remaining)"
    ///
    /// Useful for debugging, logging, and understanding why an action
    /// triggered or didn't trigger.
    public let reason: String

    /// Creates a new policy evaluation result.
    ///
    /// - Parameters:
    ///   - shouldTriggerAction: Whether the action should be triggered
    ///   - policyID: ID of the evaluated policy
    ///   - actionKey: Action key from the policy
    ///   - currentCount: Current pattern count
    ///   - threshold: Required threshold from the policy
    ///   - reason: Human-readable explanation of the result
    public init(
        shouldTriggerAction: Bool,
        policyID: String,
        actionKey: String,
        currentCount: Int,
        threshold: Int,
        reason: String,
    ) {
        self.shouldTriggerAction = shouldTriggerAction
        self.policyID = policyID
        self.actionKey = actionKey
        self.currentCount = currentCount
        self.threshold = threshold
        self.reason = reason
    }
}
