//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents

/// Provides event policies for the news feed application.
///
/// This demonstrates how to use JourneyEvents to trigger actions
/// based on user behavior in a news app context.
///
/// ## Demo Policies
///
/// | Policy ID | Trigger | Threshold | Cooldown |
/// |-----------|---------|-----------|----------|
/// | `article_viewed_subscription` | View articles | 3 | None |
/// | `engagement_journey` | Feed → View → Share | 1 | None |
/// | `category_recommendation` | Same category views | 2 | None |
/// | `onboarding_feedback` | Launch → Feed → Read | 1 | None |
final class NewsFeedPolicyProvider: PolicyProvider, @unchecked Sendable {
    func getActivePolicies() -> [EventPolicy] {
        [
            // Show subscription prompt after viewing 3 articles
            EventPolicy(
                id: "article_viewed_subscription",
                actionKey: "article_viewed_subscription",
                pattern: JourneyPattern(steps: ["article_viewed"]),
                threshold: 3,
                cooldownMinutes: 1,
                persistAcrossSessions: false,
            ),

            // Show "become a member" after user journey:
            // feed_opened -> article_viewed -> article_shared
            EventPolicy(
                id: "engagement_journey",
                actionKey: "engagement_journey",
                pattern: JourneyPattern(
                    steps: ["feed_opened", "article_viewed", "article_shared"],
                    strictSequence: false,
                ),
                threshold: 1,
                cooldownMinutes: 0,
                persistAcrossSessions: false,
            ),

            // Show category-based recommendation after tapping "More [Category]" twice
            EventPolicy(
                id: "category_recommendation",
                actionKey: "category_recommendation",
                pattern: JourneyPattern(steps: ["category_article_viewed"]),
                threshold: 2,
                cooldownMinutes: 0,
                persistAcrossSessions: false,
            ),

            // Show feedback request after completing onboarding journey
            EventPolicy(
                id: "onboarding_feedback",
                actionKey: "onboarding_feedback",
                pattern: JourneyPattern(
                    steps: ["app_launched", "feed_opened", "article_read"],
                    strictSequence: false,
                ),
                threshold: 1,
                cooldownMinutes: 0,
                persistAcrossSessions: false,
            ),
        ]
    }
}
