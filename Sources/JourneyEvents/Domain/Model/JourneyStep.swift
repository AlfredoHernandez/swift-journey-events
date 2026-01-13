//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import Foundation

/// Represents a specific step in the user's journey within the app.
///
/// Each step captures a significant action that the user performs,
/// including relevant context through parameters.
///
/// Examples:
/// ```swift
/// JourneyStep(name: "app_started")
/// JourneyStep(name: "line_viewed", parameters: ["id": "linea_1", "name": "Line 1"])
/// JourneyStep(name: "station_selected", parameters: ["id": "pantitlan", "lineId": "linea_1"])
/// JourneyStep(name: "map_viewed")
/// JourneyStep(name: "news_detail_viewed", parameters: ["id": "123", "title": "...", "count": 5])
/// ```
public struct JourneyStep: Sendable, Equatable {
    /// Step name (e.g., "line_viewed", "station_selected")
    public let name: String

    /// Additional step context supporting multiple types (String, Int, Bool, Double)
    public let parameters: [String: AnyHashableSendable]

    /// Moment when the step occurred (milliseconds since epoch)
    public let timestamp: Int64

    public init(
        name: String,
        parameters: [String: AnyHashableSendable] = [:],
        timestamp: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
    ) {
        self.name = name
        self.parameters = parameters
        self.timestamp = timestamp
    }
}

/// A type-erased hashable and sendable value for use in parameters.
///
/// This type wraps any `Hashable & Sendable` value in a type-erased container.
/// The `@unchecked Sendable` is safe because:
/// - The underlying value is immutable (let)
/// - Only `Sendable` values can be stored via the public initializer
public struct AnyHashableSendable: Hashable, @unchecked Sendable {
    private let value: AnyHashable

    public init(_ value: some Hashable & Sendable) {
        self.value = AnyHashable(value)
    }

    public func value<T>(as _: T.Type) -> T? {
        value.base as? T
    }
}

extension AnyHashableSendable: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension AnyHashableSendable: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension AnyHashableSendable: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension AnyHashableSendable: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self.init(value)
    }
}

extension AnyHashableSendable: CustomStringConvertible {
    public var description: String {
        String(describing: value.base)
    }
}
