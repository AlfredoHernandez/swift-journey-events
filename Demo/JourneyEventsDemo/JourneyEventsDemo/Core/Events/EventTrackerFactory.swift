//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents

/// Factory for creating and configuring the EventTracker for the news feed app.
enum EventTrackerFactory {
	/// Creates a fully configured EventTracker instance.
	///
	/// Sets up all dependencies including:
	/// - Session-scoped repositories shipped by `JourneyEvents` for session-based tracking
	/// - News feed policy provider
	/// - No-op logger (the demo prints triggers from the AsyncStream)
	/// - System time provider for cooldown calculations
	static func create() -> EventTracker {
		let policyProvider = NewsFeedPolicyProvider()
		let journeyStepRepository = SessionJourneyStepRepository()
		let eventStateRepository = SessionEventStateRepository()
		let sequenceMatcher = SequenceMatcher()
		let timeProvider = SystemTimeProvider()
		let logger = NoOpJourneyLogger()

		let trackJourneyStep = TrackJourneyStep(
			journeyStepRepository: journeyStepRepository,
			eventStateRepository: eventStateRepository,
			policyProvider: policyProvider,
			sequenceMatcher: sequenceMatcher,
		)

		let evaluateEventPolicy = EvaluateEventPolicy(
			eventStateRepository: eventStateRepository,
			logger: logger,
			timeProvider: timeProvider,
		)

		return EventTracker(
			trackJourneyStep: trackJourneyStep,
			evaluateEventPolicy: evaluateEventPolicy,
			policyProvider: policyProvider,
			logger: logger,
		)
	}
}
