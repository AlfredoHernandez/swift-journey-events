//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import Foundation
import os

/// Implementation of ``EventStateRepository`` using `UserDefaults`.
///
/// Persists event policy state across app sessions. All counters and timestamps are
/// stored locally.
///
/// ## When Used
///
/// This implementation is selected by ``EventStateRepositorySelector`` for policies
/// with `persistAcrossSessions = true`. Counters survive app restarts.
///
/// ## Thread Safety
///
/// `UserDefaults` is documented thread-safe by Apple for individual operations, but
/// is not declared `Sendable`. Atomicity for read–modify–write sequences (notably
/// ``incrementCount(policyID:)``) is provided by a process-wide static lock that
/// serializes access across all repository instances. Without it, two distinct
/// `UserDefaultsEventStateRepository` instances pointing at the same `UserDefaults`
/// (e.g. an app and an extension target sharing a suite, or simply two repository
/// instances in the same process) would race their reads and lose increments.
///
/// The class is declared `Sendable` despite holding a non-Sendable `UserDefaults`
/// reference because every access to that reference is gated through the static
/// lock; the underlying value is treated as if it were behind an ``OSAllocatedUnfairLock``.
public final class UserDefaultsEventStateRepository: EventStateRepository, Sendable {
	private static let prefsName = "journey_events_state"
	private static let keyPrefixCount = "event_state_count_"
	private static let keyPrefixTimestamp = "event_state_timestamp_"
	private static let keyPrefixLastCountedStep = "event_state_last_counted_step_"

	/// Process-wide lock guarding read–modify–write atomicity across all repository
	/// instances. Must wrap every access to `userDefaults` in this type.
	private static let lock = OSAllocatedUnfairLock(initialState: ())

	/// `UserDefaults` is thread-safe for individual operations and only mutated under
	/// `Self.lock`, so the unsafe annotation is justified by the synchronization contract
	/// documented above. Do not access this property outside `Self.lock.withLock { ... }`.
	private nonisolated(unsafe) let userDefaults: UserDefaults

	/// Creates a new UserDefaults-backed event state repository.
	///
	/// - Parameter userDefaults: Custom UserDefaults instance. If `nil`, creates a suite
	///   with the name "journey_events_state" or falls back to `.standard`.
	public init(userDefaults: UserDefaults? = nil) {
		self.userDefaults = userDefaults ?? UserDefaults(suiteName: Self.prefsName) ?? .standard
	}

	public func getCount(policyID: String) async -> Int {
		let key = countKey(for: policyID)
		return Self.lock.withLock { _ in userDefaults.integer(forKey: key) }
	}

	public func incrementCount(policyID: String) async {
		let key = countKey(for: policyID)
		Self.lock.withLock { _ in
			let current = userDefaults.integer(forKey: key)
			userDefaults.set(current + 1, forKey: key)
		}
	}

	public func resetCount(policyID: String) async {
		let key = countKey(for: policyID)
		Self.lock.withLock { _ in userDefaults.set(0, forKey: key) }
	}

	public func setLastActionTriggeredTimestamp(policyID: String, timestamp: Int64) async {
		let key = timestampKey(for: policyID)
		Self.lock.withLock { _ in userDefaults.set(timestamp, forKey: key) }
	}

	public func getLastActionTriggeredTimestamp(policyID: String) async -> Int64? {
		let key = timestampKey(for: policyID)
		return Self.lock.withLock { _ in userDefaults.object(forKey: key) as? Int64 }
	}

	public func setLastCountedStepTimestamp(policyID: String, timestamp: Int64) async {
		let key = lastCountedStepKey(for: policyID)
		Self.lock.withLock { _ in userDefaults.set(timestamp, forKey: key) }
	}

	public func getLastCountedStepTimestamp(policyID: String) async -> Int64? {
		let key = lastCountedStepKey(for: policyID)
		return Self.lock.withLock { _ in userDefaults.object(forKey: key) as? Int64 }
	}

	// MARK: - Private Helpers

	private func countKey(for policyID: String) -> String {
		"\(Self.keyPrefixCount)\(policyID)"
	}

	private func timestampKey(for policyID: String) -> String {
		"\(Self.keyPrefixTimestamp)\(policyID)"
	}

	private func lastCountedStepKey(for policyID: String) -> String {
		"\(Self.keyPrefixLastCountedStep)\(policyID)"
	}
}
