//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Main entry point for the journey-events module.
///
/// This class orchestrates user journey tracking and event policy evaluation.
///
/// **Policy Trigger Notifications:**
/// Subscribe to `policyTriggers` to receive notifications when policies are triggered:
/// ```swift
/// for await evaluation in eventTracker.policyTriggers {
///     // Handle triggered policy
///     showAd(evaluation.actionKey)
/// }
/// ```
///
/// **Simplified Usage (Recommended):**
/// ```swift
/// // Record step - policies are automatically checked and listeners notified
/// await eventTracker.recordStep("line_viewed", parameters: ["id": "linea_1"])
/// ```
///
/// **Manual Usage (Advanced):**
/// ```swift
/// // Just record step without checking
/// await eventTracker.recordStepOnly("line_viewed", parameters: ["id": "linea_1"])
///
/// // Check policies manually later
/// let evaluation = await eventTracker.checkPoliciesForStep("line_viewed")
/// ```
public final class EventTracker: @unchecked Sendable {
    private let trackJourneyStep: TrackJourneyStep
    private let evaluateEventPolicy: EvaluateEventPolicy
    private let policyProvider: PolicyProvider
    private let logger: JourneyLogger

    /// Continuation for emitting policy trigger events.
    private var continuation: AsyncStream<PolicyEvaluation>.Continuation?

    /// Public stream of policy trigger events.
    ///
    /// Emits whenever a policy threshold is reached and an action should be triggered.
    /// Subscribe to this stream to handle policy triggers (e.g., show ads, log analytics).
    ///
    /// Example:
    /// ```swift
    /// for await evaluation in eventTracker.policyTriggers {
    ///     if evaluation.shouldTriggerAction {
    ///         showAd(evaluation.actionKey)
    ///     }
    /// }
    /// ```
    public let policyTriggers: AsyncStream<PolicyEvaluation>

    /// Index mapping step names to their associated policy IDs.
    /// Built lazily for fast lookup when checking policies for a specific step.
    ///
    /// Maps the last step of each pattern to its policy IDs:
    /// - Single-step patterns: Maps the only step to the policy
    /// - Multi-step patterns: Maps the final step to the policy (evaluated only on completion)
    private lazy var stepToPolicyIDsIndex: [String: [String]] = Dictionary(
        grouping: policyProvider.getActivePolicies().map { policy in
            (stepName: policy.pattern.lastStep, policyID: policy.id)
        },
        by: { $0.stepName },
    ).mapValues { $0.map(\.policyID) }

    public init(
        trackJourneyStep: TrackJourneyStep,
        evaluateEventPolicy: EvaluateEventPolicy,
        policyProvider: PolicyProvider,
        logger: JourneyLogger,
    ) {
        self.trackJourneyStep = trackJourneyStep
        self.evaluateEventPolicy = evaluateEventPolicy
        self.policyProvider = policyProvider
        self.logger = logger

        var continuation: AsyncStream<PolicyEvaluation>.Continuation?
        policyTriggers = AsyncStream(bufferingPolicy: .bufferingNewest(10)) { cont in
            continuation = cont
        }
        self.continuation = continuation
    }

    /// Records a user journey step and automatically checks related policies.
    ///
    /// This is the recommended method that combines both recording and checking
    /// in a single call, simplifying the API and ensuring policies are always checked.
    ///
    /// - Parameters:
    ///   - stepName: Name of the step (e.g., "line_viewed", "station_selected")
    ///   - parameters: Optional parameters with context
    /// - Returns: `PolicyEvaluation` if a policy threshold was reached, nil otherwise
    @discardableResult
    public func recordStep(
        _ stepName: String,
        parameters: [String: AnyHashableSendable] = [:],
    ) async -> PolicyEvaluation? {
        do {
            let step = JourneyStep(name: stepName, parameters: parameters)
            await trackJourneyStep(step)
            logger.logStepRecorded(step)

            // Automatically check policies related to this step
            if let evaluation = try await checkPoliciesForStep(stepName) {
                // Emit to listeners if action should be triggered
                if evaluation.shouldTriggerAction {
                    continuation?.yield(evaluation)
                }
                return evaluation
            }
            return nil
        } catch {
            logger.logError("Error recording step: \(stepName)", error: error)
            return nil
        }
    }

    /// Records a user journey step WITHOUT checking policies.
    ///
    /// Use this only in advanced scenarios where you want to manually control
    /// when policies are checked. For most cases, use `recordStep` instead.
    ///
    /// - Parameters:
    ///   - stepName: Name of the step (e.g., "line_viewed", "station_selected")
    ///   - parameters: Optional parameters with context
    public func recordStepOnly(
        _ stepName: String,
        parameters: [String: AnyHashableSendable] = [:],
    ) async {
        let step = JourneyStep(name: stepName, parameters: parameters)
        await trackJourneyStep(step)
        logger.logStepRecorded(step)
    }

    /// Checks only the policies related to a specific step name.
    ///
    /// This is more efficient because it only evaluates policies that are
    /// associated with the given step, rather than all policies.
    ///
    /// - Parameter stepName: The step name to check policies for
    /// - Returns: `PolicyEvaluation` of the first action that should trigger, or nil if none
    public func checkPoliciesForStep(_ stepName: String) async throws -> PolicyEvaluation? {
        // Get policy IDs related to this step
        let relatedPolicyIDs = stepToPolicyIDsIndex[stepName] ?? []

        // Get the actual policy objects
        let policies = policyProvider.getActivePolicies()
            .filter { relatedPolicyIDs.contains($0.id) }

        // Evaluate only the related policies
        var evaluations: [PolicyEvaluation] = []
        for policy in policies {
            let evaluation = await evaluateEventPolicy(policy)
            logger.logPolicyEvaluated(evaluation)
            evaluations.append(evaluation)
        }

        return evaluations.first { $0.shouldTriggerAction }
    }

    deinit {
        continuation?.finish()
    }
}
