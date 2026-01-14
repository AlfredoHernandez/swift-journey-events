//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Testing

@Suite("EventPolicy Tests")
struct EventPolicyTests {
    @Test("Init creates basic policy with default values")
    func init_createsBasicPolicyWithDefaultValues() {
        let pattern = JourneyPattern(steps: ["article_viewed"])
        let policy = EventPolicy(
            id: "article_ad",
            actionKey: "ad_unit_123",
            pattern: pattern,
            threshold: 5,
        )

        #expect(policy.id == "article_ad")
        #expect(policy.actionKey == "ad_unit_123")
        #expect(policy.pattern == pattern)
        #expect(policy.threshold == 5)
        #expect(policy.cooldownMinutes == 0)
        #expect(policy.persistAcrossSessions == true)
    }

    @Test("Init creates policy with custom cooldown")
    func init_createsPolicyWithCustomCooldown() {
        let pattern = JourneyPattern(steps: ["app_opened"])
        let policy = EventPolicy(
            id: "notification_prompt",
            actionKey: "request_notifications",
            pattern: pattern,
            threshold: 3,
            cooldownMinutes: 60,
        )

        #expect(policy.cooldownMinutes == 60)
        #expect(policy.persistAcrossSessions == true)
    }

    @Test("Init creates session-only policy when persistAcrossSessions is false")
    func init_createsSessionOnlyPolicyWhenPersistAcrossSessionsIsFalse() {
        let pattern = JourneyPattern(steps: ["feature_used"])
        let policy = EventPolicy(
            id: "session_tip",
            actionKey: "show_tip",
            pattern: pattern,
            threshold: 2,
            persistAcrossSessions: false,
        )

        #expect(policy.persistAcrossSessions == false)
        #expect(policy.cooldownMinutes == 0)
    }

    @Test("Init creates policy with all custom parameters")
    func init_createsPolicyWithAllCustomParameters() {
        let pattern = JourneyPattern(
            steps: ["welcome", "tutorial", "profile"],
            strictSequence: false,
        )
        let policy = EventPolicy(
            id: "onboarding_complete",
            actionKey: "show_celebration",
            pattern: pattern,
            threshold: 1,
            cooldownMinutes: 30,
            persistAcrossSessions: false,
        )

        #expect(policy.id == "onboarding_complete")
        #expect(policy.actionKey == "show_celebration")
        #expect(policy.pattern == pattern)
        #expect(policy.threshold == 1)
        #expect(policy.cooldownMinutes == 30)
        #expect(policy.persistAcrossSessions == false)
    }

    @Test("Equatable returns true when policies have same values")
    func equatable_returnsTrueWhenPoliciesHaveSameValues() {
        let pattern = JourneyPattern(steps: ["test"])
        let policy1 = EventPolicy(
            id: "test_policy",
            actionKey: "test_action",
            pattern: pattern,
            threshold: 5,
        )
        let policy2 = EventPolicy(
            id: "test_policy",
            actionKey: "test_action",
            pattern: pattern,
            threshold: 5,
        )

        #expect(policy1 == policy2)
    }

    @Test("Equatable returns false when policies have different IDs")
    func equatable_returnsFalseWhenPoliciesHaveDifferentIDs() {
        let pattern = JourneyPattern(steps: ["test"])
        let policy1 = EventPolicy(
            id: "policy1",
            actionKey: "action",
            pattern: pattern,
            threshold: 5,
        )
        let policy2 = EventPolicy(
            id: "policy2",
            actionKey: "action",
            pattern: pattern,
            threshold: 5,
        )

        #expect(policy1 != policy2)
    }
}
