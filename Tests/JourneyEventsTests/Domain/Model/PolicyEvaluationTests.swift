//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Testing

@Suite("PolicyEvaluation Tests")
struct PolicyEvaluationTests {
    @Test("Init creates evaluation with shouldTriggerAction as true")
    func init_createsEvaluationWithShouldTriggerActionAsTrue() {
        let evaluation = PolicyEvaluation(
            shouldTriggerAction: true,
            policyID: "article_ad",
            actionKey: "ad_unit_123",
            currentCount: 5,
            threshold: 5,
            reason: "Threshold reached (5/5)",
        )

        #expect(evaluation.shouldTriggerAction == true)
        #expect(evaluation.policyID == "article_ad")
        #expect(evaluation.actionKey == "ad_unit_123")
        #expect(evaluation.currentCount == 5)
        #expect(evaluation.threshold == 5)
        #expect(evaluation.reason == "Threshold reached (5/5)")
    }

    @Test("Init creates evaluation with shouldTriggerAction as false")
    func init_createsEvaluationWithShouldTriggerActionAsFalse() {
        let evaluation = PolicyEvaluation(
            shouldTriggerAction: false,
            policyID: "article_ad",
            actionKey: "ad_unit_123",
            currentCount: 3,
            threshold: 5,
            reason: "Threshold not reached (3/5, 2 remaining)",
        )

        #expect(evaluation.shouldTriggerAction == false)
        #expect(evaluation.currentCount == 3)
        #expect(evaluation.threshold == 5)
        #expect(evaluation.reason.contains("2 remaining"))
    }

    @Test("Init creates evaluation with cooldown active reason")
    func init_createsEvaluationWithCooldownActiveReason() {
        let evaluation = PolicyEvaluation(
            shouldTriggerAction: false,
            policyID: "notification_prompt",
            actionKey: "request_notifications",
            currentCount: 5,
            threshold: 3,
            reason: "Cooldown active (5/15 min elapsed, 10m 0s remaining)",
        )

        #expect(evaluation.shouldTriggerAction == false)
        #expect(evaluation.reason.contains("Cooldown active"))
        #expect(evaluation.reason.contains("remaining"))
    }

    @Test("Equatable returns true when evaluations have same values")
    func equatable_returnsTrueWhenEvaluationsHaveSameValues() {
        let eval1 = PolicyEvaluation(
            shouldTriggerAction: true,
            policyID: "test",
            actionKey: "action",
            currentCount: 5,
            threshold: 5,
            reason: "Threshold reached",
        )
        let eval2 = PolicyEvaluation(
            shouldTriggerAction: true,
            policyID: "test",
            actionKey: "action",
            currentCount: 5,
            threshold: 5,
            reason: "Threshold reached",
        )

        #expect(eval1 == eval2)
    }

    @Test("Equatable returns false when evaluations have different values")
    func equatable_returnsFalseWhenEvaluationsHaveDifferentValues() {
        let eval1 = PolicyEvaluation(
            shouldTriggerAction: true,
            policyID: "test",
            actionKey: "action",
            currentCount: 5,
            threshold: 5,
            reason: "Threshold reached",
        )
        let eval2 = PolicyEvaluation(
            shouldTriggerAction: false,
            policyID: "test",
            actionKey: "action",
            currentCount: 3,
            threshold: 5,
            reason: "Threshold not reached",
        )

        #expect(eval1 != eval2)
    }
}
