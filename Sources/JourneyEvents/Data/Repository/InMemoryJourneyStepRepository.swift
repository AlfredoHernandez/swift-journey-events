//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

/// In-memory implementation of `JourneyStepRepository`.
///
/// Stores journey step history during the current app session.
/// Steps are lost when the app is closed.
///
/// Thread-safe using Swift actor isolation.
public actor InMemoryJourneyStepRepository: JourneyStepRepository {
    private var stepHistory: [JourneyStep] = []
    private var stepCounts: [String: Int] = [:]

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
