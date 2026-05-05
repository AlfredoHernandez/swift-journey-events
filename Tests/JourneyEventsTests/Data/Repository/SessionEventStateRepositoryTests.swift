//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Testing

struct SessionEventStateRepositoryTests {
	@Test
	func `getCount returns zero for an unknown policy ID`() async {
		let repository = SessionEventStateRepository()

		let count = await repository.getCount(policyID: "unknown")

		#expect(count == 0)
	}

	@Test
	func `incrementCount increases the per-policy counter`() async {
		let repository = SessionEventStateRepository()

		await repository.incrementCount(policyID: "p1")
		await repository.incrementCount(policyID: "p1")
		await repository.incrementCount(policyID: "p1")

		#expect(await repository.getCount(policyID: "p1") == 3)
	}

	@Test
	func `resetCount returns the counter to zero`() async {
		let repository = SessionEventStateRepository()
		await repository.incrementCount(policyID: "p1")
		await repository.incrementCount(policyID: "p1")

		await repository.resetCount(policyID: "p1")

		#expect(await repository.getCount(policyID: "p1") == 0)
	}

	@Test
	func `counts are isolated per policy ID`() async {
		let repository = SessionEventStateRepository()

		await repository.incrementCount(policyID: "p1")
		await repository.incrementCount(policyID: "p1")
		await repository.incrementCount(policyID: "p2")

		#expect(await repository.getCount(policyID: "p1") == 2)
		#expect(await repository.getCount(policyID: "p2") == 1)
	}

	@Test
	func `setLastActionTriggeredTimestamp round-trips through getter`() async {
		let repository = SessionEventStateRepository()

		await repository.setLastActionTriggeredTimestamp(policyID: "p1", timestamp: 1_700_000_000)

		#expect(await repository.getLastActionTriggeredTimestamp(policyID: "p1") == 1_700_000_000)
	}

	@Test
	func `setLastCountedStepTimestamp round-trips through getter`() async {
		let repository = SessionEventStateRepository()

		await repository.setLastCountedStepTimestamp(policyID: "p1", timestamp: 42)

		#expect(await repository.getLastCountedStepTimestamp(policyID: "p1") == 42)
	}

	@Test
	func `getLastActionTriggeredTimestamp returns nil when never set`() async {
		let repository = SessionEventStateRepository()

		#expect(await repository.getLastActionTriggeredTimestamp(policyID: "p1") == nil)
	}

	@Test
	func `getLastCountedStepTimestamp returns nil when never set`() async {
		let repository = SessionEventStateRepository()

		#expect(await repository.getLastCountedStepTimestamp(policyID: "p1") == nil)
	}

	/// Concurrent stress test that pins the actor's data-race safety.
	///
	/// 1000 increments are dispatched in parallel via a `TaskGroup`. With actor isolation the
	/// final count must be exactly 1000. A regression to a non-isolated shared-state design
	/// would produce lost updates and an under-count.
	@Test
	func `incrementCount is data-race safe under concurrent fan-out`() async {
		let repository = SessionEventStateRepository()
		let increments = 1000

		await withTaskGroup(of: Void.self) { group in
			for _ in 0 ..< increments {
				group.addTask {
					await repository.incrementCount(policyID: "race")
				}
			}
		}

		#expect(await repository.getCount(policyID: "race") == increments)
	}
}
