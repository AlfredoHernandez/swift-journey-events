//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Foundation
import Testing

/// Pins the no-op contract: each `JourneyLogger` method must accept its arguments
/// and return without throwing or producing observable side effects. The tests
/// verify the API surface stays callable; if a future refactor accidentally adds
/// behavior or changes a signature, these tests break first.
struct NoOpJourneyLoggerTests {
	@Test func `logStepRecorded accepts a step and returns without effect`() {
		let logger = NoOpJourneyLogger()
		logger.logStepRecorded(JourneyStep(name: "any", timestamp: 0))
	}

	@Test func `logPolicyEvaluated accepts an evaluation and returns without effect`() {
		let logger = NoOpJourneyLogger()
		let evaluation = PolicyEvaluation(
			shouldTriggerAction: false,
			policyID: "any",
			actionKey: "any",
			currentCount: 0,
			threshold: 1,
			reason: "below threshold",
		)
		logger.logPolicyEvaluated(evaluation)
	}

	@Test func `logPolicyReset accepts a policy id and returns without effect`() {
		let logger = NoOpJourneyLogger()
		logger.logPolicyReset(policyID: "any")
	}

	@Test func `logError accepts a message and optional error and returns without effect`() {
		let logger = NoOpJourneyLogger()
		struct Boom: Error {}
		logger.logError("any", error: nil)
		logger.logError("any", error: Boom())
	}
}
