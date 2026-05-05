//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Foundation
import Testing

struct JourneyStepTests {
	@Test
	func `Init creates step with name and auto-generated timestamp`() {
		let step = JourneyStep(name: "app_started")

		#expect(step.name == "app_started")
		#expect(step.parameters.isEmpty)
		#expect(step.timestamp > 0)
	}

	@Test
	func `Init creates step with parameters dictionary`() {
		let params: [String: AnyHashableSendable] = [
			"id": "line_1",
			"count": 42,
			"premium": true,
			"rating": 4.5,
		]

		let step = JourneyStep(name: "line_viewed", parameters: params)

		#expect(step.name == "line_viewed")
		#expect(step.parameters.count == 4)
		#expect(step.parameters["id"]?.value(as: String.self) == "line_1")
		#expect(step.parameters["count"]?.value(as: Int.self) == 42)
		#expect(step.parameters["premium"]?.value(as: Bool.self) == true)
		#expect(step.parameters["rating"]?.value(as: Double.self) == 4.5)
	}

	@Test
	func `Init creates step with custom timestamp`() {
		let customTimestamp: Int64 = 1_234_567_890_000
		let step = JourneyStep(
			name: "custom_step",
			timestamp: customTimestamp,
		)

		#expect(step.timestamp == customTimestamp)
	}

	@Test
	func `Equatable returns true when steps have same values`() {
		let timestamp: Int64 = 1000
		let params: [String: AnyHashableSendable] = ["id": "123"]

		let step1 = JourneyStep(name: "test", parameters: params, timestamp: timestamp)
		let step2 = JourneyStep(name: "test", parameters: params, timestamp: timestamp)

		#expect(step1 == step2)
	}

	@Test
	func `Equatable returns false when steps have different names`() {
		let timestamp: Int64 = 1000
		let step1 = JourneyStep(name: "step1", timestamp: timestamp)
		let step2 = JourneyStep(name: "step2", timestamp: timestamp)

		#expect(step1 != step2)
	}
}

struct AnyHashableSendableTests {
	@Test
	func `string case exposes wrapped String via value(as:)`() {
		let value: AnyHashableSendable = .string("hello")

		#expect(value.value(as: String.self) == "hello")
		#expect(value.value(as: Int.self) == nil)
	}

	@Test
	func `int case exposes wrapped Int via value(as:)`() {
		let value: AnyHashableSendable = .int(42)

		#expect(value.value(as: Int.self) == 42)
		#expect(value.value(as: String.self) == nil)
	}

	@Test
	func `bool case exposes wrapped Bool via value(as:)`() {
		let value: AnyHashableSendable = .bool(true)

		#expect(value.value(as: Bool.self) == true)
		#expect(value.value(as: Int.self) == nil)
	}

	@Test
	func `double case exposes wrapped Double via value(as:)`() {
		let value: AnyHashableSendable = .double(3.14)

		#expect(value.value(as: Double.self) == 3.14)
		#expect(value.value(as: Int.self) == nil)
	}

	@Test
	func `date case exposes wrapped Date via value(as:)`() {
		let now = Date(timeIntervalSince1970: 1_700_000_000)
		let value: AnyHashableSendable = .date(now)

		#expect(value.value(as: Date.self) == now)
		#expect(value.value(as: String.self) == nil)
	}

	@Test
	func `ExpressibleByStringLiteral creates value from string`() {
		let value: AnyHashableSendable = "test"

		#expect(value.value(as: String.self) == "test")
	}

	@Test
	func `ExpressibleByIntegerLiteral creates value from integer`() {
		let value: AnyHashableSendable = 100

		#expect(value.value(as: Int.self) == 100)
	}

	@Test
	func `ExpressibleByBooleanLiteral creates value from boolean`() {
		let value: AnyHashableSendable = false

		#expect(value.value(as: Bool.self) == false)
	}

	@Test
	func `ExpressibleByFloatLiteral creates value from float`() {
		let value: AnyHashableSendable = 2.5

		#expect(value.value(as: Double.self) == 2.5)
	}

	@Test
	func `Hashable and Equatable conform correctly for values`() {
		let value1: AnyHashableSendable = .string("test")
		let value2: AnyHashableSendable = .string("test")
		let value3: AnyHashableSendable = .string("different")

		#expect(value1 == value2)
		#expect(value1 != value3)

		var set = Set<AnyHashableSendable>()
		set.insert(value1)
		set.insert(value2)

		#expect(set.count == 1)
	}

	@Test
	func `Description returns string representation of wrapped value`() {
		#expect(AnyHashableSendable.string("hello").description == "hello")
		#expect(AnyHashableSendable.int(42).description == "42")
		#expect(AnyHashableSendable.bool(true).description == "true")
	}
}
