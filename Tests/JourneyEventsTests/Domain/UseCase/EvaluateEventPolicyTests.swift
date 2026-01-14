//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Testing

@Suite("EvaluateEventPolicy Tests")
struct EvaluateEventPolicyTests {
    // MARK: - Basic Threshold Tests

    @Suite("Basic Threshold Evaluation")
    struct BasicThresholdTests {
        @Test("Evaluate returns false when threshold not reached")
        func evaluate_returnsFalseWhenThresholdNotReached() async {
            let repository = InMemoryEventStateRepository()
            let logger = MockLogger()
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

        @Test("Evaluate returns true when threshold exactly reached")
        func evaluate_returnsTrueWhenThresholdExactlyReached() async {
            let repository = InMemoryEventStateRepository()
            let logger = MockLogger()
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

        @Test("Evaluate returns true when threshold exceeded")
        func evaluate_returnsTrueWhenThresholdExceeded() async {
            let repository = InMemoryEventStateRepository()
            let logger = MockLogger()
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

        @Test("Evaluate resets counter when action triggers")
        func evaluate_resetsCounterWhenActionTriggers() async {
            let repository = InMemoryEventStateRepository()
            let logger = MockLogger()
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

        @Test("Evaluate logs policy reset when action triggers")
        func evaluate_logsPolicyResetWhenActionTriggers() async {
            let repository = InMemoryEventStateRepository()
            let logger = MockLogger()
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

    @Suite("Cooldown Evaluation")
    struct CooldownTests {
        @Test("Evaluate allows trigger when no previous action timestamp exists")
        func evaluate_allowsTriggerWhenNoPreviousActionTimestampExists() async {
            let repository = InMemoryEventStateRepository()
            let logger = MockLogger()
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

        @Test("Evaluate blocks trigger when cooldown is active")
        func evaluate_blocksTriggerWhenCooldownIsActive() async {
            let repository = InMemoryEventStateRepository()
            let logger = MockLogger()
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

        @Test("Evaluate allows trigger when cooldown expires")
        func evaluate_allowsTriggerWhenCooldownExpires() async {
            let repository = InMemoryEventStateRepository()
            let logger = MockLogger()
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

        @Test("Evaluate records timestamp when action triggers with cooldown")
        func evaluate_recordsTimestampWhenActionTriggersWithCooldown() async {
            let repository = InMemoryEventStateRepository()
            let logger = MockLogger()
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

        @Test("Evaluate does not record timestamp when cooldown is zero")
        func evaluate_doesNotRecordTimestampWhenCooldownIsZero() async {
            let repository = InMemoryEventStateRepository()
            let logger = MockLogger()
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

    @Suite("Evaluation Result Content")
    struct EvaluationResultTests {
        @Test("Evaluate returns correct policy metadata in result")
        func evaluate_returnsCorrectPolicyMetadataInResult() async {
            let repository = InMemoryEventStateRepository()
            let logger = MockLogger()
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

        @Test("Evaluate returns accurate remaining count in reason text")
        func evaluate_returnsAccurateRemainingCountInReasonText() async {
            let repository = InMemoryEventStateRepository()
            let logger = MockLogger()
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
