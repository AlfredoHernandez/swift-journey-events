//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// In-memory implementation of ``JourneyStepRepository``.
///
/// Stores journey step history in memory during the current app session.
/// All history is lost when the app is closed or the instance is deallocated.
///
/// ## Overview
///
/// This repository maintains two data structures:
/// - A chronologically ordered history of all recorded steps
/// - Counter map for tracking individual step occurrences
///
/// The history is used for sequence pattern matching, while counters
/// provide quick access to step occurrence counts.
///
/// ## Usage
///
///     let repository = InMemoryJourneyStepRepository()
///     await repository.recordStep(JourneyStep(name: "article_viewed"))
///     let count = await repository.getStepCount(stepName: "article_viewed")
///     print(count) // Output: 1
///
/// Get recent steps for sequence validation:
///
///     let recent = await repository.getRecentSteps(limit: 5)
///     print(recent.map(\.name)) // ["home", "search", "results", "detail", "article_viewed"]
///
/// ## Memory Management
///
/// The history grows unbounded during the session. For long-running apps with
/// many step recordings, consider calling ``clearHistory()`` periodically to
/// free memory (e.g., after sequence completion or user logout).
///
/// ## Thread Safety
///
/// Thread-safe using Swift actor isolation. All methods can be called
/// concurrently without additional synchronization.
///
/// - Note: All data is lost when the app restarts.
/// - SeeAlso: ``JourneyStepRepository`` for protocol documentation
/// - SeeAlso: ``JourneyStep`` for step structure
public actor InMemoryJourneyStepRepository: JourneyStepRepository {
    /// Chronologically ordered history of all recorded steps.
    private var stepHistory: [JourneyStep] = []

    /// Counter map tracking occurrences of each step name.
    private var stepCounts: [String: Int] = [:]

    /// Creates a new in-memory journey step repository.
    public init() {}

    public func recordStep(_ step: JourneyStep) {
        // Add to history
        stepHistory.append(step)

        // Increment counter
        stepCounts[step.name, default: 0] += 1
    }

    public func getStepCount(stepName: String) -> Int {
        stepCounts[stepName] ?? 0
    }

    public func getStepHistory() -> [JourneyStep] {
        stepHistory
    }

    public func getRecentSteps(limit: Int) -> [JourneyStep] {
        if stepHistory.count <= limit {
            stepHistory
        } else {
            Array(stepHistory.suffix(limit))
        }
    }

    public func clearHistory() {
        stepHistory.removeAll()
        // Note: We don't clear stepCounts because they're used for persistent policies
    }
}
