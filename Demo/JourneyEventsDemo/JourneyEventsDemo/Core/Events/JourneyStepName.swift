//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents

/// Type-safe journey step names for the news feed app.
enum JourneyStepName: String {
    case appLaunched = "app_launched"
    case feedOpened = "feed_opened"
    case articleViewed = "article_viewed"
    case articleRead = "article_read"
    case articleShared = "article_shared"
    case categoryArticleViewed = "category_article_viewed"
}

// MARK: - EventTracker Extension

extension EventTracker {
    /// Records a step using a type-safe step name.
    @discardableResult
    func recordStep(
        _ step: JourneyStepName,
        parameters: [String: AnyHashableSendable] = [:],
    ) async -> PolicyEvaluation? {
        await recordStep(step.rawValue, parameters: parameters)
    }
}
