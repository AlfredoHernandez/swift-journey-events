//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents

public extension EventPolicy {
	/// Builds a single-step policy keyed on `step`, triggered every `threshold` occurrences.
	static func singleStep(
		id: String,
		actionKey: String = "test_action",
		step: String,
		threshold: Int,
		cooldownMinutes: Int = 0,
		persistAcrossSessions: Bool = true,
	) -> EventPolicy {
		EventPolicy(
			id: id,
			actionKey: actionKey,
			pattern: JourneyPattern(steps: [step]),
			threshold: threshold,
			cooldownMinutes: cooldownMinutes,
			persistAcrossSessions: persistAcrossSessions,
		)
	}

	/// Builds a multi-step sequence policy.
	static func sequence(
		id: String,
		actionKey: String = "test_action",
		steps: [String],
		threshold: Int = 1,
		strict: Bool = true,
		cooldownMinutes: Int = 0,
		persistAcrossSessions: Bool = true,
	) -> EventPolicy {
		EventPolicy(
			id: id,
			actionKey: actionKey,
			pattern: JourneyPattern(steps: steps, strictSequence: strict),
			threshold: threshold,
			cooldownMinutes: cooldownMinutes,
			persistAcrossSessions: persistAcrossSessions,
		)
	}
}
