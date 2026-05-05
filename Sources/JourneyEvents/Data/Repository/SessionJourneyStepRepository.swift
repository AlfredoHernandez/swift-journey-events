//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Production-ready, non-persistent implementation of ``JourneyStepRepository``.
///
/// Records the chronological history and per-step counters of journey steps for the lifetime
/// of a single app session. All data is lost when the app terminates or the instance is
/// deallocated.
///
/// ## Overview
///
/// The repository maintains two structures:
/// - A chronologically ordered history of all recorded steps (used for sequence matching).
/// - A name-keyed counter map for fast occurrence look-ups.
///
/// ## When Used
///
/// Use this implementation in production wiring whenever step history should reset between
/// launches — for example, when sequence matching only needs to reason about the current
/// session.
///
/// ## Memory Management
///
/// `stepHistory` grows unbounded across the session. For long-running apps with many step
/// recordings, call ``clearHistory()`` periodically (e.g., after sequence completion or user
/// logout) to reclaim memory.
///
/// ## Thread Safety
///
/// Thread-safe via Swift actor isolation. All methods can be called concurrently without
/// additional synchronization.
///
/// ## Example
///
///     let repository = SessionJourneyStepRepository()
///     await repository.recordStep(JourneyStep(name: "article_viewed"))
///     let count = await repository.getStepCount(stepName: "article_viewed")
///     // count == 1
///
/// - Note: This is the production analogue of the test-only
///   ``InMemoryJourneyStepRepository`` shipped in `JourneyEventsTesting`.
/// - SeeAlso: ``JourneyStepRepository``
/// - SeeAlso: ``JourneyStep``
public actor SessionJourneyStepRepository: JourneyStepRepository {
	private var stepHistory: [JourneyStep] = []
	private var stepCounts: [String: Int] = [:]

	/// Creates a new session-scoped journey step repository.
	public init() {}

	public func recordStep(_ step: JourneyStep) {
		stepHistory.append(step)
		stepCounts[step.name, default: 0] += 1
	}

	public func getStepCount(stepName: String) -> Int {
		stepCounts[stepName] ?? 0
	}

	public func getStepHistory() -> [JourneyStep] {
		stepHistory
	}

	public func getRecentSteps(limit: Int) -> [JourneyStep] {
		// Guard the negative case before falling through to `suffix(_:)`, which traps
		// on negative `maxLength` (`_precondition(maxLength >= 0)` in stdlib).
		guard limit > 0 else { return [] }
		if stepHistory.count <= limit {
			return stepHistory
		} else {
			return Array(stepHistory.suffix(limit))
		}
	}

	public func clearHistory() {
		stepHistory.removeAll()
		// Counts intentionally retained: they back persistent-style policies that read
		// step counts independently of history length.
	}
}
