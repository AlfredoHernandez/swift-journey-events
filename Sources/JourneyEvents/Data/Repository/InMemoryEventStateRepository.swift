//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// In-memory implementation of ``EventStateRepository``.
///
/// Stores event policy counters and timestamps in memory only. All state is
/// lost when the app restarts or the instance is deallocated.
///
/// ## Overview
///
/// This implementation is used for policies with ``EventPolicy/persistAcrossSessions``
/// set to `false`, providing session-only state management. It stores three types
/// of data in memory:
/// - Policy counters (pattern occurrence/completion counts)
/// - Last action triggered timestamps (for cooldown tracking)
/// - Last counted step timestamps (for multi-step deduplication)
///
/// ## Use Cases
///
/// Session-only tracking is ideal for:
/// - Testing different action frequencies without persistent data
/// - Time-limited campaigns that should reset daily
/// - Session-based user journey tracking
/// - Privacy-sensitive features that shouldn't persist user data
///
/// ## Thread Safety
///
/// Uses Swift actor isolation for safe concurrent access from multiple tasks.
/// All methods can be called concurrently without additional synchronization.
///
/// ## Example
///
///     let repository = InMemoryEventStateRepository()
///     await repository.incrementCount(policyID: "article_ad")
///     let count = await repository.getCount(policyID: "article_ad")
///     print(count) // Output: 1
///
/// - Note: All data is lost when the app restarts.
/// - SeeAlso: ``EventStateRepository`` for protocol documentation
/// - SeeAlso: ``UserDefaultsEventStateRepository`` for persistent storage
public actor InMemoryEventStateRepository: EventStateRepository {
    /// Policy counters keyed by policy ID.
    private var counts: [String: Int] = [:]

    /// Last action triggered timestamps keyed by policy ID.
    private var timestamps: [String: Int64] = [:]

    /// Last counted step timestamps keyed by policy ID.
    private var lastCountedStepTimestamps: [String: Int64] = [:]

    /// Creates a new in-memory event state repository.
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
