//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Provides current time for the journey-events module.
///
/// This abstraction allows for:
/// - Testable time-based logic (cooldowns, timestamps)
/// - Consistent time source across the module
/// - Easy mocking in unit tests
///
/// **Why this exists:**
/// Cooldown functionality requires time calculations. Using `Date()` directly
/// makes tests non-deterministic and slow (requiring actual time delays).
/// This protocol allows tests to control time precisely.
public protocol TimeProvider: Sendable {
    /// Returns current time in milliseconds since epoch (January 1, 1970 00:00:00 UTC).
    ///
    /// - Returns: Current time in milliseconds
    func currentTimeMillis() -> Int64
}
