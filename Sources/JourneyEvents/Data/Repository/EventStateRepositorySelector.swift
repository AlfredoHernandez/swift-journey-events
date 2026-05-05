//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Repository selector that delegates to either persistent or session-only storage
/// based on the event policy's `persistAcrossSessions` configuration.
///
/// ## How It Works
///
/// - Event policies with `persistAcrossSessions = true` → persistent repository (data persists)
/// - Event policies with `persistAcrossSessions = false` → session-only repository (data resets on app restart)
/// - Unknown event policies → Defaults to persistent storage for safety
///
/// ## Composition
///
/// The persistent side defaults to ``UserDefaultsEventStateRepository``; the session-only
/// side defaults to ``SessionEventStateRepository``. Both are `Sendable` actors, no
/// `@unchecked` escape hatches involved. The defaults can be overridden when a different
/// backing store is required (for example, a test double or an alternative persistence
/// layer).
///
/// ## Performance
///
/// Uses an eagerly-built index for O(1) event policy lookups instead of filtering on every operation.
///
/// ## Thread Safety
///
/// This type is `Sendable` because all stored properties are immutable after initialization
/// and the underlying repositories handle their own thread safety.
public struct EventStateRepositorySelector: EventStateRepository, Sendable {
	/// The backing repository for persistent policies (default: ``UserDefaultsEventStateRepository``).
	///
	/// Override when you need a different persistence layer (e.g., a test double).
	private let persistentRepo: UserDefaultsEventStateRepository

	/// The backing repository for session-only policies (default: ``SessionEventStateRepository``).
	///
	/// Override when you need a different in-memory store (e.g., a test double).
	private let sessionRepo: SessionEventStateRepository

	/// Index mapping event policy ID to persistence strategy.
	///
	/// Map structure: `policyID -> shouldPersist`
	/// - `true` = use the persistent repository
	/// - `false` = use the session-only repository
	private let policyPersistenceIndex: [String: Bool]

	/// Creates a new repository selector.
	///
	/// - Parameters:
	///   - persistentRepo: Repository for persistent storage. Defaults to
	///     ``UserDefaultsEventStateRepository``.
	///   - sessionRepo: Repository for session-only storage. Defaults to
	///     ``SessionEventStateRepository``.
	///   - policyProvider: Provider for active event policies.
	public init(
		persistentRepo: UserDefaultsEventStateRepository = UserDefaultsEventStateRepository(),
		sessionRepo: SessionEventStateRepository = SessionEventStateRepository(),
		policyProvider: PolicyProvider,
	) {
		self.persistentRepo = persistentRepo
		self.sessionRepo = sessionRepo

		// Build index eagerly for thread safety and Sendable conformance
		policyPersistenceIndex = Dictionary(
			uniqueKeysWithValues: policyProvider.getActivePolicies().map { policy in
				(policy.id, policy.persistAcrossSessions)
			},
		)
	}

	/// Selects the appropriate repository for a given event policy.
	///
	/// - Parameter policyID: The event policy identifier
	/// - Returns: `persistentRepo` if event policy has `persistAcrossSessions=true` or is unknown,
	///            `sessionRepo` if event policy has `persistAcrossSessions=false`
	private func getRepositoryForPolicy(policyID: String) -> any EventStateRepository {
		let shouldPersist = policyPersistenceIndex[policyID] ?? true // default to persistent
		return shouldPersist ? persistentRepo : sessionRepo
	}

	public func getCount(policyID: String) async -> Int {
		await getRepositoryForPolicy(policyID: policyID).getCount(policyID: policyID)
	}

	public func incrementCount(policyID: String) async {
		await getRepositoryForPolicy(policyID: policyID).incrementCount(policyID: policyID)
	}

	public func resetCount(policyID: String) async {
		await getRepositoryForPolicy(policyID: policyID).resetCount(policyID: policyID)
	}

	public func setLastActionTriggeredTimestamp(policyID: String, timestamp: Int64) async {
		await getRepositoryForPolicy(policyID: policyID)
			.setLastActionTriggeredTimestamp(policyID: policyID, timestamp: timestamp)
	}

	public func getLastActionTriggeredTimestamp(policyID: String) async -> Int64? {
		await getRepositoryForPolicy(policyID: policyID)
			.getLastActionTriggeredTimestamp(policyID: policyID)
	}

	public func setLastCountedStepTimestamp(policyID: String, timestamp: Int64) async {
		await getRepositoryForPolicy(policyID: policyID)
			.setLastCountedStepTimestamp(policyID: policyID, timestamp: timestamp)
	}

	public func getLastCountedStepTimestamp(policyID: String) async -> Int64? {
		await getRepositoryForPolicy(policyID: policyID)
			.getLastCountedStepTimestamp(policyID: policyID)
	}
}
