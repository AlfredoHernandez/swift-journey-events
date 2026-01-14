//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Logger for journey tracking and policy evaluation.
///
/// Provides detailed observability about each user action
/// and decisions made by the event trigger system.
public protocol JourneyLogger: Sendable {
    /// Logs when a new journey step is recorded.
    ///
    /// - Parameter step: The step that was recorded
    func logStepRecorded(_ step: JourneyStep)

    /// Logs when an event trigger policy is evaluated.
    ///
    /// - Parameter evaluation: The evaluation result
    func logPolicyEvaluated(_ evaluation: PolicyEvaluation)

    /// Logs when a policy counter is reset.
    ///
    /// - Parameter policyID: ID of the reset policy
    func logPolicyReset(policyID: String)

    /// Logs system errors.
    ///
    /// - Parameters:
    ///   - message: Error message
    ///   - error: Optional error
    func logError(_ message: String, error: Error?)
}

public extension JourneyLogger {
    /// Logs system errors without an associated error object.
    ///
    /// - Parameter message: Error message
    func logError(_ message: String) {
        logError(message, error: nil)
    }
}
