//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Default ``JourneyLogger`` that swallows everything.
///
/// Use this in tests, demos, or production builds where journey logging is not needed.
/// Consumers wanting telemetry should provide their own ``JourneyLogger`` adapter
/// (for example, one that bridges to a telemetry pipeline or analytics SDK).
///
/// ## Usage
///
///     let tracker = EventTracker(
///         trackJourneyStep: trackStep,
///         evaluateEventPolicy: evaluatePolicy,
///         policyProvider: provider,
///         logger: NoOpJourneyLogger(),
///     )
public struct NoOpJourneyLogger: JourneyLogger, Sendable {
	/// Creates a new no-op journey logger.
	public init() {}

	public func logStepRecorded(_: JourneyStep) {}
	public func logPolicyEvaluated(_: PolicyEvaluation) {}
	public func logPolicyReset(policyID _: String) {}
	public func logError(_: String, error _: Error?) {}
}
