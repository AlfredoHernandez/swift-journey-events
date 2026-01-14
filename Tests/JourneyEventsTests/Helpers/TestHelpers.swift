//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Foundation

// MARK: - Mock Time Provider

final class MockTimeProvider: TimeProvider, @unchecked Sendable {
    private var _currentTime: Int64 = 0
    private let lock = NSLock()

    var currentTime: Int64 {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _currentTime
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _currentTime = newValue
        }
    }

    func currentTimeMillis() -> Int64 {
        lock.lock()
        defer { lock.unlock() }
        return _currentTime
    }

    func advance(by milliseconds: Int64) {
        lock.lock()
        defer { lock.unlock() }
        _currentTime += milliseconds
    }
}

// MARK: - Mock Policy Provider

final class MockPolicyProvider: PolicyProvider, @unchecked Sendable {
    private var _policies: [EventPolicy] = []
    private let lock = NSLock()

    var policies: [EventPolicy] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _policies
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _policies = newValue
        }
    }

    init(policies: [EventPolicy] = []) {
        _policies = policies
    }

    func getActivePolicies() -> [EventPolicy] {
        lock.lock()
        defer { lock.unlock() }
        return _policies
    }
}

// MARK: - Mock Logger

final class MockLogger: JourneyLogger, @unchecked Sendable {
    private var _recordedSteps: [JourneyStep] = []
    private var _evaluations: [PolicyEvaluation] = []
    private var _resets: [String] = []
    private var _errors: [(message: String, error: Error?)] = []
    private let lock = NSLock()

    var recordedSteps: [JourneyStep] {
        lock.lock()
        defer { lock.unlock() }
        return _recordedSteps
    }

    var evaluations: [PolicyEvaluation] {
        lock.lock()
        defer { lock.unlock() }
        return _evaluations
    }

    var resets: [String] {
        lock.lock()
        defer { lock.unlock() }
        return _resets
    }

    var errors: [(message: String, error: Error?)] {
        lock.lock()
        defer { lock.unlock() }
        return _errors
    }

    func logStepRecorded(_ step: JourneyStep) {
        lock.lock()
        defer { lock.unlock() }
        _recordedSteps.append(step)
    }

    func logPolicyEvaluated(_ evaluation: PolicyEvaluation) {
        lock.lock()
        defer { lock.unlock() }
        _evaluations.append(evaluation)
    }

    func logPolicyReset(policyID: String) {
        lock.lock()
        defer { lock.unlock() }
        _resets.append(policyID)
    }

    func logError(_ message: String, error: Error?) {
        lock.lock()
        defer { lock.unlock() }
        _errors.append((message, error))
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        _recordedSteps.removeAll()
        _evaluations.removeAll()
        _resets.removeAll()
        _errors.removeAll()
    }
}

// MARK: - Test Factory

struct TestFactory {
    static func createStep(_ name: String, timestamp: Int64 = 1000) -> JourneyStep {
        JourneyStep(name: name, timestamp: timestamp)
    }

    static func createPattern(_ steps: String..., strict: Bool = true) -> JourneyPattern {
        JourneyPattern(steps: steps, strictSequence: strict)
    }

    static func createPolicy(
        id: String,
        actionKey: String,
        steps: [String],
        threshold: Int = 1,
        cooldown: Int = 0,
        persist: Bool = true,
        strict: Bool = true,
    ) -> EventPolicy {
        EventPolicy(
            id: id,
            actionKey: actionKey,
            pattern: JourneyPattern(steps: steps, strictSequence: strict),
            threshold: threshold,
            cooldownMinutes: cooldown,
            persistAcrossSessions: persist,
        )
    }
}
