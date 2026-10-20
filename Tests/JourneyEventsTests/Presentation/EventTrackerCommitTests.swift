//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import JourneyEventsTesting
import Testing

struct EventTrackerCommitTests {
	private static let policyID = "deferred_policy"
	private static let step = "screen_viewed"

	@Test
	func `An uncommitted trigger fires again on the next eligible step`() async {
		let (sut, _) = makeSUT(policies: [deferredPolicy(threshold: 2)])

		await sut.recordStep(Self.step)
		let first = await sut.recordStep(Self.step)
		let second = await sut.recordStep(Self.step)

		#expect(first?.shouldTriggerAction == true)
		#expect(second?.shouldTriggerAction == true)
		#expect(second?.currentCount == 3)
	}

	@Test
	func `Committing a policy spends its cycle`() async {
		let (sut, repository) = makeSUT(policies: [deferredPolicy(threshold: 2)])
		await sut.recordStep(Self.step)
		await sut.recordStep(Self.step)

		let committed = await sut.commit(policyID: Self.policyID)
		let next = await sut.recordStep(Self.step)

		#expect(committed)
		#expect(next == nil)
		#expect(await repository.getCount(policyID: Self.policyID) == 1)
	}

	@Test
	func `Committing an unknown policy changes nothing`() async {
		let (sut, repository) = makeSUT(policies: [deferredPolicy(threshold: 1)])
		await sut.recordStep(Self.step)

		let committed = await sut.commit(policyID: "unknown")

		#expect(!committed)
		#expect(await repository.getCount(policyID: Self.policyID) == 1)
	}

	@Test
	func `Committing an on-trigger policy changes nothing`() async {
		let policy = EventPolicy.singleStep(id: Self.policyID, step: Self.step, threshold: 2)
		let (sut, repository) = makeSUT(policies: [policy])
		await sut.recordStep(Self.step)

		let committed = await sut.commit(policyID: Self.policyID)

		#expect(!committed)
		#expect(await repository.getCount(policyID: Self.policyID) == 1)
	}

	@Test
	func `Every uncommitted trigger is emitted on the stream`() async {
		let (sut, _) = makeSUT(policies: [deferredPolicy(threshold: 1)])
		let received = Task {
			var evaluations: [PolicyEvaluation] = []
			for await evaluation in sut.policyTriggers {
				evaluations.append(evaluation)
				if evaluations.count == 2 {
					break
				}
			}
			return evaluations
		}

		await sut.recordStep(Self.step)
		await sut.recordStep(Self.step)

		#expect(await received.value.map(\.currentCount) == [1, 2])
	}

	// MARK: - Helpers

	private func makeSUT(policies: [EventPolicy]) -> (EventTracker, InMemoryEventStateRepository) {
		let stateRepository = InMemoryEventStateRepository()
		let policyProvider = MockPolicyProvider(policies: policies)
		let logger = RecordingJourneyLogger()
		let sut = EventTracker(
			trackJourneyStep: TrackJourneyStep(
				journeyStepRepository: InMemoryJourneyStepRepository(),
				eventStateRepository: stateRepository,
				policyProvider: policyProvider,
				sequenceMatcher: SequenceMatcher(),
			),
			evaluateEventPolicy: EvaluateEventPolicy(
				eventStateRepository: stateRepository,
				logger: logger,
				timeProvider: MockTimeProvider(),
			),
			policyProvider: policyProvider,
			logger: logger,
		)
		return (sut, stateRepository)
	}

	private func deferredPolicy(threshold: Int) -> EventPolicy {
		.singleStep(id: Self.policyID, step: Self.step, threshold: threshold, commitMode: .deferred)
	}
}
