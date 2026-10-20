//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// When a triggered ``EventPolicy`` spends its cycle: resets its counter and,
/// if it has one, starts its cooldown.
public enum PolicyCommitMode: Sendable, Equatable {
	/// The evaluation that reaches the threshold spends the cycle immediately.
	///
	/// Right for actions that always happen once triggered.
	case onTrigger

	/// The evaluation reports the trigger but leaves the counter and cooldown
	/// untouched until the caller commits the cycle.
	///
	/// Until then every evaluation of the policy keeps triggering, so an action
	/// that was skipped or failed gets another chance on the very next eligible
	/// step instead of waiting a whole new cycle. Commit with
	/// ``EventTracker/commit(policyID:)`` or ``EvaluateEventPolicy/commit(_:)``
	/// once the action actually happened.
	case deferred
}
