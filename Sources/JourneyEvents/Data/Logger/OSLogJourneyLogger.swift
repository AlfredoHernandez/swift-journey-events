//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import Foundation
import OSLog

/// Verbose implementation of `JourneyLogger` using OS Logger.
///
/// Provides detailed and visual logging of all journey events
/// and policy evaluation results. Suitable for debugging.
public struct OSLogJourneyLogger: JourneyLogger {
    private let logger = Logger(subsystem: "JourneyEvents", category: "Journey")
    private let dateFormatter: DateFormatter

    public init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    }

    public func logStepRecorded(_ step: JourneyStep) {
        let timestamp = dateFormatter.string(from: Date(timeIntervalSince1970: Double(step.timestamp) / 1000))
        let params = formatParameters(step.parameters)

        logger.debug("╔═══════════════════════════════════════════════════════════════")
        logger.debug("║ JOURNEY STEP RECORDED")
        logger.debug("╠═══════════════════════════════════════════════════════════════")
        logger.debug("║ Step: \(step.name)")
        logger.debug("║ Parameters: \(params)")
        logger.debug("║ Timestamp: \(timestamp)")
        logger.debug("╚═══════════════════════════════════════════════════════════════")
    }

    public func logPolicyEvaluated(_ evaluation: PolicyEvaluation) {
        let result = evaluation.shouldTriggerAction ? "✓ TRIGGER ACTION" : "✗ DON'T TRIGGER ACTION"
        let resultSymbol = evaluation.shouldTriggerAction ? "✓" : "✗"

        logger.debug("")
        logger.debug("╔═══════════════════════════════════════════════════════════════")
        logger.debug("║ POLICY EVALUATED")
        logger.debug("╠═══════════════════════════════════════════════════════════════")
        logger.debug("║ Policy ID: \(evaluation.policyID)")
        logger.debug("║ Count: \(evaluation.currentCount)/\(evaluation.threshold)")
        logger.debug("║ Result: \(result)")
        logger.debug("║ Reason: \(evaluation.reason)")
        logger.debug("║ Action Key: \(evaluation.actionKey)")
        logger.debug("╚═══════════════════════════════════════════════════════════════")

        if evaluation.shouldTriggerAction {
            logger.info("\(resultSymbol) Action trigger activated: \(evaluation.policyID)")
        }
    }

    public func logPolicyReset(policyID: String) {
        logger.debug("")
        logger.debug("╔═══════════════════════════════════════════════════════════════")
        logger.debug("║ POLICY RESET")
        logger.debug("╠═══════════════════════════════════════════════════════════════")
        logger.debug("║ Policy ID: \(policyID)")
        logger.debug("║ Count reset to: 0")
        logger.debug("╚═══════════════════════════════════════════════════════════════")
    }

    public func logError(_ message: String, error: Error?) {
        logger.error("╔═══════════════════════════════════════════════════════════════")
        logger.error("║ ERROR")
        logger.error("╠═══════════════════════════════════════════════════════════════")
        logger.error("║ Message: \(message)")
        if let error {
            logger.error("║ Exception: \(error.localizedDescription)")
        }
        logger.error("╚═══════════════════════════════════════════════════════════════")
    }

    private func formatParameters(_ parameters: [String: AnyHashableSendable]) -> String {
        if parameters.isEmpty {
            return "{}"
        }
        let entries = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        return "{\(entries)}"
    }
}
