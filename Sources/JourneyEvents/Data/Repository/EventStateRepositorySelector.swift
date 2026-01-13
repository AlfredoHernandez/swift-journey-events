//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Repository selector that delegates to either persistent or in-memory storage
/// based on the event policy's `persistAcrossSessions` configuration.
///
/// ## How It Works
///
/// - Event policies with `persistAcrossSessions = true` → ``UserDefaultsEventStateRepository`` (data persists)
/// - Event policies with `persistAcrossSessions = false` → ``InMemoryEventStateRepository`` (data resets on app restart)
/// - Unknown event policies → Defaults to persistent storage for safety
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
    private let persistentRepo: UserDefaultsEventStateRepository
    private let inMemoryRepo: InMemoryEventStateRepository

    /// Index mapping event policy ID to persistence strategy.
    ///
    /// Map structure: `policyID -> shouldPersist`
    /// - `true` = use UserDefaults
    /// - `false` = use in-memory storage
    private let policyPersistenceIndex: [String: Bool]

    /// Creates a new repository selector.
    ///
    /// - Parameters:
    ///   - persistentRepo: Repository for persistent storage (UserDefaults)
    ///   - inMemoryRepo: Repository for in-memory storage
    ///   - policyProvider: Provider for active event policies
    public init(
        persistentRepo: UserDefaultsEventStateRepository,
        inMemoryRepo: InMemoryEventStateRepository,
        policyProvider: PolicyProvider,
    ) {
        self.persistentRepo = persistentRepo
        self.inMemoryRepo = inMemoryRepo

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
    ///            `inMemoryRepo` if event policy has `persistAcrossSessions=false`
    private func getRepositoryForPolicy(policyID: String) -> EventStateRepository {
        let shouldPersist = policyPersistenceIndex[policyID] ?? true // default to persistent
        return shouldPersist ? persistentRepo : inMemoryRepo
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
