//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Foundation
import JourneyEventsTesting

// MARK: - Mock Time Provider

final class MockTimeProvider: TimeProvider, @unchecked Sendable {
	private var _currentTime: Int64 = 0
	private let lock = NSLock()

	var currentTime: Int64 {
		get {
			lock.lock()
			defer { lock.unlock() }
			return _currentTime
		}
		set {
			lock.lock()
			defer { lock.unlock() }
			_currentTime = newValue
		}
	}

	func currentTimeMillis() -> Int64 {
		lock.lock()
		defer { lock.unlock() }
		return _currentTime
	}

	func advance(by milliseconds: Int64) {
		lock.lock()
		defer { lock.unlock() }
		_currentTime += milliseconds
	}
}

// MARK: - Mock Policy Provider

final class MockPolicyProvider: PolicyProvider, @unchecked Sendable {
	private var _policies: [EventPolicy] = []
	private let lock = NSLock()

	var policies: [EventPolicy] {
		get {
			lock.lock()
			defer { lock.unlock() }
			return _policies
		}
		set {
			lock.lock()
			defer { lock.unlock() }
			_policies = newValue
		}
	}

	init(policies: [EventPolicy] = []) {
		_policies = policies
	}

	func getActivePolicies() -> [EventPolicy] {
		lock.lock()
		defer { lock.unlock() }
		return _policies
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
