//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Testing

struct SessionJourneyStepRepositoryTests {
	@Test
	func `recordStep appends to history and increments counter`() async {
		let repository = SessionJourneyStepRepository()

		await repository.recordStep(JourneyStep(name: "viewed", timestamp: 1))
		await repository.recordStep(JourneyStep(name: "viewed", timestamp: 2))

		#expect(await repository.getStepCount(stepName: "viewed") == 2)
		#expect(await repository.getStepHistory().map(\.name) == ["viewed", "viewed"])
	}

	@Test
	func `getRecentSteps returns the trailing window when history exceeds the limit`() async {
		let repository = SessionJourneyStepRepository()
		for index in 0 ..< 5 {
			await repository.recordStep(JourneyStep(name: "step_\(index)", timestamp: Int64(index)))
		}

		let recent = await repository.getRecentSteps(limit: 3)

		#expect(recent.map(\.name) == ["step_2", "step_3", "step_4"])
	}

	@Test
	func `getRecentSteps returns full history when history is shorter than the limit`() async {
		let repository = SessionJourneyStepRepository()
		await repository.recordStep(JourneyStep(name: "only", timestamp: 1))

		let recent = await repository.getRecentSteps(limit: 10)

		#expect(recent.map(\.name) == ["only"])
	}

	@Test
	func `clearHistory empties history but preserves counters`() async {
		let repository = SessionJourneyStepRepository()
		await repository.recordStep(JourneyStep(name: "viewed", timestamp: 1))
		await repository.recordStep(JourneyStep(name: "viewed", timestamp: 2))

		await repository.clearHistory()

		#expect(await repository.getStepHistory().isEmpty)
		#expect(await repository.getStepCount(stepName: "viewed") == 2)
	}

	@Test
	func `recordStep is data-race safe under concurrent fan-out`() async {
		let repository = SessionJourneyStepRepository()
		let writes = 500

		await withTaskGroup(of: Void.self) { group in
			for index in 0 ..< writes {
				group.addTask {
					await repository.recordStep(JourneyStep(name: "step", timestamp: Int64(index)))
				}
			}
		}

		#expect(await repository.getStepCount(stepName: "step") == writes)
		#expect(await repository.getStepHistory().count == writes)
	}

	@Test
	func `getRecentSteps returns empty array for negative limit instead of trapping`() async {
		// Without the guard, `suffix(_:)` triggers a stdlib precondition crash for any
		// negative `maxLength`. Guarding upstream keeps the public API total.
		let repository = SessionJourneyStepRepository()
		await repository.recordStep(JourneyStep(name: "any", timestamp: 1))

		#expect(await repository.getRecentSteps(limit: -1) == [])
		#expect(await repository.getRecentSteps(limit: -100) == [])
	}

	@Test
	func `getRecentSteps returns empty array for zero limit`() async {
		let repository = SessionJourneyStepRepository()
		await repository.recordStep(JourneyStep(name: "any", timestamp: 1))

		#expect(await repository.getRecentSteps(limit: 0) == [])
	}
}
