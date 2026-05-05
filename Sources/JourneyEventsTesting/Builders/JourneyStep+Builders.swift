//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents

public extension JourneyStep {
	/// Creates a ``JourneyStep`` with explicit defaults suitable for tests.
	///
	/// Unlike the production initializer, the timestamp is fixed at `0` by default
	/// so equality assertions are deterministic.
	static func make(
		name: String,
		parameters: [String: AnyHashableSendable] = [:],
		at timestamp: Int64 = 0,
	) -> JourneyStep {
		JourneyStep(name: name, parameters: parameters, timestamp: timestamp)
	}
}
