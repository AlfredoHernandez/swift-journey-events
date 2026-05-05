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
/// - Note: Parameters support `String`, `Int`, `Double`, `Bool`, and `Date` values via ``AnyHashableSendable``.
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
	/// Parameters carry ``AnyHashableSendable`` values, a closed enum over the
	/// statically `Sendable` scalars supported by step metadata.
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

/// A closed, statically `Sendable` value used in ``JourneyStep`` parameter dictionaries.
///
/// ``AnyHashableSendable`` is a finite enum over the scalar types journey metadata is allowed
/// to carry. Replacing the previous type-erased wrapper with a closed enum removes the
/// unchecked-Sendable escape hatch: every case is built from a value the compiler already
/// knows is `Sendable`, so the type is safely concurrent without manual review.
///
/// ## Supported cases
///
/// - ``string(_:)`` — UTF-8 text
/// - ``int(_:)`` — signed 64-bit integers
/// - ``double(_:)`` — IEEE 754 doubles
/// - ``bool(_:)`` — booleans
/// - ``date(_:)`` — `Foundation.Date`
///
/// ## Usage
///
/// Build values explicitly via cases or rely on the literal conformances for ergonomic
/// dictionaries:
///
///     let step = JourneyStep(
///         name: "item_viewed",
///         parameters: [
///             "id": "line_1",        // ExpressibleByStringLiteral
///             "count": 5,            // ExpressibleByIntegerLiteral
///             "premium": true,       // ExpressibleByBooleanLiteral
///             "rating": 4.5,         // ExpressibleByFloatLiteral
///             "viewed_at": .date(Date()),
///         ]
///     )
///
/// Retrieve typed values either by switching on the case or by calling ``value(as:)``:
///
///     if case let .string(id) = step.parameters["id"] {
///         print("ID: \(id)")
///     }
///
///     if let id = step.parameters["id"]?.value(as: String.self) {
///         print("ID: \(id)")
///     }
///
/// - SeeAlso: ``JourneyStep``
public enum AnyHashableSendable: Hashable, Sendable {
	case string(String)
	case int(Int)
	case double(Double)
	case bool(Bool)
	case date(Date)
}

public extension AnyHashableSendable {
	/// Attempts to retrieve the underlying scalar as the requested type.
	///
	/// Returns the wrapped value when `T` matches the case payload, otherwise `nil`.
	/// Provided for source-compatibility with the previous type-erased wrapper; new
	/// call sites should prefer pattern matching on the case directly.
	func value<T>(as _: T.Type) -> T? {
		switch self {
		case let .string(value): value as? T
		case let .int(value): value as? T
		case let .double(value): value as? T
		case let .bool(value): value as? T
		case let .date(value): value as? T
		}
	}
}

extension AnyHashableSendable: ExpressibleByStringLiteral {
	/// Creates a ``string(_:)`` value from a string literal.
	public init(stringLiteral value: String) {
		self = .string(value)
	}
}

extension AnyHashableSendable: ExpressibleByIntegerLiteral {
	/// Creates an ``int(_:)`` value from an integer literal.
	public init(integerLiteral value: Int) {
		self = .int(value)
	}
}

extension AnyHashableSendable: ExpressibleByFloatLiteral {
	/// Creates a ``double(_:)`` value from a float literal.
	public init(floatLiteral value: Double) {
		self = .double(value)
	}
}

extension AnyHashableSendable: ExpressibleByBooleanLiteral {
	/// Creates a ``bool(_:)`` value from a boolean literal.
	public init(booleanLiteral value: Bool) {
		self = .bool(value)
	}
}

extension AnyHashableSendable: CustomStringConvertible {
	/// A textual representation of the wrapped value.
	public var description: String {
		switch self {
		case let .string(value): value
		case let .int(value): String(value)
		case let .double(value): String(value)
		case let .bool(value): String(value)
		case let .date(value): ISO8601DateFormatter().string(from: value)
		}
	}
}
