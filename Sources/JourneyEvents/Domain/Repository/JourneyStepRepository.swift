//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// Repository for tracking user journey steps.
///
/// Stores steps in memory to evaluate sequence patterns
/// and manages counters for individual patterns.
public protocol JourneyStepRepository: Sendable {
    /// Records a new journey step.
    ///
    /// - Stores the step in memory for sequence evaluation
    /// - Increments the counter for the step name if it's a Single pattern
    ///
    /// - Parameter step: The journey step to record
    func recordStep(_ step: JourneyStep) async

    /// Gets the occurrence counter for a specific step.
    ///
    /// - Parameter stepName: Name of the step
    /// - Returns: Number of times the step has occurred
    func getStepCount(stepName: String) async -> Int

    /// Gets the history of steps recorded in memory.
    ///
    /// Used to evaluate sequence patterns.
    ///
    /// - Returns: List of steps in chronological order
    func getStepHistory() async -> [JourneyStep]

    /// Gets the most recent N steps from the history.
    ///
    /// More efficient than `getStepHistory()` when you only need recent steps
    /// for sequence validation. Returns steps in chronological order (oldest first).
    ///
    /// - Parameter limit: Maximum number of recent steps to return
    /// - Returns: List of recent steps in chronological order (oldest first)
    func getRecentSteps(limit: Int) async -> [JourneyStep]

    /// Clears the step history in memory.
    ///
    /// Useful when a sequence is completed or when logging out.
    func clearHistory() async
}
