//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Foundation
import JourneyEventsTesting
import os

// MARK: - Mock Time Provider

/// Mutable `TimeProvider` for tests. Storage is guarded by `OSAllocatedUnfairLock`
/// so the type is `Sendable` without an `@unchecked` escape hatch.
final class MockTimeProvider: TimeProvider {
	private let storage = OSAllocatedUnfairLock<Int64>(initialState: 0)

	var currentTime: Int64 {
		get { storage.withLock { $0 } }
		set { storage.withLock { $0 = newValue } }
	}

	func currentTimeMillis() -> Int64 {
		storage.withLock { $0 }
	}

	func advance(by milliseconds: Int64) {
		storage.withLock { $0 += milliseconds }
	}
}

// MARK: - Mock Policy Provider

/// Mutable `PolicyProvider` for tests. Storage is guarded by `OSAllocatedUnfairLock`
/// so the type is `Sendable` without an `@unchecked` escape hatch.
final class MockPolicyProvider: PolicyProvider {
	private let storage: OSAllocatedUnfairLock<[EventPolicy]>

	init(policies: [EventPolicy] = []) {
		storage = OSAllocatedUnfairLock(initialState: policies)
	}

	var policies: [EventPolicy] {
		get { storage.withLock { $0 } }
		set { storage.withLock { $0 = newValue } }
	}

	func getActivePolicies() -> [EventPolicy] {
		storage.withLock { $0 }
	}
}

// MARK: - Test Factory

struct TestFactory {
	static func createStep(_ name: String, timestamp: Int64 = 1000) -> JourneyStep {
		JourneyStep(name: name, timestamp: timestamp)
	}

	static func createPattern(_ steps: String..., strict: Bool = true) -> JourneyPattern {
		JourneyPattern(steps: steps, strictSequence: strict)
	}

	static func createPolicy(
		id: String,
		actionKey: String,
		steps: [String],
		threshold: Int = 1,
		cooldown: Int = 0,
		persist: Bool = true,
		strict: Bool = true,
	) -> EventPolicy {
		EventPolicy(
			id: id,
			actionKey: actionKey,
			pattern: JourneyPattern(steps: steps, strictSequence: strict),
			threshold: threshold,
			cooldownMinutes: cooldown,
			persistAcrossSessions: persist,
		)
	}
}
