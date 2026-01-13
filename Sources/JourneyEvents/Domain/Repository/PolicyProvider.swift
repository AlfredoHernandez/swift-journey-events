//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Provides event policies to the journey-events module.
///
/// This protocol allows the app to define its own policies
/// without hardcoding them in the module, making journey-events
/// completely reusable across different applications.
///
/// **Implementation Example:**
/// ```swift
/// final class MyAppPolicyProvider: PolicyProvider {
///     func getActivePolicies() -> [EventPolicy] {
///         [
///             // Persistent policy (counter survives app restarts)
///             EventPolicy(
///                 id: "my_custom_action",
///                 actionKey: "my_action_key",
///                 pattern: JourneyPattern(steps: ["my_event"]),
///                 threshold: 5,
///                 cooldownMinutes: 0,
///                 persistAcrossSessions: true  // Uses UserDefaults
///             ),
///             // Session-only policy (counter resets on app close)
///             EventPolicy(
///                 id: "session_action",
///                 actionKey: "session_action_key",
///                 pattern: JourneyPattern(steps: ["session_event"]),
///                 threshold: 3,
///                 cooldownMinutes: 0,
///                 persistAcrossSessions: false  // Uses in-memory storage
///             )
///         ]
///     }
/// }
/// ```
public protocol PolicyProvider: Sendable {
    /// Returns the list of active event policies.
    ///
    /// Policies define when and how actions should be triggered based on
    /// user journey patterns.
    ///
    /// - Returns: List of active policies
    func getActivePolicies() -> [EventPolicy]
}
