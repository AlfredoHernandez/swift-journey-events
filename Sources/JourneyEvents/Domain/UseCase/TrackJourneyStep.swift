//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Tracks user journey steps throughout the application.
///
/// This use case is the core entry point for recording user actions. It stores
/// each step in history and automatically increments relevant policy counters
/// when patterns are matched.
///
/// ## Overview
///
/// ``TrackJourneyStep`` performs three key functions:
/// 1. Records each step in the journey history
/// 2. Identifies which policies are affected by the current step
/// 3. Updates policy counters when patterns are fulfilled
///
/// ## Pattern Handling
///
/// The use case handles different pattern types differently:
///
/// **Single-step patterns**: Counter increments immediately on each occurrence
///
///     // Policy: Show ad after 5 article views
///     // Pattern: ["article_viewed"], threshold: 5
///     trackStep(JourneyStep(name: "article_viewed"))  // Counter: 1/5
///     trackStep(JourneyStep(name: "article_viewed"))  // Counter: 2/5
///     trackStep(JourneyStep(name: "article_viewed"))  // Counter: 3/5
///
/// **Multi-step patterns**: Validates sequence completion before incrementing
///
///     // Policy: Show tutorial after onboarding
///     // Pattern: ["welcome", "profile", "home"], threshold: 1
///     trackStep(JourneyStep(name: "welcome"))   // Counter: 0/1 (incomplete)
///     trackStep(JourneyStep(name: "profile"))   // Counter: 0/1 (incomplete)
///     trackStep(JourneyStep(name: "home"))      // Counter: 1/1 (complete!)
///
/// ## Performance
///
/// The use case uses an internal index for O(1) policy lookup. Only policies
/// whose pattern ends with the current step are evaluated, making it efficient
/// even with many policies.
///
/// ## Usage
///
/// Create the use case with required dependencies:
///
///     let trackStep = TrackJourneyStep(
///         journeyStepRepository: journeyRepo,
///         eventStateRepository: stateRepo,
///         policyProvider: provider,
///         sequenceMatcher: matcher
///     )
///
/// Call it whenever a user action occurs:
///
///     await trackStep(JourneyStep(name: "article_viewed"))
///     await trackStep(JourneyStep(name: "article_viewed", parameters: ["id": "123"]))
///
/// - Note: This use case is thread-safe and can be called concurrently.
/// - SeeAlso: ``JourneyStep`` for creating journey steps
/// - SeeAlso: ``EventPolicy`` for defining policies
/// - SeeAlso: ``SequenceMatcher`` for sequence validation logic
public final class TrackJourneyStep: Sendable {
    private let journeyStepRepository: JourneyStepRepository
    private let eventStateRepository: EventStateRepository
    private let policyProvider: PolicyProvider
    private let sequenceMatcher: SequenceMatcher

    /// Index mapping step names to their associated policies.
    ///
    /// Built once at initialization for O(1) lookup instead of O(n) filtering.
    /// Maps the last step of each pattern to its complete policy:
    /// - Single-step: Maps the only step (increments immediately)
    /// - Multi-step: Maps the final step (validates sequence before incrementing)
    ///
    /// Example: Policy with pattern ["A", "B", "C"] is indexed under "C"
    private let stepToPoliciesIndex: [String: [EventPolicy]]

    /// Creates a new journey step tracker.
    ///
    /// - Parameters:
    ///   - journeyStepRepository: Repository for storing step history
    ///   - eventStateRepository: Repository for storing policy state and counters
    ///   - policyProvider: Provider for active event policies
    ///   - sequenceMatcher: Matcher for validating multi-step sequences
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
    /// This method performs the complete tracking workflow:
    /// 1. Records the step in journey history
    /// 2. Finds policies where this step is the last in the pattern
    /// 3. For each policy:
    ///    - Single-step: Increments counter immediately
    ///    - Multi-step: Validates sequence completion, then increments if complete
    ///
    /// For multi-step patterns, prevents double-counting by tracking the timestamp
    /// of the first step in each counted sequence.
    ///
    /// - Parameter step: The journey step to record
    ///
    /// - Complexity: O(p) where p is the number of policies ending with this step
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
    /// Retrieves recent steps from history and checks if they match the expected
    /// sequence according to the policy's strict/loose mode using ``SequenceMatcher``.
    ///
    /// - Parameter policy: The policy with a multi-step pattern to validate
    /// - Returns: Validation result with match status and first step timestamp
    ///
    /// - Complexity: O(n) where n is the number of recent steps retrieved
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

/// Result of sequence validation for multi-step patterns.
///
/// Used internally by ``TrackJourneyStep`` to track sequence matches
/// and prevent double-counting of completed sequences.
private struct SequenceValidationResult {
    /// Indicates whether the expected sequence was found in recent steps.
    let matches: Bool

    /// The timestamp of the first step in the matched sequence.
    ///
    /// Used to prevent double-counting by tracking which sequence completions
    /// have already been counted. `nil` if no sequence was matched.
    let firstStepTimestamp: Int64?
}
