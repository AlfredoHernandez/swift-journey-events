//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import JourneyEventsTesting
import Testing

struct EvaluateEventPolicyTests {
	// MARK: - Basic Threshold Tests

	struct BasicThresholdTests {
		@Test
		func `Evaluate returns false when threshold not reached`() async {
			let repository = InMemoryEventStateRepository()
			let logger = RecordingJourneyLogger()
			let timeProvider = MockTimeProvider()
			let evaluator = EvaluateEventPolicy(
				eventStateRepository: repository,
				logger: logger,
				timeProvider: timeProvider,
			)

			let policy = TestFactory.createPolicy(
				id: "test_policy",
				actionKey: "test_action",
				steps: ["test"],
				threshold: 5,
			)

			await repository.incrementCount(policyID: "test_policy")
			await repository.incrementCount(policyID: "test_policy")

			let evaluation = await evaluator(policy)

			#expect(evaluation.shouldTriggerAction == false)
			#expect(evaluation.currentCount == 2)
			#expect(evaluation.threshold == 5)
			#expect(evaluation.reason.contains("not reached"))
			#expect(evaluation.reason.contains("3 remaining"))
		}

		@Test
		func `Evaluate returns true when threshold exactly reached`() async {
			let repository = InMemoryEventStateRepository()
			let logger = RecordingJourneyLogger()
			let timeProvider = MockTimeProvider()
			let evaluator = EvaluateEventPolicy(
				eventStateRepository: repository,
				logger: logger,
				timeProvider: timeProvider,
			)

			let policy = TestFactory.createPolicy(
				id: "test_policy",
				actionKey: "test_action",
				steps: ["test"],
				threshold: 3,
			)

			await repository.incrementCount(policyID: "test_policy")
			await repository.incrementCount(policyID: "test_policy")
			await repository.incrementCount(policyID: "test_policy")

			let evaluation = await evaluator(policy)

			#expect(evaluation.shouldTriggerAction == true)
			#expect(evaluation.currentCount == 3)
			#expect(evaluation.threshold == 3)
			#expect(evaluation.reason.contains("Threshold reached"))
		}

		@Test
		func `Evaluate returns true when threshold exceeded`() async {
			let repository = InMemoryEventStateRepository()
			let logger = RecordingJourneyLogger()
			let timeProvider = MockTimeProvider()
			let evaluator = EvaluateEventPolicy(
				eventStateRepository: repository,
				logger: logger,
				timeProvider: timeProvider,
			)

			let policy = TestFactory.createPolicy(
				id: "test_policy",
				actionKey: "test_action",
				steps: ["test"],
				threshold: 3,
			)

			for _ in 0 ..< 5 {
				await repository.incrementCount(policyID: "test_policy")
			}

			let evaluation = await evaluator(policy)

			#expect(evaluation.shouldTriggerAction == true)
			#expect(evaluation.currentCount == 5)
		}

		@Test
		func `Evaluate resets counter when action triggers`() async {
			let repository = InMemoryEventStateRepository()
			let logger = RecordingJourneyLogger()
			let timeProvider = MockTimeProvider()
			let evaluator = EvaluateEventPolicy(
				eventStateRepository: repository,
				logger: logger,
				timeProvider: timeProvider,
			)

			let policy = TestFactory.createPolicy(
				id: "test_policy",
				actionKey: "test_action",
				steps: ["test"],
				threshold: 2,
			)

			await repository.incrementCount(policyID: "test_policy")
			await repository.incrementCount(policyID: "test_policy")

			let evaluation = await evaluator(policy)

			#expect(evaluation.shouldTriggerAction == true)

			let countAfter = await repository.getCount(policyID: "test_policy")
			#expect(countAfter == 0)
		}

		@Test
		func `Evaluate logs policy reset when action triggers`() async {
			let repository = InMemoryEventStateRepository()
			let logger = RecordingJourneyLogger()
			let timeProvider = MockTimeProvider()
			let evaluator = EvaluateEventPolicy(
				eventStateRepository: repository,
				logger: logger,
				timeProvider: timeProvider,
			)

			let policy = TestFactory.createPolicy(
				id: "test_policy",
				actionKey: "test_action",
				steps: ["test"],
				threshold: 1,
			)

			await repository.incrementCount(policyID: "test_policy")
			_ = await evaluator(policy)

			#expect(logger.resets.count == 1)
			#expect(logger.resets[0] == "test_policy")
		}
	}

	// MARK: - Cooldown Tests

	struct CooldownTests {
		@Test
		func `Evaluate allows trigger when no previous action timestamp exists`() async {
			let repository = InMemoryEventStateRepository()
			let logger = RecordingJourneyLogger()
			let timeProvider = MockTimeProvider()
			timeProvider.currentTime = 10000
			let evaluator = EvaluateEventPolicy(
				eventStateRepository: repository,
				logger: logger,
				timeProvider: timeProvider,
			)

			let policy = TestFactory.createPolicy(
				id: "test_policy",
				actionKey: "test_action",
				steps: ["test"],
				threshold: 1,
				cooldown: 15,
			)

			await repository.incrementCount(policyID: "test_policy")

			let evaluation = await evaluator(policy)

			#expect(evaluation.shouldTriggerAction == true)
		}

		@Test
		func `Evaluate blocks trigger when cooldown is active`() async {
			let repository = InMemoryEventStateRepository()
			let logger = RecordingJourneyLogger()
			let timeProvider = MockTimeProvider()
			timeProvider.currentTime = 10000
			let evaluator = EvaluateEventPolicy(
				eventStateRepository: repository,
				logger: logger,
				timeProvider: timeProvider,
			)

			let policy = TestFactory.createPolicy(
				id: "test_policy",
				actionKey: "test_action",
				steps: ["test"],
				threshold: 1,
				cooldown: 15, // 15 minutes
			)

			// Simulate previous action at time 10000
			await repository.setLastActionTriggeredTimestamp(
				policyID: "test_policy",
				timestamp: 10000,
			)

			// Advance time by 5 minutes (cooldown still active)
			timeProvider.currentTime = 10000 + (5 * 60 * 1000)

			await repository.incrementCount(policyID: "test_policy")

			let evaluation = await evaluator(policy)

			#expect(evaluation.shouldTriggerAction == false)
			#expect(evaluation.reason.contains("Cooldown active"))
			#expect(evaluation.reason.contains("5/15 min elapsed"))
		}

		@Test
		func `Evaluate allows trigger when cooldown expires`() async {
			let repository = InMemoryEventStateRepository()
			let logger = RecordingJourneyLogger()
			let timeProvider = MockTimeProvider()
			timeProvider.currentTime = 10000
			let evaluator = EvaluateEventPolicy(
				eventStateRepository: repository,
				logger: logger,
				timeProvider: timeProvider,
			)

			let policy = TestFactory.createPolicy(
				id: "test_policy",
				actionKey: "test_action",
				steps: ["test"],
				threshold: 1,
				cooldown: 10, // 10 minutes
			)

			// Simulate previous action at time 10000
			await repository.setLastActionTriggeredTimestamp(
				policyID: "test_policy",
				timestamp: 10000,
			)

			// Advance time by 15 minutes (cooldown expired)
			timeProvider.currentTime = 10000 + (15 * 60 * 1000)

			await repository.incrementCount(policyID: "test_policy")

			let evaluation = await evaluator(policy)

			#expect(evaluation.shouldTriggerAction == true)
		}

		@Test
		func `Evaluate records timestamp when action triggers with cooldown`() async {
			let repository = InMemoryEventStateRepository()
			let logger = RecordingJourneyLogger()
			let timeProvider = MockTimeProvider()
			timeProvider.currentTime = 20000
			let evaluator = EvaluateEventPolicy(
				eventStateRepository: repository,
				logger: logger,
				timeProvider: timeProvider,
			)

			let policy = TestFactory.createPolicy(
				id: "test_policy",
				actionKey: "test_action",
				steps: ["test"],
				threshold: 1,
				cooldown: 10,
			)

			await repository.incrementCount(policyID: "test_policy")
			_ = await evaluator(policy)

			let timestamp = await repository.getLastActionTriggeredTimestamp(
				policyID: "test_policy",
			)

			#expect(timestamp == 20000)
		}

		@Test
		func `Evaluate does not record timestamp when cooldown is zero`() async {
			let repository = InMemoryEventStateRepository()
			let logger = RecordingJourneyLogger()
			let timeProvider = MockTimeProvider()
			timeProvider.currentTime = 20000
			let evaluator = EvaluateEventPolicy(
				eventStateRepository: repository,
				logger: logger,
				timeProvider: timeProvider,
			)

			let policy = TestFactory.createPolicy(
				id: "test_policy",
				actionKey: "test_action",
				steps: ["test"],
				threshold: 1,
				cooldown: 0,
			)

			await repository.incrementCount(policyID: "test_policy")
			_ = await evaluator(policy)

			let timestamp = await repository.getLastActionTriggeredTimestamp(
				policyID: "test_policy",
			)

			#expect(timestamp == nil)
		}
	}

	// MARK: - Evaluation Result Tests

	struct EvaluationResultTests {
		@Test
		func `Evaluate returns correct policy metadata in result`() async {
			let repository = InMemoryEventStateRepository()
			let logger = RecordingJourneyLogger()
			let timeProvider = MockTimeProvider()
			let evaluator = EvaluateEventPolicy(
				eventStateRepository: repository,
				logger: logger,
				timeProvider: timeProvider,
			)

			let policy = TestFactory.createPolicy(
				id: "my_policy",
				actionKey: "my_action_key",
				steps: ["test"],
				threshold: 3,
			)

			let evaluation = await evaluator(policy)

			#expect(evaluation.policyID == "my_policy")
			#expect(evaluation.actionKey == "my_action_key")
			#expect(evaluation.threshold == 3)
		}

		@Test
		func `Evaluate returns accurate remaining count in reason text`() async {
			let repository = InMemoryEventStateRepository()
			let logger = RecordingJourneyLogger()
			let timeProvider = MockTimeProvider()
			let evaluator = EvaluateEventPolicy(
				eventStateRepository: repository,
				logger: logger,
				timeProvider: timeProvider,
			)

			let policy = TestFactory.createPolicy(
				id: "test_policy",
				actionKey: "test_action",
				steps: ["test"],
				threshold: 10,
			)

			for _ in 0 ..< 7 {
				await repository.incrementCount(policyID: "test_policy")
			}

			let evaluation = await evaluator(policy)

			#expect(evaluation.reason.contains("7/10"))
			#expect(evaluation.reason.contains("3 remaining"))
		}
	}
}
