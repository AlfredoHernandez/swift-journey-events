//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Result of evaluating an event policy.
///
/// Contains all necessary information to decide whether to trigger an action
/// and for debugging/logging purposes.
public struct PolicyEvaluation: Sendable, Equatable {
    /// Whether the action should be triggered according to the evaluation
    public let shouldTriggerAction: Bool

    /// ID of the evaluated policy
    public let policyID: String

    /// Action key to trigger the correct action (e.g., ad unit ID, analytics event)
    public let actionKey: String

    /// Current count of pattern occurrences
    public let currentCount: Int

    /// Threshold needed to trigger the action
    public let threshold: Int

    /// Description of the result for debugging/logging
    public let reason: String

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
