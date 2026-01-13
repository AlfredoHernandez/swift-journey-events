//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Evaluates event policies to determine if an action should be triggered.
///
/// Checks the current journey state against the specified policy and determines
/// if the conditions are met to trigger an action.
///
/// **Evaluation Flow:**
/// 1. If cooldown enabled (> 0): Check if cooldown period has expired
/// 2. Check if threshold is reached (counter >= threshold)
/// 3. If action should trigger: Reset counter and save timestamp (for cooldown)
public final class EvaluateEventPolicy: Sendable {
    private static let millisPerSecond: Int64 = 1000
    private static let millisPerMinute: Int64 = 60000

    private let eventStateRepository: EventStateRepository
    private let logger: JourneyLogger
    private let timeProvider: TimeProvider

    public init(
        eventStateRepository: EventStateRepository,
        logger: JourneyLogger,
        timeProvider: TimeProvider,
    ) {
        self.eventStateRepository = eventStateRepository
        self.logger = logger
        self.timeProvider = timeProvider
    }

    /// Evaluates an event policy.
    ///
    /// - Parameter policy: The policy to evaluate
    /// - Returns: `PolicyEvaluation` with the evaluation result
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

    /// Evaluates if cooldown period is still active.
    ///
    /// - Returns: `PolicyEvaluation` with shouldTriggerAction=false if cooldown is active,
    ///            nil if cooldown expired or no previous action
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

    /// Resets policy counter and saves current timestamp for cooldown tracking.
    private func resetCounterAndSaveTimestamp(policy: EventPolicy) async {
        await eventStateRepository.resetCount(policyID: policy.id)

        if policy.cooldownMinutes > 0 {
            await eventStateRepository.setLastActionTriggeredTimestamp(
                policyID: policy.id,
                timestamp: timeProvider.currentTimeMillis(),
            )
        }
    }

    /// Builds human-readable reason for cooldown state.
    private func buildCooldownReason(
        elapsedMinutes: Int64,
        totalMinutes: Int,
        remainingMinutes: Int64,
        remainingSeconds: Int64,
    ) -> String {
        "Cooldown active (\(elapsedMinutes)/\(totalMinutes) min elapsed, " +
            "\(remainingMinutes)m \(remainingSeconds)s remaining)"
    }

    /// Builds human-readable reason for threshold evaluation.
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

    /// Gets the current counter value for a policy.
    ///
    /// For single-step patterns: Returns the occurrence count
    /// For multi-step patterns: Returns the sequence completion count
    private func getCurrentCount(policy: EventPolicy) async -> Int {
        await eventStateRepository.getCount(policyID: policy.id)
    }
}
