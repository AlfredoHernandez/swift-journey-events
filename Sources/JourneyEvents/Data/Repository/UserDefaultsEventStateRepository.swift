//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import Foundation

/// Implementation of `EventStateRepository` using UserDefaults.
///
/// Persists event policy state across app sessions.
/// All counters and timestamps are stored locally.
///
/// **When used:**
/// This implementation is selected by `EventStateRepositorySelector` for policies
/// with `persistAcrossSessions = true`. Counters survive app restarts.
public final class UserDefaultsEventStateRepository: EventStateRepository, @unchecked Sendable {
    private static let prefsName = "journey_events_state"
    private static let keyPrefixCount = "event_state_count_"
    private static let keyPrefixTimestamp = "event_state_timestamp_"
    private static let keyPrefixLastCountedStep = "event_state_last_counted_step_"

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults? = nil) {
        self.userDefaults = userDefaults ?? UserDefaults(suiteName: Self.prefsName) ?? .standard
    }

    public func getCount(policyID: String) async -> Int {
        userDefaults.integer(forKey: countKey(for: policyID))
    }

    public func incrementCount(policyID: String) async {
        let currentCount = await getCount(policyID: policyID)
        userDefaults.set(currentCount + 1, forKey: countKey(for: policyID))
    }

    public func resetCount(policyID: String) async {
        userDefaults.set(0, forKey: countKey(for: policyID))
    }

    public func setLastActionTriggeredTimestamp(policyID: String, timestamp: Int64) async {
        userDefaults.set(timestamp, forKey: timestampKey(for: policyID))
    }

    public func getLastActionTriggeredTimestamp(policyID: String) async -> Int64? {
        let timestamp = userDefaults.object(forKey: timestampKey(for: policyID)) as? Int64
        return timestamp
    }

    public func setLastCountedStepTimestamp(policyID: String, timestamp: Int64) async {
        userDefaults.set(timestamp, forKey: lastCountedStepKey(for: policyID))
    }

    public func getLastCountedStepTimestamp(policyID: String) async -> Int64? {
        let timestamp = userDefaults.object(forKey: lastCountedStepKey(for: policyID)) as? Int64
        return timestamp
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
