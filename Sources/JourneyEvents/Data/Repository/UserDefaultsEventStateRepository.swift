//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import Foundation

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
/// `UserDefaults` is documented as thread-safe by Apple but is not declared `Sendable`.
/// Wrapping the reference in an actor confines it to a single isolation domain, so the
/// repository is safely shareable across tasks without unchecked-Sendable escape hatches.
public actor UserDefaultsEventStateRepository: EventStateRepository {
	private static let prefsName = "journey_events_state"
	private static let keyPrefixCount = "event_state_count_"
	private static let keyPrefixTimestamp = "event_state_timestamp_"
	private static let keyPrefixLastCountedStep = "event_state_last_counted_step_"

	private let userDefaults: UserDefaults

	/// Creates a new UserDefaults-backed event state repository.
	///
	/// - Parameter userDefaults: Custom UserDefaults instance. If `nil`, creates a suite
	///   with the name "journey_events_state" or falls back to `.standard`.
	public init(userDefaults: UserDefaults? = nil) {
		self.userDefaults = userDefaults ?? UserDefaults(suiteName: Self.prefsName) ?? .standard
	}

	public func getCount(policyID: String) -> Int {
		userDefaults.integer(forKey: countKey(for: policyID))
	}

	public func incrementCount(policyID: String) {
		let current = userDefaults.integer(forKey: countKey(for: policyID))
		userDefaults.set(current + 1, forKey: countKey(for: policyID))
	}

	public func resetCount(policyID: String) {
		userDefaults.set(0, forKey: countKey(for: policyID))
	}

	public func setLastActionTriggeredTimestamp(policyID: String, timestamp: Int64) {
		userDefaults.set(timestamp, forKey: timestampKey(for: policyID))
	}

	public func getLastActionTriggeredTimestamp(policyID: String) -> Int64? {
		userDefaults.object(forKey: timestampKey(for: policyID)) as? Int64
	}

	public func setLastCountedStepTimestamp(policyID: String, timestamp: Int64) {
		userDefaults.set(timestamp, forKey: lastCountedStepKey(for: policyID))
	}

	public func getLastCountedStepTimestamp(policyID: String) -> Int64? {
		userDefaults.object(forKey: lastCountedStepKey(for: policyID)) as? Int64
	}

	// MARK: - Private Helpers

	private nonisolated func countKey(for policyID: String) -> String {
		"\(Self.keyPrefixCount)\(policyID)"
	}

	private nonisolated func timestampKey(for policyID: String) -> String {
		"\(Self.keyPrefixTimestamp)\(policyID)"
	}

	private nonisolated func lastCountedStepKey(for policyID: String) -> String {
		"\(Self.keyPrefixLastCountedStep)\(policyID)"
	}
}
