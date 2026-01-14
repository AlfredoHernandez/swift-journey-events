//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Defines the conditions under which an action should be triggered based on user journey events.
///
/// A policy combines a journey pattern with triggering rules to create behavior-based
/// actions. Policies control when and how frequently actions occur based on user
/// navigation patterns.
///
/// ## Overview
///
/// Each policy specifies:
/// - A ``JourneyPattern`` defining which steps to track
/// - A threshold indicating how many times the pattern must occur
/// - Optional cooldown period to rate-limit action triggers
/// - Persistence strategy (in-memory vs UserDefaults)
///
/// ## Use Cases
///
/// ### Frequency-Based Actions
///
/// Show an interstitial ad after 5 article views:
///
///     let policy = EventPolicy(
///         id: "article_ad",
///         actionKey: "ca-app-pub-xxx/yyy",
///         pattern: JourneyPattern(steps: ["article_viewed"]),
///         threshold: 5
///     )
///
/// ### Sequence-Based Actions
///
/// Show tutorial after completing onboarding flow:
///
///     let policy = EventPolicy(
///         id: "onboarding_tutorial",
///         actionKey: "show_tutorial",
///         pattern: JourneyPattern(steps: ["welcome_viewed", "profile_created", "home_viewed"]),
///         threshold: 1
///     )
///
/// ### Rate-Limited Actions
///
/// Show notification prompt at most once per hour:
///
///     let policy = EventPolicy(
///         id: "notification_prompt",
///         actionKey: "request_notifications",
///         pattern: JourneyPattern(steps: ["app_opened"]),
///         threshold: 3,
///         cooldownMinutes: 60
///     )
///
/// ### Session-Only Actions
///
/// Show tip dialog during current session only:
///
///     let policy = EventPolicy(
///         id: "session_tip",
///         actionKey: "show_tip",
///         pattern: JourneyPattern(steps: ["feature_used"]),
///         threshold: 2,
///         persistAcrossSessions: false
///     )
///
/// - SeeAlso: ``JourneyPattern`` for defining step patterns
/// - SeeAlso: ``PolicyEvaluation`` for evaluation results
/// - SeeAlso: ``EvaluateEventPolicy`` for the evaluation use case
public struct EventPolicy: Sendable, Equatable {
    /// Unique identifier for this policy.
    ///
    /// Used to track state and distinguish between different policies.
    /// Must be unique across all policies in your app.
    public let id: String

    /// The action identifier to trigger when conditions are met.
    ///
    /// This key is returned in ``PolicyEvaluation/actionKey`` and can represent:
    /// - Ad unit IDs (e.g., "ca-app-pub-xxx/yyy")
    /// - Analytics event names (e.g., "show_rating_prompt")
    /// - Feature flags (e.g., "enable_premium_feature")
    /// - Any custom action identifier your app needs
    public let actionKey: String

    /// The journey pattern that activates this policy.
    ///
    /// Defines which user steps must occur before this policy can trigger.
    /// See ``JourneyPattern`` for pattern types and examples.
    public let pattern: JourneyPattern

    /// The number of times the pattern must be fulfilled before triggering the action.
    ///
    /// For single-step patterns: Number of occurrences required.
    /// For multi-step patterns: Number of sequence completions required.
    ///
    /// Example: `threshold = 5` means the pattern must occur 5 times.
    public let threshold: Int

    /// Minimum wait time in minutes between consecutive action triggers.
    ///
    /// Controls rate-limiting to prevent actions from triggering too frequently:
    /// - `0`: No cooldown (action triggers immediately when threshold is reached)
    /// - `> 0`: Enforces minimum wait time between triggers
    ///
    /// Example: `cooldownMinutes = 15` ensures at least 15 minutes between actions,
    /// even if the threshold is reached multiple times.
    ///
    /// - Note: Counter continues accumulating during cooldown but won't trigger until cooldown expires.
    public let cooldownMinutes: Int

    /// Determines whether counter state persists between app sessions.
    ///
    /// - `true`: Counters persist using ``UserDefaultsEventStateRepository`` (survive app restarts)
    /// - `false`: Counters use ``InMemoryEventStateRepository`` (reset on app restart)
    ///
    /// Use persistent storage for long-term user behavior tracking.
    /// Use in-memory storage for session-only or testing scenarios.
    public let persistAcrossSessions: Bool

    /// Creates a new event policy.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for this policy
    ///   - actionKey: Action identifier to trigger (e.g., ad unit ID, event name)
    ///   - pattern: Journey pattern that activates this policy
    ///   - threshold: Number of times pattern must occur before triggering
    ///   - cooldownMinutes: Minimum minutes between triggers (default: 0)
    ///   - persistAcrossSessions: Whether to persist state across sessions (default: true)
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
