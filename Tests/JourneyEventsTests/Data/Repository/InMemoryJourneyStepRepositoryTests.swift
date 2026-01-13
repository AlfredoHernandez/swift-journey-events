//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Testing

@Suite("InMemoryJourneyStepRepository Tests")
struct InMemoryJourneyStepRepositoryTests {
    @Test("RecordStep records step and increments count")
    func recordStep_recordsStepAndIncrementsCount() async {
        let repository = InMemoryJourneyStepRepository()
        let step = JourneyStep(name: "test_step", timestamp: 1000)

        await repository.recordStep(step)

        let count = await repository.getStepCount(stepName: "test_step")
        #expect(count == 1)
    }

    @Test("RecordStep records multiple steps and maintains separate counts")
    func recordStep_recordsMultipleStepsAndMaintainsSeparateCounts() async {
        let repository = InMemoryJourneyStepRepository()

        await repository.recordStep(JourneyStep(name: "step_a", timestamp: 1000))
        await repository.recordStep(JourneyStep(name: "step_b", timestamp: 2000))
        await repository.recordStep(JourneyStep(name: "step_a", timestamp: 3000))

        let countA = await repository.getStepCount(stepName: "step_a")
        let countB = await repository.getStepCount(stepName: "step_b")

        #expect(countA == 2)
        #expect(countB == 1)
    }

    @Test("GetStepCount returns zero for unknown step name")
    func getStepCount_returnsZeroForUnknownStepName() async {
        let repository = InMemoryJourneyStepRepository()

        let count = await repository.getStepCount(stepName: "unknown_step")

        #expect(count == 0)
    }

    @Test("GetStepHistory returns steps in chronological order")
    func getStepHistory_returnsStepsInChronologicalOrder() async {
        let repository = InMemoryJourneyStepRepository()

        let step1 = JourneyStep(name: "A", timestamp: 1000)
        let step2 = JourneyStep(name: "B", timestamp: 2000)
        let step3 = JourneyStep(name: "C", timestamp: 3000)

        await repository.recordStep(step1)
        await repository.recordStep(step2)
        await repository.recordStep(step3)

        let history = await repository.getStepHistory()

        #expect(history.count == 3)
        #expect(history[0] == step1)
        #expect(history[1] == step2)
        #expect(history[2] == step3)
    }

    @Test("GetRecentSteps returns limited most recent steps")
    func getRecentSteps_returnsLimitedMostRecentSteps() async {
        let repository = InMemoryJourneyStepRepository()

        await repository.recordStep(JourneyStep(name: "A", timestamp: 1000))
        await repository.recordStep(JourneyStep(name: "B", timestamp: 2000))
        await repository.recordStep(JourneyStep(name: "C", timestamp: 3000))
        await repository.recordStep(JourneyStep(name: "D", timestamp: 4000))
        await repository.recordStep(JourneyStep(name: "E", timestamp: 5000))

        let recent = await repository.getRecentSteps(limit: 3)

        #expect(recent.count == 3)
        #expect(recent[0].name == "C")
        #expect(recent[1].name == "D")
        #expect(recent[2].name == "E")
    }

    @Test("GetRecentSteps returns all steps when limit exceeds history size")
    func getRecentSteps_returnsAllStepsWhenLimitExceedsHistorySize() async {
        let repository = InMemoryJourneyStepRepository()

        await repository.recordStep(JourneyStep(name: "A", timestamp: 1000))
        await repository.recordStep(JourneyStep(name: "B", timestamp: 2000))

        let recent = await repository.getRecentSteps(limit: 10)

        #expect(recent.count == 2)
        #expect(recent[0].name == "A")
        #expect(recent[1].name == "B")
    }

    @Test("ClearHistory clears history but preserves step counts")
    func clearHistory_clearsHistoryButPreservesStepCounts() async {
        let repository = InMemoryJourneyStepRepository()

        await repository.recordStep(JourneyStep(name: "test", timestamp: 1000))
        await repository.recordStep(JourneyStep(name: "test", timestamp: 2000))

        let countBefore = await repository.getStepCount(stepName: "test")
        #expect(countBefore == 2)

        await repository.clearHistory()

        let history = await repository.getStepHistory()
        let countAfter = await repository.getStepCount(stepName: "test")

        #expect(history.isEmpty)
        #expect(countAfter == 2) // Count preserved
    }

    @Test("Repository handles empty state correctly")
    func repository_handlesEmptyStateCorrectly() async {
        let repository = InMemoryJourneyStepRepository()

        let history = await repository.getStepHistory()
        let recent = await repository.getRecentSteps(limit: 5)
        let count = await repository.getStepCount(stepName: "any")

        #expect(history.isEmpty)
        #expect(recent.isEmpty)
        #expect(count == 0)
    }
}
