//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents
import JourneyEventsTesting
import Testing

struct RecordingJourneyLoggerTests {
	@Test
	func `Records every step passed to logStepRecorded in order`() {
		let logger = RecordingJourneyLogger()

		logger.logStepRecorded(JourneyStep(name: "first", timestamp: 1))
		logger.logStepRecorded(JourneyStep(name: "second", timestamp: 2))

		#expect(logger.recordedSteps.map(\.name) == ["first", "second"])
	}

	@Test
	func `Records every policy evaluation in order`() {
		let logger = RecordingJourneyLogger()
		let evaluation = PolicyEvaluation(
			shouldTriggerAction: true,
			policyID: "p",
			actionKey: "a",
			currentCount: 1,
			threshold: 1,
			reason: "ok",
		)

		logger.logPolicyEvaluated(evaluation)

		#expect(logger.evaluations == [evaluation])
	}

	@Test
	func `Records policy resets`() {
		let logger = RecordingJourneyLogger()

		logger.logPolicyReset(policyID: "p1")
		logger.logPolicyReset(policyID: "p2")

		#expect(logger.resets == ["p1", "p2"])
	}

	@Test
	func `Records errors with their messages`() {
		let logger = RecordingJourneyLogger()

		logger.logError("boom", error: nil)
		logger.logError("kapow", error: nil)

		#expect(logger.errorMessages == ["boom", "kapow"])
	}

	@Test
	func `Clear empties every recorded buffer`() {
		let logger = RecordingJourneyLogger()
		logger.logStepRecorded(JourneyStep(name: "x", timestamp: 0))
		logger.logPolicyReset(policyID: "p")
		logger.logError("e", error: nil)

		logger.clear()

		#expect(logger.recordedSteps.isEmpty)
		#expect(logger.evaluations.isEmpty)
		#expect(logger.resets.isEmpty)
		#expect(logger.errorMessages.isEmpty)
	}

	@Test
	func `Records concurrently from many tasks without losing entries`() async {
		let logger = RecordingJourneyLogger()
		let totalTasks = 200

		await withTaskGroup(of: Void.self) { group in
			for i in 0 ..< totalTasks {
				group.addTask {
					logger.logStepRecorded(JourneyStep(name: "step_\(i)", timestamp: Int64(i)))
				}
			}
		}

		#expect(logger.recordedSteps.count == totalTasks)
	}
}
