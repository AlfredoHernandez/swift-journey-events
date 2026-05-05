//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Foundation
import Testing

struct UserDefaultsEventStateRepositoryTests {
	@Test func `incrementCount is atomic across distinct repository instances sharing UserDefaults`() async {
		// Two distinct repository instances pointing at the same UserDefaults would
		// race their read-modify-write without a process-wide lock: each could read
		// the same `current` and then write `current + 1`, dropping the other's
		// increment. The static lock makes the operation linearizable across
		// instances. The repos themselves are Sendable so they cross task boundaries
		// safely; the underlying UserDefaults reference never leaves the test task.
		let suite = makeIsolatedSuite()
		let policyID = "race_test"
		let increments = 200
		let repositories = (0 ..< increments).map { _ in
			UserDefaultsEventStateRepository(userDefaults: suite)
		}

		await withTaskGroup(of: Void.self) { group in
			for repository in repositories {
				group.addTask {
					await repository.incrementCount(policyID: policyID)
				}
			}
		}

		let observer = UserDefaultsEventStateRepository(userDefaults: suite)
		#expect(await observer.getCount(policyID: policyID) == increments)
	}

	@Test func `incrementCount is atomic for many concurrent calls on a single instance`() async {
		let suite = makeIsolatedSuite()
		let repository = UserDefaultsEventStateRepository(userDefaults: suite)
		let policyID = "single_instance"
		let increments = 200

		await withTaskGroup(of: Void.self) { group in
			for _ in 0 ..< increments {
				group.addTask {
					await repository.incrementCount(policyID: policyID)
				}
			}
		}

		#expect(await repository.getCount(policyID: policyID) == increments)
	}

	@Test func `getCount returns zero before any increments`() async {
		let repository = UserDefaultsEventStateRepository(userDefaults: makeIsolatedSuite())

		#expect(await repository.getCount(policyID: "unseen") == 0)
	}

	@Test func `resetCount clears the stored value`() async {
		let suite = makeIsolatedSuite()
		let repository = UserDefaultsEventStateRepository(userDefaults: suite)
		await repository.incrementCount(policyID: "clear_me")
		await repository.incrementCount(policyID: "clear_me")

		await repository.resetCount(policyID: "clear_me")

		#expect(await repository.getCount(policyID: "clear_me") == 0)
	}

	@Test func `timestamps round-trip through set and get`() async {
		let suite = makeIsolatedSuite()
		let repository = UserDefaultsEventStateRepository(userDefaults: suite)

		await repository.setLastActionTriggeredTimestamp(policyID: "p", timestamp: 1_700_000_000)
		await repository.setLastCountedStepTimestamp(policyID: "p", timestamp: 1_800_000_000)

		#expect(await repository.getLastActionTriggeredTimestamp(policyID: "p") == 1_700_000_000)
		#expect(await repository.getLastCountedStepTimestamp(policyID: "p") == 1_800_000_000)
	}

	// MARK: - Helpers

	/// Builds a UserDefaults suite scoped to this test invocation. Removing the
	/// persistent domain on creation guarantees no leftover state from previous runs.
	private func makeIsolatedSuite() -> UserDefaults {
		let name = "UserDefaultsEventStateRepositoryTests-\(UUID().uuidString)"
		let suite = UserDefaults(suiteName: name) ?? .standard
		suite.removePersistentDomain(forName: name)
		return suite
	}
}
