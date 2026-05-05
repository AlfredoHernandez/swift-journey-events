//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents

/// Pre-armed step sequences ready to feed into a journey-step repository.
public enum JourneyFixtures {
	/// `n` repetitions of the same step name with monotonically increasing timestamps.
	public static func repeating(_ stepName: String, count: Int, startingAt: Int64 = 0) -> [JourneyStep] {
		(0 ..< count).map { offset in
			JourneyStep.make(name: stepName, at: startingAt + Int64(offset))
		}
	}

	/// A strictly-ordered sequence of distinct step names, one per millisecond.
	public static func sequence(_ names: [String], startingAt: Int64 = 0) -> [JourneyStep] {
		names.enumerated().map { offset, name in
			JourneyStep.make(name: name, at: startingAt + Int64(offset))
		}
	}
}
