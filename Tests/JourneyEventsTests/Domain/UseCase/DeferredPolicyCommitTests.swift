//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import JourneyEventsTesting
import Testing

struct DeferredPolicyCommitTests {
	private static let policyID = "deferred_policy"
	private static let millisPerMinute: Int64 = 60000

	@Test
	func `Policies consume their cycle on evaluation by default`() {
		let policy = EventPolicy(id: "policy", actionKey: "action", pattern: JourneyPattern(steps: ["step"]), threshold: 1)

		#expect(policy.commitMode == .onTrigger)
	}

	@Test
	func `A reached threshold is not consumed until committed`() async {
		let (sut, repository, logger, _) = makeSUT()
		await increment(times: 3, repository)

		let evaluation = await sut(deferredPolicy(threshold: 3, cooldown: 15))

		#expect(evaluation.shouldTriggerAction)
		#expect(await repository.getCount(policyID: Self.policyID) == 3)
		#expect(await repository.getLastActionTriggeredTimestamp(policyID: Self.policyID) == nil)
		#expect(logger.resets.isEmpty)
	}

	@Test
	func `An uncommitted evaluation triggers again on the next evaluation`() async {
		let (sut, repository, _, timeProvider) = makeSUT()
		let policy = deferredPolicy(threshold: 2, cooldown: 15)
		await increment(times: 2, repository)

		let first = await sut(policy)
		timeProvider.advance(by: Self.millisPerMinute)
		await repository.incrementCount(policyID: Self.policyID)
		let second = await sut(policy)

		#expect(first.shouldTriggerAction)
		#expect(second.shouldTriggerAction)
		#expect(second.currentCount == 3)
	}

	@Test
	func `Commit resets the counter and logs the reset`() async {
		let (sut, repository, logger, _) = makeSUT()
		let policy = deferredPolicy(threshold: 2)
		await increment(times: 2, repository)
		_ = await sut(policy)

		await sut.commit(policy)

		#expect(await repository.getCount(policyID: Self.policyID) == 0)
		#expect(logger.resets == [Self.policyID])
	}

	@Test
	func `Commit starts the cooldown`() async {
		let (sut, repository, _, timeProvider) = makeSUT()
		let policy = deferredPolicy(threshold: 1, cooldown: 15)
		timeProvider.currentTime = 10000
		await repository.incrementCount(policyID: Self.policyID)
		_ = await sut(policy)

		await sut.commit(policy)
		await repository.incrementCount(policyID: Self.policyID)
		timeProvider.advance(by: 14 * Self.millisPerMinute)
		let insideCooldown = await sut(policy)
		timeProvider.advance(by: Self.millisPerMinute)
		let afterCooldown = await sut(policy)

		#expect(await repository.getLastActionTriggeredTimestamp(policyID: Self.policyID) == 10000)
		#expect(!insideCooldown.shouldTriggerAction)
		#expect(insideCooldown.reason.contains("Cooldown active"))
		#expect(afterCooldown.shouldTriggerAction)
	}

	@Test
	func `Commit does not start a cooldown for a policy without one`() async {
		let (sut, repository, _, _) = makeSUT()

		await sut.commit(deferredPolicy(threshold: 1))

		#expect(await repository.getLastActionTriggeredTimestamp(policyID: Self.policyID) == nil)
	}

	@Test
	func `An on-trigger policy still consumes its cycle on evaluation`() async {
		let (sut, repository, logger, _) = makeSUT()
		let policy = EventPolicy.singleStep(id: Self.policyID, step: "step", threshold: 2)
		await increment(times: 2, repository)

		let evaluation = await sut(policy)

		#expect(evaluation.shouldTriggerAction)
		#expect(await repository.getCount(policyID: Self.policyID) == 0)
		#expect(logger.resets == [Self.policyID])
	}

	// MARK: - Helpers

	private func makeSUT() -> (EvaluateEventPolicy, InMemoryEventStateRepository, RecordingJourneyLogger, MockTimeProvider) {
		let repository = InMemoryEventStateRepository()
		let logger = RecordingJourneyLogger()
		let timeProvider = MockTimeProvider()
		let sut = EvaluateEventPolicy(eventStateRepository: repository, logger: logger, timeProvider: timeProvider)
		return (sut, repository, logger, timeProvider)
	}

	private func deferredPolicy(threshold: Int, cooldown: Int = 0) -> EventPolicy {
		.singleStep(id: Self.policyID, step: "step", threshold: threshold, cooldownMinutes: cooldown, commitMode: .deferred)
	}

	private func increment(times: Int, _ repository: InMemoryEventStateRepository) async {
		for _ in 0 ..< times {
			await repository.incrementCount(policyID: Self.policyID)
		}
	}
}
