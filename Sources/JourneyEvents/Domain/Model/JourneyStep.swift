//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import Foundation

/// Represents a specific step in the user's journey within the app.
///
/// Each step captures a significant action that the user performs,
/// including relevant context through parameters. Steps are the fundamental
/// building blocks used to track user behavior and trigger policy-based actions.
///
/// ## Overview
///
/// Journey steps capture user actions with three key pieces of information:
/// - A unique name identifying the type of action
/// - Optional parameters providing additional context
/// - A timestamp recording when the action occurred
///
/// ## Usage
///
/// Create simple steps with just a name:
///
///     let step = JourneyStep(name: "app_started")
///
/// Add context using parameters:
///
///     let step = JourneyStep(
///         name: "line_viewed",
///         parameters: ["id": "linea_1", "name": "Line 1"]
///     )
///
/// Chain multiple steps to create user journey patterns:
///
///     tracker.trackStep(JourneyStep(name: "app_started"))
///     tracker.trackStep(JourneyStep(name: "line_viewed", parameters: ["id": "linea_1"]))
///     tracker.trackStep(JourneyStep(name: "station_selected", parameters: ["id": "pantitlan"]))
///
/// - Note: Parameters support String, Int, Bool, and Double values via ``AnyHashableSendable``.
/// - SeeAlso: ``JourneyPattern`` for defining step sequences
/// - SeeAlso: ``EventPolicy`` for creating behavior-based triggers
public struct JourneyStep: Sendable, Equatable {
    /// The name identifying this step type.
    ///
    /// Use consistent naming conventions across your app for reliable pattern matching.
    /// Examples: "app_started", "line_viewed", "station_selected"
    public let name: String

    /// Additional context for this step.
    ///
    /// Parameters can contain String, Int, Bool, or Double values wrapped in
    /// ``AnyHashableSendable``. Empty dictionary if no parameters are needed.
    public let parameters: [String: AnyHashableSendable]

    /// The timestamp when this step occurred, measured in milliseconds since Unix epoch.
    ///
    /// Used for sequence validation and cooldown calculations.
    public let timestamp: Int64

    /// Creates a new journey step.
    ///
    /// - Parameters:
    ///   - name: The step name (e.g., "line_viewed", "station_selected")
    ///   - parameters: Additional context as key-value pairs (default: empty)
    ///   - timestamp: When the step occurred in milliseconds since epoch (default: current time)
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

/// A type-erased hashable and sendable value for use in ``JourneyStep`` parameters.
///
/// This type wraps any `Hashable & Sendable` value in a type-erased container,
/// allowing ``JourneyStep`` parameters to store values of different types
/// (String, Int, Bool, Double) in a single dictionary.
///
/// ## Overview
///
/// ``AnyHashableSendable`` provides type safety while enabling flexible parameter storage.
/// Values are stored immutably and can be retrieved with type checking.
///
/// ## Usage
///
/// Create values directly or use literal expressions:
///
///     let stringValue = AnyHashableSendable("line_1")
///     let intValue = AnyHashableSendable(42)
///     let boolValue = AnyHashableSendable(true)
///     let doubleValue = AnyHashableSendable(3.14)
///
/// Use in step parameters with literal syntax:
///
///     let step = JourneyStep(
///         name: "item_viewed",
///         parameters: [
///             "id": "line_1",        // String literal
///             "count": 5,            // Int literal
///             "premium": true,       // Bool literal
///             "rating": 4.5          // Double literal
///         ]
///     )
///
/// Retrieve typed values safely:
///
///     if let id = step.parameters["id"]?.value(as: String.self) {
///         print("ID: \(id)")
///     }
///
/// - Note: The `@unchecked Sendable` conformance is safe because the underlying value is immutable and only `Sendable` values can be stored.
/// - SeeAlso: ``JourneyStep``
public struct AnyHashableSendable: Hashable, @unchecked Sendable {
    private let value: AnyHashable

    /// Creates a type-erased hashable sendable value.
    ///
    /// - Parameter value: The value to wrap, must be both `Hashable` and `Sendable`
    public init(_ value: some Hashable & Sendable) {
        self.value = AnyHashable(value)
    }

    /// Attempts to retrieve the underlying value as the specified type.
    ///
    /// - Parameter type: The expected type of the value
    /// - Returns: The value cast to the specified type, or `nil` if the cast fails
    public func value<T>(as _: T.Type) -> T? {
        value.base as? T
    }
}

extension AnyHashableSendable: ExpressibleByStringLiteral {
    /// Creates an instance from a string literal.
    ///
    /// Enables using string literals directly in parameter dictionaries:
    ///
    ///     let params: [String: AnyHashableSendable] = ["key": "value"]
    ///
    /// - Parameter value: The string literal value
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension AnyHashableSendable: ExpressibleByIntegerLiteral {
    /// Creates an instance from an integer literal.
    ///
    /// Enables using integer literals directly in parameter dictionaries:
    ///
    ///     let params: [String: AnyHashableSendable] = ["count": 42]
    ///
    /// - Parameter value: The integer literal value
    public init(integerLiteral value: Int) {
        self.init(value)
    }
}

extension AnyHashableSendable: ExpressibleByFloatLiteral {
    /// Creates an instance from a floating-point literal.
    ///
    /// Enables using double literals directly in parameter dictionaries:
    ///
    ///     let params: [String: AnyHashableSendable] = ["rating": 4.5]
    ///
    /// - Parameter value: The double literal value
    public init(floatLiteral value: Double) {
        self.init(value)
    }
}

extension AnyHashableSendable: ExpressibleByBooleanLiteral {
    /// Creates an instance from a boolean literal.
    ///
    /// Enables using boolean literals directly in parameter dictionaries:
    ///
    ///     let params: [String: AnyHashableSendable] = ["premium": true]
    ///
    /// - Parameter value: The boolean literal value
    public init(booleanLiteral value: Bool) {
        self.init(value)
    }
}

extension AnyHashableSendable: CustomStringConvertible {
    /// A textual representation of the wrapped value.
    public var description: String {
        String(describing: value.base)
    }
}
