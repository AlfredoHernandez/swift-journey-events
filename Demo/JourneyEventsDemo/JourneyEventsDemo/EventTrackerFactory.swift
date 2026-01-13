//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents

/// Factory for creating and configuring the EventTracker for the news feed app.
enum EventTrackerFactory {
    /// Creates a fully configured EventTracker instance.
    ///
    /// Sets up all dependencies including:
    /// - In-memory repositories for session-based tracking
    /// - News feed policy provider
    /// - OSLog-based logger for debugging
    /// - System time provider for cooldown calculations
    static func create() -> EventTracker {
        let policyProvider = NewsFeedPolicyProvider()
        let journeyStepRepository = InMemoryJourneyStepRepository()
        let eventStateRepository = InMemoryEventStateRepository()
        let sequenceMatcher = SequenceMatcher()
        let timeProvider = SystemTimeProvider()
        let logger = OSLogJourneyLogger()

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
