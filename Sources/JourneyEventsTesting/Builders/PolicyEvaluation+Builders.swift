//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents

public extension PolicyEvaluation {
	/// Builds a triggered evaluation with sensible defaults.
	static func triggered(
		policyID: String,
		actionKey: String = "test_action",
		currentCount: Int = 1,
		threshold: Int = 1,
		reason: String = "Threshold reached",
	) -> PolicyEvaluation {
		PolicyEvaluation(
			shouldTriggerAction: true,
			policyID: policyID,
			actionKey: actionKey,
			currentCount: currentCount,
			threshold: threshold,
			reason: reason,
		)
	}

	/// Builds a non-triggering evaluation with sensible defaults.
	static func skipped(
		policyID: String,
		actionKey: String = "test_action",
		currentCount: Int = 0,
		threshold: Int = 1,
		reason: String = "Threshold not reached",
	) -> PolicyEvaluation {
		PolicyEvaluation(
			shouldTriggerAction: false,
			policyID: policyID,
			actionKey: actionKey,
			currentCount: currentCount,
			threshold: threshold,
			reason: reason,
		)
	}
}
