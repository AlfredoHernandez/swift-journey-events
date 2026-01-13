//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// In-memory implementation of `EventStateRepository`.
///
/// Stores event policy counters in memory only. All state is lost when the app restarts.
/// Used for policies with `persistAcrossSessions = false`.
///
/// **Thread-safety:** Uses Swift actor isolation for safe concurrent access.
///
/// **Use case:** Temporary counters for actions that should reset on each app session,
/// useful for:
/// - Testing different action frequencies without persistent data
/// - Time-limited campaigns
/// - Session-based user journey tracking
public actor InMemoryEventStateRepository: EventStateRepository {
    private var counts: [String: Int] = [:]
    private var timestamps: [String: Int64] = [:]
    private var lastCountedStepTimestamps: [String: Int64] = [:]

    public init() {}

    public func getCount(policyID: String) -> Int {
        counts[policyID] ?? 0
    }

    public func incrementCount(policyID: String) {
        counts[policyID, default: 0] += 1
    }

    public func resetCount(policyID: String) {
        counts[policyID] = 0
    }

    public func setLastActionTriggeredTimestamp(policyID: String, timestamp: Int64) {
        timestamps[policyID] = timestamp
    }

    public func getLastActionTriggeredTimestamp(policyID: String) -> Int64? {
        timestamps[policyID]
    }

    public func setLastCountedStepTimestamp(policyID: String, timestamp: Int64) {
        lastCountedStepTimestamps[policyID] = timestamp
    }

    public func getLastCountedStepTimestamp(policyID: String) -> Int64? {
        lastCountedStepTimestamps[policyID]
    }
}
