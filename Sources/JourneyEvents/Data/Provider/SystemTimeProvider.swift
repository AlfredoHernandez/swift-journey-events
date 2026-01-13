//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import Foundation

/// Production implementation of ``TimeProvider`` using system time.
///
/// Provides the actual current time from the device's system clock,
/// measured in milliseconds since Unix epoch (January 1, 1970 00:00:00 UTC).
///
/// ## Overview
///
/// This implementation delegates to Foundation's `Date` type to get the
/// current time. It's the standard implementation for production use and
/// should be used in all non-testing scenarios.
///
/// ## Usage
///
///     let timeProvider = SystemTimeProvider()
///     let now = timeProvider.currentTimeMillis()
///     print(now) // Output: 1736764800000 (example timestamp)
///
/// Use with journey events:
///
///     let evaluatePolicy = EvaluateEventPolicy(
///         eventStateRepository: stateRepo,
///         logger: logger,
///         timeProvider: SystemTimeProvider()  // Use real system time
///     )
///
/// ## Testing
///
/// For unit tests, create a mock implementation of ``TimeProvider`` that
/// returns controlled time values instead of using this implementation.
///
/// ## Thread Safety
///
/// Thread-safe by design. Foundation's `Date` is thread-safe and can be
/// called concurrently from multiple threads.
///
/// - SeeAlso: ``TimeProvider`` for protocol documentation
/// - SeeAlso: ``EvaluateEventPolicy`` for cooldown calculations using time
public struct SystemTimeProvider: TimeProvider {
    /// Creates a new system time provider.
    public init() {}

    public func currentTimeMillis() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
}
