//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Repository for managing event policy state.
///
/// Manages counters for each policy and their cooldown state.
///
/// **Implementations:**
/// - `UserDefaultsEventStateRepository`: Persistent storage (UserDefaults)
/// - `InMemoryEventStateRepository`: Session-only storage (in-memory)
/// - `EventStateRepositorySelector`: Strategy selector (chooses based on policy config)
public protocol EventStateRepository: Sendable {
    /// Gets the current counter for a specific policy.
    ///
    /// - Parameter policyID: Policy ID
    /// - Returns: Current counter (number of times the pattern has occurred)
    func getCount(policyID: String) async -> Int

    /// Increments a policy counter by 1.
    ///
    /// - Parameter policyID: Policy ID
    func incrementCount(policyID: String) async

    /// Resets a policy counter to 0.
    ///
    /// Called after triggering an action to restart the cycle.
    ///
    /// - Parameter policyID: Policy ID
    func resetCount(policyID: String) async

    /// Records the timestamp of the last action triggered for a policy.
    ///
    /// Used by the cooldown system to enforce minimum wait times between actions.
    /// Called automatically when an action is triggered for a policy with `cooldownMinutes > 0`.
    ///
    /// - Parameters:
    ///   - policyID: Policy ID
    ///   - timestamp: Timestamp in millis of the last action triggered
    func setLastActionTriggeredTimestamp(policyID: String, timestamp: Int64) async

    /// Gets the timestamp of the last action triggered for a policy.
    ///
    /// Used by the cooldown system to calculate elapsed time since last action.
    ///
    /// - Parameter policyID: Policy ID
    /// - Returns: Timestamp in millis, or nil if an action has never been triggered for this policy
    func getLastActionTriggeredTimestamp(policyID: String) async -> Int64?

    /// Records the timestamp of the last step that incremented the counter for a multi-step sequence.
    ///
    /// Used to prevent double-counting when old completed sequences remain in history.
    /// Only sequences where the last step has a timestamp AFTER this timestamp should increment the counter.
    ///
    /// **Example use case:**
    /// - User completes sequence A→B→C (counter: 1/2, lastCountedStepTimestamp: 3000ms)
    /// - Later, user triggers only step C (timestamp: 5000ms)
    /// - System finds old sequence in history but sees timestamp 3000ms was already counted
    /// - Counter stays at 1/2 (prevents double-counting)
    ///
    /// - Parameters:
    ///   - policyID: Policy ID
    ///   - timestamp: Timestamp in millis of the last step that incremented the counter
    func setLastCountedStepTimestamp(policyID: String, timestamp: Int64) async

    /// Gets the timestamp of the last step that incremented the counter.
    ///
    /// Used to filter out old sequence completions that have already been counted.
    ///
    /// - Parameter policyID: Policy ID
    /// - Returns: Timestamp in millis, or nil if no step has been counted yet
    func getLastCountedStepTimestamp(policyID: String) async -> Int64?
}
