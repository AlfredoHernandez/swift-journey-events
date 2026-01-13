//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Defines the conditions under which an action should be triggered based on user journey events.
///
/// A policy specifies:
/// - Which journey pattern must be fulfilled
/// - How many times it must occur (threshold)
/// - Additional configurations (cooldown, persistence)
public struct EventPolicy: Sendable, Equatable {
    /// Unique identifier of the policy
    public let id: String

    /// Key to identify the action to be triggered (e.g., ad unit ID, analytics event name)
    public let actionKey: String

    /// Journey pattern that activates this policy
    public let pattern: JourneyPattern

    /// Number of times the pattern must be fulfilled before triggering the action
    public let threshold: Int

    /// Wait time in minutes between consecutive action triggers.
    /// - `0`: No cooldown - action triggers immediately when threshold reached
    /// - `> 0`: Enforces minimum wait time between actions, even if threshold reached
    ///
    /// Example: `cooldownMinutes = 15` means minimum 15 minutes between triggers
    public let cooldownMinutes: Int

    /// Whether counter progress persists between app sessions.
    /// - `true`: Counters persist using UserDefaults (survive app restarts)
    /// - `false`: Counters stored in memory only (reset on app restart)
    public let persistAcrossSessions: Bool

    public init(
        id: String,
        actionKey: String,
        pattern: JourneyPattern,
        threshold: Int,
        cooldownMinutes: Int = 0,
        persistAcrossSessions: Bool = true,
    ) {
        self.id = id
        self.actionKey = actionKey
        self.pattern = pattern
        self.threshold = threshold
        self.cooldownMinutes = cooldownMinutes
        self.persistAcrossSessions = persistAcrossSessions
    }
}
