//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Evaluates event policies to determine if an action should be triggered.
///
/// This use case checks the current journey state against a specified policy
/// and determines if all conditions are met to trigger the associated action.
/// It handles threshold checking, cooldown enforcement, and state management.
///
/// ## Overview
///
/// ``EvaluateEventPolicy`` performs a multi-step evaluation:
/// 1. **Cooldown Check**: If cooldown is enabled, verifies enough time has passed since last action
/// 2. **Threshold Check**: Verifies the pattern counter meets or exceeds the threshold
/// 3. **State Update**: If action should trigger, resets counter and records timestamp
///
/// ## Evaluation Workflow
///
/// The evaluation follows this decision tree:
///
///     Has cooldown? → Yes → Is cooldown expired?
///                              ↓ No: Return false with time remaining
///                              ↓ Yes: Continue to threshold check
///                   → No  → Continue to threshold check
///
///     Threshold reached? → Yes → Reset counter, record timestamp, return true
///                        → No  → Return false with remaining count
///
/// ## Usage
///
/// Create the use case with required dependencies:
///
///     let evaluatePolicy = EvaluateEventPolicy(
///         eventStateRepository: stateRepo,
///         logger: logger,
///         timeProvider: timeProvider
///     )
///
/// Evaluate a policy when you need to check if an action should trigger:
///
///     let evaluation = await evaluatePolicy(myPolicy)
///     if evaluation.shouldTriggerAction {
///         // Perform the action
///         showAd(evaluation.actionKey)
///     }
///
/// Check evaluation details for debugging:
///
///     print(evaluation.reason)
///     // "Threshold reached (5/5)" or
///     // "Cooldown active (5/15 min elapsed, 10m 0s remaining)"
///
/// ## Thread Safety
///
/// This use case is thread-safe and can be called concurrently. State updates
/// are atomic and handled by the underlying ``EventStateRepository``.
///
/// - Note: Automatically resets counters and records timestamps when actions trigger.
/// - SeeAlso: ``PolicyEvaluation`` for evaluation results
/// - SeeAlso: ``EventPolicy`` for policy configuration
/// - SeeAlso: ``TimeProvider`` for cooldown time calculations
public final class EvaluateEventPolicy: Sendable {
    private static let millisPerSecond: Int64 = 1000
    private static let millisPerMinute: Int64 = 60000

    private let eventStateRepository: EventStateRepository
    private let logger: JourneyLogger
    private let timeProvider: TimeProvider

    /// Creates a new policy evaluator.
    ///
    /// - Parameters:
    ///   - eventStateRepository: Repository for accessing policy state and counters
    ///   - logger: Logger for recording evaluation results
    ///   - timeProvider: Provider for current time (used in cooldown calculations)
    public init(
        eventStateRepository: EventStateRepository,
        logger: JourneyLogger,
        timeProvider: TimeProvider,
    ) {
        self.eventStateRepository = eventStateRepository
        self.logger = logger
        self.timeProvider = timeProvider
    }

    /// Evaluates an event policy against current journey state.
    ///
    /// This method performs the complete evaluation workflow including cooldown
    /// checking, threshold validation, and state updates. Results are logged
    /// using the configured ``JourneyLogger``.
    ///
    /// If the action should trigger (threshold reached and cooldown expired),
    /// this method automatically:
    /// - Resets the policy counter to 0
    /// - Records the current timestamp for cooldown tracking
    /// - Logs the policy reset event
    ///
    /// - Parameter policy: The policy to evaluate
    /// - Returns: A ``PolicyEvaluation`` containing the decision and context
    ///
    /// - Complexity: O(1) - Constant time lookups and updates
    public func callAsFunction(_ policy: EventPolicy) async -> PolicyEvaluation {
        // Step 1: Check cooldown (if enabled)
        if policy.cooldownMinutes > 0 {
            if let cooldownEvaluation = await evaluateCooldownState(policy: policy) {
                return cooldownEvaluation
            }
        }

        // Step 2: Check threshold (existing logic)
        let currentCount = await getCurrentCount(policy: policy)
        let thresholdReached = currentCount >= policy.threshold

        // Step 3: Handle result
        if thresholdReached {
            await resetCounterAndSaveTimestamp(policy: policy)
            logger.logPolicyReset(policyID: policy.id)
        }

        let reason = buildEvaluationReason(
            thresholdReached: thresholdReached,
            currentCount: currentCount,
            threshold: policy.threshold,
        )

        return PolicyEvaluation(
            shouldTriggerAction: thresholdReached,
            policyID: policy.id,
            actionKey: policy.actionKey,
            currentCount: currentCount,
            threshold: policy.threshold,
            reason: reason,
        )
    }

    /// Evaluates if the cooldown period is still active for a policy.
    ///
    /// - Parameter policy: The policy with cooldown to check
    /// - Returns: A ``PolicyEvaluation`` with `shouldTriggerAction = false` if cooldown is active,
    ///            or `nil` if cooldown has expired or no previous action exists
    private func evaluateCooldownState(policy: EventPolicy) async -> PolicyEvaluation? {
        guard let lastActionTimestamp = await eventStateRepository.getLastActionTriggeredTimestamp(
            policyID: policy.id,
        ) else {
            return nil // No previous action, allow triggering
        }

        let currentTimeMillis = timeProvider.currentTimeMillis()
        let elapsedTimeMillis = currentTimeMillis - lastActionTimestamp
        let elapsedMinutes = elapsedTimeMillis / Self.millisPerMinute

        if elapsedMinutes >= Int64(policy.cooldownMinutes) {
            return nil // Cooldown expired, continue with threshold check
        }

        // Cooldown still active, calculate remaining time
        let currentCount = await getCurrentCount(policy: policy)
        let remainingTimeMillis = (Int64(policy.cooldownMinutes) * Self.millisPerMinute) - elapsedTimeMillis
        let remainingMinutes = remainingTimeMillis / Self.millisPerMinute
        let remainingSeconds = (remainingTimeMillis % Self.millisPerMinute) / Self.millisPerSecond

        let cooldownReason = buildCooldownReason(
            elapsedMinutes: elapsedMinutes,
            totalMinutes: policy.cooldownMinutes,
            remainingMinutes: remainingMinutes,
            remainingSeconds: remainingSeconds,
        )

        return PolicyEvaluation(
            shouldTriggerAction: false,
            policyID: policy.id,
            actionKey: policy.actionKey,
            currentCount: currentCount,
            threshold: policy.threshold,
            reason: cooldownReason,
        )
    }

    /// Resets the policy counter and saves the current timestamp for cooldown tracking.
    ///
    /// Called automatically when an action is triggered to prepare for the next cycle.
    ///
    /// - Parameter policy: The policy whose state should be reset
    private func resetCounterAndSaveTimestamp(policy: EventPolicy) async {
        await eventStateRepository.resetCount(policyID: policy.id)

        if policy.cooldownMinutes > 0 {
            await eventStateRepository.setLastActionTriggeredTimestamp(
                policyID: policy.id,
                timestamp: timeProvider.currentTimeMillis(),
            )
        }
    }

    /// Builds a human-readable reason string for cooldown state.
    ///
    /// - Parameters:
    ///   - elapsedMinutes: Minutes elapsed since last action
    ///   - totalMinutes: Total cooldown period in minutes
    ///   - remainingMinutes: Minutes remaining in cooldown period
    ///   - remainingSeconds: Seconds remaining (in addition to minutes)
    /// - Returns: Formatted string describing cooldown state
    private func buildCooldownReason(
        elapsedMinutes: Int64,
        totalMinutes: Int,
        remainingMinutes: Int64,
        remainingSeconds: Int64,
    ) -> String {
        "Cooldown active (\(elapsedMinutes)/\(totalMinutes) min elapsed, " +
            "\(remainingMinutes)m \(remainingSeconds)s remaining)"
    }

    /// Builds a human-readable reason string for threshold evaluation.
    ///
    /// - Parameters:
    ///   - thresholdReached: Whether the threshold was reached
    ///   - currentCount: Current counter value
    ///   - threshold: Required threshold value
    /// - Returns: Formatted string describing threshold state
    private func buildEvaluationReason(
        thresholdReached: Bool,
        currentCount: Int,
        threshold: Int,
    ) -> String {
        if thresholdReached {
            return "Threshold reached (\(currentCount)/\(threshold))"
        } else {
            let remaining = threshold - currentCount
            return "Threshold not reached (\(currentCount)/\(threshold), \(remaining) remaining)"
        }
    }

    /// Retrieves the current counter value for a policy.
    ///
    /// - Parameter policy: The policy whose counter to retrieve
    /// - Returns: Current count (step occurrences for single-step patterns,
    ///            sequence completions for multi-step patterns)
    private func getCurrentCount(policy: EventPolicy) async -> Int {
        await eventStateRepository.getCount(policyID: policy.id)
    }
}
