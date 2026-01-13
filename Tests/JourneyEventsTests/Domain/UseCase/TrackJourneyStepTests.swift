//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Testing

@Suite("TrackJourneyStep Tests")
struct TrackJourneyStepTests {
    // MARK: - Single-Step Pattern Tests

    @Suite("Single-Step Pattern Tracking")
    struct SingleStepPatternTests {
        @Test("Track records step in journey repository")
        func track_recordsStepInJourneyRepository() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policyProvider = MockPolicyProvider(policies: [])
            let matcher = SequenceMatcher()

            let tracker = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: matcher,
            )

            let step = JourneyStep(name: "test_step", timestamp: 1000)
            await tracker(step)

            let history = await journeyRepo.getStepHistory()
            #expect(history.count == 1)
            #expect(history[0] == step)
        }

        @Test("Track increments counter when single-step pattern matches")
        func track_incrementsCounterWhenSingleStepPatternMatches() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "test_policy",
                actionKey: "test_action",
                steps: ["article_viewed"],
                threshold: 5,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let matcher = SequenceMatcher()

            let tracker = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: matcher,
            )

            await tracker(JourneyStep(name: "article_viewed", timestamp: 1000))
            await tracker(JourneyStep(name: "article_viewed", timestamp: 2000))

            let count = await stateRepo.getCount(policyID: "test_policy")
            #expect(count == 2)
        }

        @Test("Track increments counter only for matching step name")
        func track_incrementsCounterOnlyForMatchingStepName() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "test_policy",
                actionKey: "test_action",
                steps: ["specific_step"],
                threshold: 3,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let matcher = SequenceMatcher()

            let tracker = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: matcher,
            )

            await tracker(JourneyStep(name: "other_step", timestamp: 1000))
            await tracker(JourneyStep(name: "specific_step", timestamp: 2000))
            await tracker(JourneyStep(name: "other_step", timestamp: 3000))
            await tracker(JourneyStep(name: "specific_step", timestamp: 4000))

            let count = await stateRepo.getCount(policyID: "test_policy")
            #expect(count == 2)
        }

        @Test("Track increments counters for multiple policies on same step")
        func track_incrementsCountersForMultiplePoliciesOnSameStep() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy1 = TestFactory.createPolicy(
                id: "policy_1",
                actionKey: "action_1",
                steps: ["test_step"],
                threshold: 3,
            )
            let policy2 = TestFactory.createPolicy(
                id: "policy_2",
                actionKey: "action_2",
                steps: ["test_step"],
                threshold: 5,
            )
            let policyProvider = MockPolicyProvider(policies: [policy1, policy2])
            let matcher = SequenceMatcher()

            let tracker = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: matcher,
            )

            await tracker(JourneyStep(name: "test_step", timestamp: 1000))

            let count1 = await stateRepo.getCount(policyID: "policy_1")
            let count2 = await stateRepo.getCount(policyID: "policy_2")

            #expect(count1 == 1)
            #expect(count2 == 1)
        }
    }

    // MARK: - Multi-Step Pattern Tests

    @Suite("Multi-Step Pattern Tracking")
    struct MultiStepPatternTests {
        @Test("Track increments counter when strict sequence completes")
        func track_incrementsCounterWhenStrictSequenceCompletes() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "onboarding_policy",
                actionKey: "show_celebration",
                steps: ["welcome", "profile", "home"],
                threshold: 1,
                strict: true,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let matcher = SequenceMatcher()

            let tracker = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: matcher,
            )

            await tracker(JourneyStep(name: "welcome", timestamp: 1000))
            await tracker(JourneyStep(name: "profile", timestamp: 2000))

            let countBefore = await stateRepo.getCount(policyID: "onboarding_policy")
            #expect(countBefore == 0)

            await tracker(JourneyStep(name: "home", timestamp: 3000))

            let countAfter = await stateRepo.getCount(policyID: "onboarding_policy")
            #expect(countAfter == 1)
        }

        @Test("Track does not increment counter when strict sequence has intermediate step")
        func track_doesNotIncrementCounterWhenStrictSequenceHasIntermediateStep() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "strict_policy",
                actionKey: "action",
                steps: ["A", "B", "C"],
                threshold: 1,
                strict: true,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let matcher = SequenceMatcher()

            let tracker = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: matcher,
            )

            await tracker(JourneyStep(name: "A", timestamp: 1000))
            await tracker(JourneyStep(name: "X", timestamp: 2000))
            await tracker(JourneyStep(name: "B", timestamp: 3000))
            await tracker(JourneyStep(name: "C", timestamp: 4000))

            let count = await stateRepo.getCount(policyID: "strict_policy")
            #expect(count == 0)
        }

        @Test("Track increments counter when loose sequence completes")
        func track_incrementsCounterWhenLooseSequenceCompletes() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "loose_policy",
                actionKey: "action",
                steps: ["search", "results", "detail"],
                threshold: 1,
                strict: false,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let matcher = SequenceMatcher()

            let tracker = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: matcher,
            )

            await tracker(JourneyStep(name: "search", timestamp: 1000))
            await tracker(JourneyStep(name: "filter", timestamp: 2000))
            await tracker(JourneyStep(name: "results", timestamp: 3000))
            await tracker(JourneyStep(name: "scroll", timestamp: 4000))
            await tracker(JourneyStep(name: "detail", timestamp: 5000))

            let count = await stateRepo.getCount(policyID: "loose_policy")
            #expect(count == 1)
        }

        @Test("Track prevents double-counting same sequence completion")
        func track_preventsDoubleCountingSameSequenceCompletion() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "sequence_policy",
                actionKey: "action",
                steps: ["A", "B", "C"],
                threshold: 2,
                strict: true,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let matcher = SequenceMatcher()

            let tracker = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: matcher,
            )

            // Complete first sequence
            await tracker(JourneyStep(name: "A", timestamp: 1000))
            await tracker(JourneyStep(name: "B", timestamp: 2000))
            await tracker(JourneyStep(name: "C", timestamp: 3000))

            let countAfterFirst = await stateRepo.getCount(policyID: "sequence_policy")
            #expect(countAfterFirst == 1)

            // Trigger last step again without completing new sequence
            await tracker(JourneyStep(name: "C", timestamp: 4000))

            let countAfterRetrigger = await stateRepo.getCount(policyID: "sequence_policy")
            #expect(countAfterRetrigger == 1) // Should still be 1
        }

        @Test("Track counts multiple distinct sequence completions after history clear")
        func track_countsMultipleDistinctSequenceCompletionsAfterHistoryClear() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "sequence_policy",
                actionKey: "action",
                steps: ["A", "B", "C"],
                threshold: 2,
                strict: true,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let matcher = SequenceMatcher()

            let tracker = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: matcher,
            )

            // First completion
            await tracker(JourneyStep(name: "A", timestamp: 1000))
            await tracker(JourneyStep(name: "B", timestamp: 2000))
            await tracker(JourneyStep(name: "C", timestamp: 3000))

            let countAfterFirst = await stateRepo.getCount(policyID: "sequence_policy")
            #expect(countAfterFirst == 1)

            // Clear history to allow clean second sequence
            await journeyRepo.clearHistory()

            // Second completion after clearing
            await tracker(JourneyStep(name: "A", timestamp: 4000))
            await tracker(JourneyStep(name: "B", timestamp: 5000))
            await tracker(JourneyStep(name: "C", timestamp: 6000))

            let countAfterSecond = await stateRepo.getCount(policyID: "sequence_policy")
            #expect(countAfterSecond == 2)
        }
    }

    // MARK: - Edge Cases

    @Suite("Edge Cases")
    struct EdgeCaseTests {
        @Test("Track records step but does not increment when no policies match")
        func track_recordsStepButDoesNotIncrementWhenNoPoliciesMatch() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policy = TestFactory.createPolicy(
                id: "policy",
                actionKey: "action",
                steps: ["specific_step"],
                threshold: 1,
            )
            let policyProvider = MockPolicyProvider(policies: [policy])
            let matcher = SequenceMatcher()

            let tracker = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: matcher,
            )

            await tracker(JourneyStep(name: "unrelated_step", timestamp: 1000))

            let history = await journeyRepo.getStepHistory()
            #expect(history.count == 1) // Step still recorded

            let count = await stateRepo.getCount(policyID: "policy")
            #expect(count == 0) // Counter not incremented
        }

        @Test("Track records step when policy list is empty")
        func track_recordsStepWhenPolicyListIsEmpty() async {
            let journeyRepo = InMemoryJourneyStepRepository()
            let stateRepo = InMemoryEventStateRepository()
            let policyProvider = MockPolicyProvider(policies: [])
            let matcher = SequenceMatcher()

            let tracker = TrackJourneyStep(
                journeyStepRepository: journeyRepo,
                eventStateRepository: stateRepo,
                policyProvider: policyProvider,
                sequenceMatcher: matcher,
            )

            await tracker(JourneyStep(name: "test_step", timestamp: 1000))

            let history = await journeyRepo.getStepHistory()
            #expect(history.count == 1)
        }
    }
}
