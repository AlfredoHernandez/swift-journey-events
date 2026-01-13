//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import Foundation

/// Production implementation of `TimeProvider` using system time.
///
/// This implementation delegates to `Date`, providing the actual current time
/// from the device's system clock in milliseconds since Unix epoch.
///
/// **Thread-safety:** `Date` is thread-safe by design.
public struct SystemTimeProvider: TimeProvider {
    public init() {}

    public func currentTimeMillis() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
}
