//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents
import SwiftUI

/// Main entry point for the News Feed demo application.
///
/// This app demonstrates the JourneyEvents package by tracking user behavior
/// in a simulated news reader application.
///
/// ## How to Test
///
/// 1. Browse the article feed (triggers `feed_opened` and `app_launched`)
/// 2. Tap on articles to view them (triggers `article_viewed`)
/// 3. Scroll down to read articles (triggers `article_read`)
/// 4. Share articles (triggers `article_shared`)
/// 5. Tap "More [Category]" button (triggers `category_article_viewed`)
///
/// Watch for alert dialogs showing when policies are triggered!
@main
struct JourneyEventsDemoApp: App {
    let eventTracker = EventTrackerFactory.create()
    @State private var alertManager = AlertManager()

    var body: some Scene {
        WindowGroup {
            NewsFeedView(
                eventTracker: eventTracker,
                articles: Article.samples,
                alertManager: alertManager,
            )
            .alert(alertManager.alertTitle, isPresented: $alertManager.isShowingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertManager.alertMessage)
            }
            .task {
                for await evaluation in eventTracker.policyTriggers {
                    alertManager.handlePolicyTrigger(evaluation)
                }
            }
        }
    }
}
