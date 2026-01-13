//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import OSLog

/// Compact implementation of `JourneyLogger` using single-line format.
///
/// This logger provides minimal, efficient logging suitable for production use:
/// - Single line per event for better Console readability
/// - All essential information preserved
/// - Easy to filter
/// - 85% less verbose than `OSLogJourneyLogger`
///
/// Example output:
/// ```
/// Step: line_viewed {id=linea_1}
/// Policy SKIP: content_ad (3/5) - Threshold not reached
/// Action triggered: content_ad -> content_interstitial
/// ```
public struct CompactJourneyLogger: JourneyLogger {
    private let logger = Logger(subsystem: "JourneyEvents", category: "Compact")

    public init() {}

    public func logStepRecorded(_ step: JourneyStep) {
        let params = formatParameters(step.parameters)
        logger.debug("Step: \(step.name) \(params)")
    }

    public func logPolicyEvaluated(_ evaluation: PolicyEvaluation) {
        let status = evaluation.shouldTriggerAction ? "TRIGGER" : "SKIP"
        logger.debug(
            "Policy \(status): \(evaluation.policyID) (\(evaluation.currentCount)/\(evaluation.threshold)) - \(evaluation.reason)",
        )

        if evaluation.shouldTriggerAction {
            logger.info("Action triggered: \(evaluation.policyID) -> \(evaluation.actionKey)")
        }
    }

    public func logPolicyReset(policyID: String) {
        logger.debug("Policy reset: \(policyID) -> 0")
    }

    public func logError(_ message: String, error: Error?) {
        if let error {
            logger.error("Error: \(message) - \(error.localizedDescription)")
        } else {
            logger.error("Error: \(message)")
        }
    }

    private func formatParameters(_ parameters: [String: AnyHashableSendable]) -> String {
        if parameters.isEmpty {
            return "{}"
        }
        let entries = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        return "{\(entries)}"
    }
}
