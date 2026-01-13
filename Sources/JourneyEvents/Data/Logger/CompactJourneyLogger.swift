//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import OSLog

/// Compact implementation of ``JourneyLogger`` using single-line format.
///
/// This logger provides minimal, efficient logging suitable for production use.
/// Each event is logged on a single line, making it easy to read and filter
/// in Xcode Console or system logs.
///
/// ## Overview
///
/// ``CompactJourneyLogger`` strikes a balance between verbosity and information
/// density. It provides:
/// - Single line per event for better Console readability
/// - All essential information preserved
/// - Easy filtering by category
/// - 85% less verbose than ``OSLogJourneyLogger``
///
/// ## Log Format
///
/// Step recorded:
///
///     Step: line_viewed {id=linea_1, name=Line 1}
///
/// Policy evaluation (skipped):
///
///     Policy SKIP: content_ad (3/5) - Threshold not reached (3/5, 2 remaining)
///
/// Policy evaluation (triggered):
///
///     Policy TRIGGER: content_ad (5/5) - Threshold reached (5/5)
///     Action triggered: content_ad -> content_interstitial
///
/// Policy reset:
///
///     Policy reset: content_ad -> 0
///
/// ## Usage
///
///     let logger = CompactJourneyLogger()
///     logger.logStepRecorded(JourneyStep(name: "article_viewed", parameters: ["id": "123"]))
///     // Output: Step: article_viewed {id=123}
///
/// ## Performance
///
/// Optimized for production use with minimal overhead. Uses OSLog's debug
/// level for most messages and info level only for action triggers.
///
/// - SeeAlso: ``JourneyLogger`` for protocol documentation
/// - SeeAlso: ``OSLogJourneyLogger`` for verbose debugging output
public struct CompactJourneyLogger: JourneyLogger {
    private let logger = Logger(subsystem: "JourneyEvents", category: "Compact")

    /// Creates a new compact journey logger.
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
