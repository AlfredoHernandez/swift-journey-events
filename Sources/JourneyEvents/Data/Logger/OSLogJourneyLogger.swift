//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import Foundation
import OSLog

/// Verbose implementation of ``JourneyLogger`` using OS Logger.
///
/// Provides detailed, visual logging of all journey events and policy evaluation
/// results with box-drawing characters and formatted output. Ideal for debugging
/// and development but not recommended for production due to verbosity.
///
/// ## Overview
///
/// ``OSLogJourneyLogger`` creates highly readable, visually formatted log entries
/// using box-drawing characters. Each event is logged in a bordered box with
/// clearly labeled fields.
///
/// ## Log Format
///
/// Step recorded:
///
///     ╔═══════════════════════════════════════════════════════════════
///     ║ JOURNEY STEP RECORDED
///     ╠═══════════════════════════════════════════════════════════════
///     ║ Step: line_viewed
///     ║ Parameters: {id=linea_1, name=Line 1}
///     ║ Timestamp: 2026-01-13 10:30:45.123
///     ╚═══════════════════════════════════════════════════════════════
///
/// Policy evaluation:
///
///     ╔═══════════════════════════════════════════════════════════════
///     ║ POLICY EVALUATED
///     ╠═══════════════════════════════════════════════════════════════
///     ║ Policy ID: article_ad
///     ║ Count: 5/5
///     ║ Result: ✓ TRIGGER ACTION
///     ║ Reason: Threshold reached (5/5)
///     ║ Action Key: ca-app-pub-xxx/yyy
///     ╚═══════════════════════════════════════════════════════════════
///
/// ## Usage
///
///     let logger = OSLogJourneyLogger()
///     logger.logStepRecorded(JourneyStep(name: "article_viewed"))
///
/// ## Performance
///
/// This logger is significantly more verbose than ``CompactJourneyLogger``
/// (about 7x more lines per event). Use for debugging only, not production.
///
/// - Warning: High verbosity makes logs harder to scan. Consider ``CompactJourneyLogger`` for production.
/// - SeeAlso: ``JourneyLogger`` for protocol documentation
/// - SeeAlso: ``CompactJourneyLogger`` for production-friendly logging
public struct OSLogJourneyLogger: JourneyLogger {
    private let logger = Logger(subsystem: "JourneyEvents", category: "Journey")
    private let dateFormatter: DateFormatter

    /// Creates a new verbose OS log journey logger.
    public init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    }

    public func logStepRecorded(_ step: JourneyStep) {
        let timestamp = dateFormatter.string(from: Date(timeIntervalSince1970: Double(step.timestamp) / 1000))
        let params = formatParameters(step.parameters)

        logger.debug("""
        ╔═══════════════════════════════════════════════════════════════
        ║ JOURNEY STEP RECORDED
        ╠═══════════════════════════════════════════════════════════════
        ║ Step: \(step.name)
        ║ Parameters: \(params)
        ║ Timestamp: \(timestamp)
        ╚═══════════════════════════════════════════════════════════════
        """)
    }

    public func logPolicyEvaluated(_ evaluation: PolicyEvaluation) {
        let result = evaluation.shouldTriggerAction ? "✓ TRIGGER ACTION" : "✗ DON'T TRIGGER ACTION"

        logger.debug("""
        ╔═══════════════════════════════════════════════════════════════
        ║ POLICY EVALUATED
        ╠═══════════════════════════════════════════════════════════════
        ║ Policy ID: \(evaluation.policyID)
        ║ Count: \(evaluation.currentCount)/\(evaluation.threshold)
        ║ Result: \(result)
        ║ Reason: \(evaluation.reason)
        ║ Action Key: \(evaluation.actionKey)
        ╚═══════════════════════════════════════════════════════════════
        """)

        if evaluation.shouldTriggerAction {
            logger.info("✓ Action trigger activated: \(evaluation.policyID)")
        }
    }

    public func logPolicyReset(policyID: String) {
        logger.debug("""
        ╔═══════════════════════════════════════════════════════════════
        ║ POLICY RESET
        ╠═══════════════════════════════════════════════════════════════
        ║ Policy ID: \(policyID)
        ║ Count reset to: 0
        ╚═══════════════════════════════════════════════════════════════
        """)
    }

    public func logError(_ message: String, error: Error?) {
        let errorLine = error.map { "║ Exception: \($0.localizedDescription)\n" } ?? ""

        logger.error("""
        ╔═══════════════════════════════════════════════════════════════
        ║ ERROR
        ╠═══════════════════════════════════════════════════════════════
        ║ Message: \(message)
        \(errorLine)╚═══════════════════════════════════════════════════════════════
        """)
    }

    private func formatParameters(_ parameters: [String: AnyHashableSendable]) -> String {
        if parameters.isEmpty {
            return "{}"
        }
        let entries = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
        return "{\(entries)}"
    }
}
