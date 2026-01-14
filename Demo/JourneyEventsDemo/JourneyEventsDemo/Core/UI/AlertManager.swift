//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents
import SwiftUI

/// Manages alerts triggered by journey event policies.
@MainActor
@Observable
final class AlertManager {
    var isShowingAlert = false
    var alertTitle = ""
    var alertMessage = ""

    func handlePolicyTrigger(_ evaluation: PolicyEvaluation) {
        switch evaluation.actionKey {
        case "article_viewed_subscription":
            alertTitle = "article_viewed_subscription"
            alertMessage = "You've viewed 3 articles! Subscribe to Premium."

        case "engagement_journey":
            alertTitle = "engagement_journey"
            alertMessage = "Journey complete: Feed → View → Share"

        case "category_recommendation":
            alertTitle = "category_recommendation"
            alertMessage = "You've shown interest in this category twice!"

        case "onboarding_feedback":
            alertTitle = "onboarding_feedback"
            alertMessage = "Onboarding complete: Launch → Feed → Read"

        default:
            alertTitle = evaluation.policyID
            alertMessage = "Action: \(evaluation.actionKey)"
        }

        isShowingAlert = true
    }
}
