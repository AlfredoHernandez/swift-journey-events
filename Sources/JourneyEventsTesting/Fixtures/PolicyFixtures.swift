//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents

/// Pre-armed policies covering the most common rate-limited test scenarios.
public enum PolicyFixtures {
	/// A policy that triggers `actionKey` every `n` occurrences of `step`, optionally cooled-down.
	public static func interstitialEvery(
		n: Int,
		step: String = "screen_viewed",
		actionKey: String = "show_interstitial",
		cooldown: Int = 0,
		id: String = "interstitial_policy",
	) -> EventPolicy {
		EventPolicy.singleStep(
			id: id,
			actionKey: actionKey,
			step: step,
			threshold: n,
			cooldownMinutes: cooldown,
		)
	}

	/// A policy that triggers `actionKey` once an onboarding sequence completes.
	public static func onboardingCompleted(
		actionKey: String = "show_welcome",
		id: String = "onboarding_policy",
	) -> EventPolicy {
		EventPolicy.sequence(
			id: id,
			actionKey: actionKey,
			steps: ["signup", "profile_created", "first_action"],
			threshold: 1,
			strict: false,
		)
	}
}
