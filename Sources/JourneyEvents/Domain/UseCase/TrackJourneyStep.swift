//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Tracks user journey steps throughout the application.
///
/// Stores steps in history and increments policy counters when patterns are matched.
///
/// **Pattern Handling:**
/// - **Single-step patterns**: Increments counter immediately on each occurrence
/// - **Multi-step patterns**: Validates sequence completion before incrementing
public final class TrackJourneyStep: Sendable {
    private let journeyStepRepository: JourneyStepRepository
    private let eventStateRepository: EventStateRepository
    private let policyProvider: PolicyProvider
    private let sequenceMatcher: SequenceMatcher

    /// Index mapping step names to their associated policies.
    /// Built once at initialization for O(1) lookup instead of O(n) filtering.
    ///
    /// Maps the last step of each pattern to its complete policy:
    /// - Single-step: Maps the only step → increments immediately
    /// - Multi-step: Maps the final step → validates sequence before incrementing
    private let stepToPoliciesIndex: [String: [EventPolicy]]

    public init(
        journeyStepRepository: JourneyStepRepository,
        eventStateRepository: EventStateRepository,
        policyProvider: PolicyProvider,
        sequenceMatcher: SequenceMatcher,
    ) {
        self.journeyStepRepository = journeyStepRepository
        self.eventStateRepository = eventStateRepository
        self.policyProvider = policyProvider
        self.sequenceMatcher = sequenceMatcher

        // Build index at initialization
        stepToPoliciesIndex = Dictionary(
            grouping: policyProvider.getActivePolicies(),
            by: { $0.pattern.lastStep },
        )
    }

    /// Records a journey step and evaluates associated policies.
    ///
    /// **Flow:**
    /// 1. Records step in history
    /// 2. Finds policies where this step is the last in the pattern
    /// 3. For each policy:
    ///    - If single-step: Increments counter immediately
    ///    - If multi-step: Validates sequence completion, then increments
    ///
    /// - Parameter step: The journey step to record
    public func callAsFunction(_ step: JourneyStep) async {
        // Step 1: Record in history (always)
        await journeyStepRepository.recordStep(step)

        // Step 2: Find policies that end with this step
        guard let policies = stepToPoliciesIndex[step.name] else { return }

        // Step 3: Evaluate each policy
        for policy in policies {
            let shouldIncrement: Bool

            if policy.pattern.isSingleStep {
                // Single-step pattern: always increment
                shouldIncrement = true
            } else {
                // Multi-step pattern: validate sequence completion and check timestamp
                let result = await validateSequenceCompletion(policy: policy)

                if result.matches {
                    // Only count if this sequence completion is new (not already counted)
                    // Check if the FIRST step of the found sequence is newer than the last counted one
                    let lastCountedTimestamp = await eventStateRepository.getLastCountedStepTimestamp(
                        policyID: policy.id,
                    )
                    shouldIncrement = lastCountedTimestamp == nil ||
                        result.firstStepTimestamp! > lastCountedTimestamp!
                } else {
                    shouldIncrement = false
                }
            }

            if shouldIncrement {
                await eventStateRepository.incrementCount(policyID: policy.id)

                // For multi-step patterns, save the timestamp of the first step of the sequence
                if !policy.pattern.isSingleStep {
                    let result = await validateSequenceCompletion(policy: policy)
                    if result.matches, let timestamp = result.firstStepTimestamp {
                        await eventStateRepository.setLastCountedStepTimestamp(
                            policyID: policy.id,
                            timestamp: timestamp,
                        )
                    }
                }
            }
        }
    }

    /// Validates if a multi-step sequence pattern has been completed.
    ///
    /// Gets recent steps and checks if they match the expected sequence
    /// according to the policy's strict/loose mode.
    ///
    /// - Parameter policy: The policy with a multi-step pattern to validate
    /// - Returns: SequenceValidationResult with match status and first step timestamp
    private func validateSequenceCompletion(policy: EventPolicy) async -> SequenceValidationResult {
        let expectedSequence = policy.pattern.steps
        let limit = expectedSequence.count * 2 // Buffer for loose matching

        // Get recent steps
        let recentSteps = await journeyStepRepository.getRecentSteps(limit: limit)

        // Validate using SequenceMatcher
        let matches = sequenceMatcher.matches(
            recentSteps: recentSteps,
            expectedSequence: expectedSequence,
            strict: policy.pattern.strictSequence,
        )

        if !matches {
            return SequenceValidationResult(matches: false, firstStepTimestamp: nil)
        }

        // Find the timestamp of the first step in the found sequence
        let firstStepName = expectedSequence.first!
        let firstStepTimestamp = recentSteps.first { $0.name == firstStepName }?.timestamp

        return SequenceValidationResult(
            matches: true,
            firstStepTimestamp: firstStepTimestamp,
        )
    }
}

/// Result of sequence validation.
private struct SequenceValidationResult {
    /// Whether the sequence was found
    let matches: Bool

    /// Timestamp of the first step in the found sequence, or nil if not found
    let firstStepTimestamp: Int64?
}
