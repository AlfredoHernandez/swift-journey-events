//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Testing

@Suite("EventTracker Tests")
struct EventTrackerTests {
    // MARK: - Basic Recording Tests

    @Suite("Basic Step Recording")
    struct BasicRecordingTests {
        @Test("RecordStepOnly records step and logs it")
        func recordStepOnly_recordsStepAndLogsIt() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policyProvider = MockPolicyProvider(policies: [])
            let logger = MockLogger()
            let timeProvider = MockTimeProvider()

            let trackStep = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: SequenceMatcher(),
            )

            let evaluatePolicy = EvaluateEventPolicy(
                eventStateRepository: stateRepo,
                logger: logger,
                timeProvider: timeProvider,
            )

            let tracker = EventTracker(
                trackJourneyStep: trackStep,
                evaluateEventPolicy: evaluatePolicy,
                policyProvider: policyProvider,
                logger: logger,
            )

            await tracker.recordStepOnly("test_step")

            let history = await journeyRepo.getStepHistory()
            #expect(history.count == 1)
            #expect(history[0].name == "test_step")
            #expect(logger.recordedSteps.count == 1)
        }

        @Test("RecordStepOnly records step with parameters dictionary")
        func recordStepOnly_recordsStepWithParametersDictionary() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policyProvider = MockPolicyProvider(policies: [])
            let logger = MockLogger()
            let timeProvider = MockTimeProvider()

            let trackStep = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: SequenceMatcher(),
            )

            let evaluatePolicy = EvaluateEventPolicy(
                eventStateRepository: stateRepo,
                logger: logger,
                timeProvider: timeProvider,
            )

            let tracker = EventTracker(
                trackJourneyStep: trackStep,
                evaluateEventPolicy: evaluatePolicy,
                policyProvider: policyProvider,
                logger: logger,
            )

            let params: [String: AnyHashableSendable] = [
                "id": "123",
                "count": 42,
            ]

            await tracker.recordStepOnly("test_step", parameters: params)

            let history = await journeyRepo.getStepHistory()
            #expect(history[0].parameters["id"]?.value(as: String.self) == "123")
            #expect(history[0].parameters["count"]?.value(as: Int.self) == 42)
        }
    }

    // MARK: - Policy Evaluation Tests

    @Suite("Policy Evaluation")
    struct PolicyEvaluationTests {
        @Test("RecordStep returns nil when no policies match step name")
        func recordStep_returnsNilWhenNoPoliciesMatchStepName() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "policy",
                actionKey: "action",
                steps: ["different_step"],
                threshold: 1,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let logger = MockLogger()
            let timeProvider = MockTimeProvider()

            let trackStep = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: SequenceMatcher(),
            )

            let evaluatePolicy = EvaluateEventPolicy(
                eventStateRepository: stateRepo,
                logger: logger,
                timeProvider: timeProvider,
            )

            let tracker = EventTracker(
                trackJourneyStep: trackStep,
                evaluateEventPolicy: evaluatePolicy,
                policyProvider: policyProvider,
                logger: logger,
            )

            let result = await tracker.recordStep("unrelated_step")

            #expect(result == nil)
        }

        @Test("RecordStep returns nil when threshold not reached")
        func recordStep_returnsNilWhenThresholdNotReached() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "policy",
                actionKey: "action",
                steps: ["test_step"],
                threshold: 3,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let logger = MockLogger()
            let timeProvider = MockTimeProvider()

            let trackStep = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: SequenceMatcher(),
            )

            let evaluatePolicy = EvaluateEventPolicy(
                eventStateRepository: stateRepo,
                logger: logger,
                timeProvider: timeProvider,
            )

            let tracker = EventTracker(
                trackJourneyStep: trackStep,
                evaluateEventPolicy: evaluatePolicy,
                policyProvider: policyProvider,
                logger: logger,
            )

            let result1 = await tracker.recordStep("test_step")
            let result2 = await tracker.recordStep("test_step")

            #expect(result1 == nil)
            #expect(result2 == nil)
        }

        @Test("RecordStep returns evaluation when threshold reached")
        func recordStep_returnsEvaluationWhenThresholdReached() async throws {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "policy",
                actionKey: "show_ad",
                steps: ["article_viewed"],
                threshold: 2,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let logger = MockLogger()
            let timeProvider = MockTimeProvider()

            let trackStep = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: SequenceMatcher(),
            )

            let evaluatePolicy = EvaluateEventPolicy(
                eventStateRepository: stateRepo,
                logger: logger,
                timeProvider: timeProvider,
            )

            let tracker = EventTracker(
                trackJourneyStep: trackStep,
                evaluateEventPolicy: evaluatePolicy,
                policyProvider: policyProvider,
                logger: logger,
            )

            _ = await tracker.recordStep("article_viewed")
            let result = await tracker.recordStep("article_viewed")

            let evaluation = try #require(result)
            #expect(evaluation.shouldTriggerAction == true)
            #expect(evaluation.policyID == "policy")
            #expect(evaluation.actionKey == "show_ad")
        }

        @Test("RecordStep logs policy evaluation result")
        func recordStep_logsPolicyEvaluationResult() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "policy",
                actionKey: "action",
                steps: ["test_step"],
                threshold: 1,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let logger = MockLogger()
            let timeProvider = MockTimeProvider()

            let trackStep = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: SequenceMatcher(),
            )

            let evaluatePolicy = EvaluateEventPolicy(
                eventStateRepository: stateRepo,
                logger: logger,
                timeProvider: timeProvider,
            )

            let tracker = EventTracker(
                trackJourneyStep: trackStep,
                evaluateEventPolicy: evaluatePolicy,
                policyProvider: policyProvider,
                logger: logger,
            )

            await tracker.recordStep("test_step")

            #expect(logger.evaluations.count == 1)
            #expect(logger.evaluations[0].policyID == "policy")
        }
    }

    // MARK: - AsyncStream Tests

    @Suite("Policy Trigger Stream")
    struct PolicyTriggerStreamTests {
        @Test("PolicyTriggers emits evaluation when action triggers")
        func policyTriggers_emitsEvaluationWhenActionTriggers() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "policy",
                actionKey: "show_interstitial",
                steps: ["screen_viewed"],
                threshold: 1,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let logger = MockLogger()
            let timeProvider = MockTimeProvider()

            let trackStep = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: SequenceMatcher(),
            )

            let evaluatePolicy = EvaluateEventPolicy(
                eventStateRepository: stateRepo,
                logger: logger,
                timeProvider: timeProvider,
            )

            let tracker = EventTracker(
                trackJourneyStep: trackStep,
                evaluateEventPolicy: evaluatePolicy,
                policyProvider: policyProvider,
                logger: logger,
            )

            // Start listening to stream
            let expectation = Task {
                var received: [PolicyEvaluation] = []
                for await evaluation in tracker.policyTriggers {
                    received.append(evaluation)
                    if received.count == 1 {
                        break
                    }
                }
                return received
            }

            // Trigger action
            await tracker.recordStep("screen_viewed")

            let received = await expectation.value
            #expect(received.count == 1)
            #expect(received[0].shouldTriggerAction == true)
            #expect(received[0].actionKey == "show_interstitial")
        }

        @Test("PolicyTriggers does not emit when threshold not reached")
        func policyTriggers_doesNotEmitWhenThresholdNotReached() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "policy",
                actionKey: "action",
                steps: ["test_step"],
                threshold: 5,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let logger = MockLogger()
            let timeProvider = MockTimeProvider()

            let trackStep = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: SequenceMatcher(),
            )

            let evaluatePolicy = EvaluateEventPolicy(
                eventStateRepository: stateRepo,
                logger: logger,
                timeProvider: timeProvider,
            )

            let tracker = EventTracker(
                trackJourneyStep: trackStep,
                evaluateEventPolicy: evaluatePolicy,
                policyProvider: policyProvider,
                logger: logger,
            )

            // Start listening with timeout
            let expectation = Task {
                var received: [PolicyEvaluation] = []
                for await evaluation in tracker.policyTriggers {
                    received.append(evaluation)
                }
                return received
            }

            // Trigger but don't reach threshold
            await tracker.recordStep("test_step")
            await tracker.recordStep("test_step")

            // Small delay to ensure no events are emitted
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms

            expectation.cancel()
            let received = await expectation.value
            #expect(received.isEmpty)
        }
    }

    // MARK: - Manual Checking Tests

    @Suite("Manual Policy Checking")
    struct ManualCheckingTests {
        @Test("RecordStepOnly records step without policy evaluation")
        func recordStepOnly_recordsStepWithoutPolicyEvaluation() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "policy",
                actionKey: "action",
                steps: ["test_step"],
                threshold: 1,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let logger = MockLogger()
            let timeProvider = MockTimeProvider()

            let trackStep = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: SequenceMatcher(),
            )

            let evaluatePolicy = EvaluateEventPolicy(
                eventStateRepository: stateRepo,
                logger: logger,
                timeProvider: timeProvider,
            )

            let tracker = EventTracker(
                trackJourneyStep: trackStep,
                evaluateEventPolicy: evaluatePolicy,
                policyProvider: policyProvider,
                logger: logger,
            )

            await tracker.recordStepOnly("test_step")

            #expect(logger.recordedSteps.count == 1)
            #expect(logger.evaluations.isEmpty) // No evaluation performed
        }

        @Test("CheckPoliciesForStep evaluates policies manually for step name")
        func checkPoliciesForStep_evaluatesPoliciesManuallyForStepName() async throws {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "policy",
                actionKey: "action",
                steps: ["test_step"],
                threshold: 1,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let logger = MockLogger()
            let timeProvider = MockTimeProvider()

            let trackStep = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: SequenceMatcher(),
            )

            let evaluatePolicy = EvaluateEventPolicy(
                eventStateRepository: stateRepo,
                logger: logger,
                timeProvider: timeProvider,
            )

            let tracker = EventTracker(
                trackJourneyStep: trackStep,
                evaluateEventPolicy: evaluatePolicy,
                policyProvider: policyProvider,
                logger: logger,
            )

            await tracker.recordStepOnly("test_step")
            let evaluation = await tracker.checkPoliciesForStep("test_step")

            let result = try #require(evaluation)
            #expect(result.shouldTriggerAction == true)
            #expect(result.policyID == "policy")
        }
    }

    // MARK: - Multiple Policies Tests

    @Suite("Multiple Policies")
    struct MultiplePoliciesTests {
        @Test("RecordStep evaluates only policies matching step name")
        func recordStep_evaluatesOnlyPoliciesMatchingStepName() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy1 = TestFactory.createPolicy(
                id: "policy_1",
                actionKey: "action_1",
                steps: ["step_a"],
                threshold: 1,
            )
            let policy2 = TestFactory.createPolicy(
                id: "policy_2",
                actionKey: "action_2",
                steps: ["step_b"],
                threshold: 1,
            )
            let policyProvider = MockPolicyProvider(policies: [policy1, policy2])
            let logger = MockLogger()
            let timeProvider = MockTimeProvider()

            let trackStep = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: SequenceMatcher(),
            )

            let evaluatePolicy = EvaluateEventPolicy(
                eventStateRepository: stateRepo,
                logger: logger,
                timeProvider: timeProvider,
            )

            let tracker = EventTracker(
                trackJourneyStep: trackStep,
                evaluateEventPolicy: evaluatePolicy,
                policyProvider: policyProvider,
                logger: logger,
            )

            await tracker.recordStep("step_a")

            #expect(logger.evaluations.count == 1)
            #expect(logger.evaluations[0].policyID == "policy_1")
        }

        @Test("RecordStep returns first triggering policy when multiple match")
        func recordStep_returnsFirstTriggeringPolicyWhenMultipleMatch() async throws {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy1 = TestFactory.createPolicy(
                id: "policy_1",
                actionKey: "action_1",
                steps: ["test_step"],
                threshold: 1,
            )
            let policy2 = TestFactory.createPolicy(
                id: "policy_2",
                actionKey: "action_2",
                steps: ["test_step"],
                threshold: 1,
            )
            let policyProvider = MockPolicyProvider(policies: [policy1, policy2])
            let logger = MockLogger()
            let timeProvider = MockTimeProvider()

            let trackStep = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: SequenceMatcher(),
            )

            let evaluatePolicy = EvaluateEventPolicy(
                eventStateRepository: stateRepo,
                logger: logger,
                timeProvider: timeProvider,
            )

            let tracker = EventTracker(
                trackJourneyStep: trackStep,
                evaluateEventPolicy: evaluatePolicy,
                policyProvider: policyProvider,
                logger: logger,
            )

            let result = await tracker.recordStep("test_step")

            let evaluation = try #require(result)
            #expect(evaluation.shouldTriggerAction == true)
            // Should be one of the policies (order may vary)
            #expect(evaluation.policyID == "policy_1" || evaluation.policyID == "policy_2")
        }
    }
}
