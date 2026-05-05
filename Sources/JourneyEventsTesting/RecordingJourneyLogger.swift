//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents
import os

/// Spy implementation of ``JourneyLogger`` that records every call for assertions.
///
/// ``RecordingJourneyLogger`` is a thread-safe spy intended for tests, demos, and
/// other diagnostic scenarios. It captures every step, evaluation, reset, and error
/// it receives, exposing the captured values through synchronous read-only properties.
///
/// All mutable state is guarded by an `OSAllocatedUnfairLock`, so the logger is safe
/// to share across tasks without unchecked-Sendable escape hatches.
///
/// ## Usage
///
///     let logger = RecordingJourneyLogger()
///     await tracker.recordStep("article_viewed")
///     #expect(logger.recordedSteps.map(\.name) == ["article_viewed"])
///
public final class RecordingJourneyLogger: JourneyLogger, Sendable {
	private struct State {
		var steps: [JourneyStep] = []
		var evaluations: [PolicyEvaluation] = []
		var resets: [String] = []
		var errorMessages: [String] = []
	}

	private let state = OSAllocatedUnfairLock<State>(initialState: State())

	/// Creates a new recording journey logger.
	public init() {}

	/// All steps received by ``logStepRecorded(_:)``, in the order they arrived.
	public var recordedSteps: [JourneyStep] {
		state.withLock(\.steps)
	}

	/// All evaluations received by ``logPolicyEvaluated(_:)``, in the order they arrived.
	public var evaluations: [PolicyEvaluation] {
		state.withLock(\.evaluations)
	}

	/// All policy IDs received by ``logPolicyReset(policyID:)``, in the order they arrived.
	public var resets: [String] {
		state.withLock(\.resets)
	}

	/// All error messages received by ``logError(_:error:)``, in the order they arrived.
	public var errorMessages: [String] {
		state.withLock(\.errorMessages)
	}

	/// Empties every recorded buffer.
	public func clear() {
		state.withLock { $0 = State() }
	}

	public func logStepRecorded(_ step: JourneyStep) {
		state.withLock { $0.steps.append(step) }
	}

	public func logPolicyEvaluated(_ evaluation: PolicyEvaluation) {
		state.withLock { $0.evaluations.append(evaluation) }
	}

	public func logPolicyReset(policyID: String) {
		state.withLock { $0.resets.append(policyID) }
	}

	public func logError(_ message: String, error _: Error?) {
		state.withLock { $0.errorMessages.append(message) }
	}
}
