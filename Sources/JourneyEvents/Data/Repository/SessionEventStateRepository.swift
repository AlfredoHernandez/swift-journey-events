//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Production-ready, non-persistent implementation of ``EventStateRepository``.
///
/// Stores event policy counters and timestamps for the lifetime of a single app session.
/// All state is lost when the app terminates or the instance is deallocated.
///
/// ## When Used
///
/// This is the default session-only backing store selected by ``EventStateRepositorySelector``
/// for event policies with `persistAcrossSessions = false`. Use it directly when you need a
/// session-scoped store outside the selector (for example, in feature-specific trackers that
/// should never persist counters across launches).
///
/// ## Use Cases
///
/// Session-only tracking is appropriate for:
/// - Time-limited campaigns that should reset between launches
/// - Frequency caps that intentionally relax on relaunch
/// - Privacy-sensitive features that must not persist user counters
///
/// ## Thread Safety
///
/// Uses Swift actor isolation for safe concurrent access from multiple tasks.
/// All methods can be called concurrently without additional synchronization.
///
/// ## Example
///
///     let repository = SessionEventStateRepository()
///     await repository.incrementCount(policyID: "article_ad")
///     let count = await repository.getCount(policyID: "article_ad")
///     // count == 1
///
/// - Note: This is the production analogue of the test-only
///   ``InMemoryEventStateRepository`` shipped in `JourneyEventsTesting`.
/// - SeeAlso: ``EventStateRepository``
/// - SeeAlso: ``UserDefaultsEventStateRepository`` for persistent storage
public actor SessionEventStateRepository: EventStateRepository {
	private var counts: [String: Int] = [:]
	private var lastActionTimestamps: [String: Int64] = [:]
	private var lastCountedStepTimestamps: [String: Int64] = [:]

	/// Creates a new session-scoped event state repository.
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
		lastActionTimestamps[policyID] = timestamp
	}

	public func getLastActionTriggeredTimestamp(policyID: String) -> Int64? {
		lastActionTimestamps[policyID]
	}

	public func setLastCountedStepTimestamp(policyID: String, timestamp: Int64) {
		lastCountedStepTimestamps[policyID] = timestamp
	}

	public func getLastCountedStepTimestamp(policyID: String) -> Int64? {
		lastCountedStepTimestamps[policyID]
	}
}
