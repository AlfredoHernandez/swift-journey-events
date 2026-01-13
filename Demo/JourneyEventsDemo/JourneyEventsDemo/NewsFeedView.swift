//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents
import SwiftUI

/// Main news feed view displaying a list of articles.
struct NewsFeedView: View {
    let eventTracker: EventTracker
    let articles: [Article]
    let alertManager: AlertManager

    var body: some View {
        NavigationStack {
            List(articles) { article in
                NavigationLink(value: article) {
                    ArticleRow(article: article)
                }
            }
            .navigationTitle("Daily News")
            .navigationDestination(for: Article.self) { article in
                ArticleDetailView(
                    article: article,
                    eventTracker: eventTracker,
                    onShare: { handleShare(article: $0) },
                )
            }
            .task {
                await trackFeedOpened()
            }
        }
    }

    private func trackFeedOpened() async {
        await eventTracker.recordStep("feed_opened")
        await eventTracker.recordStep("app_launched")
    }

    private func handleShare(article: Article) {
        Task {
            await eventTracker.recordStep(
                "article_shared",
                parameters: ["article_id": AnyHashableSendable(article.id)],
            )
        }
    }
}

/// Row view for displaying an article in the list.
struct ArticleRow: View {
    let article: Article

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: article.imageSystemName)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(categoryColor)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: article.category.iconName)
                        .font(.caption)
                    Text(article.category.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(categoryColor)

                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack {
                    Text(article.author)
                    Text("•")
                    Text("\(article.readingTimeMinutes) min read")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch article.category.color {
        case "blue": .blue

        case "green": .green

        case "orange": .orange

        case "purple": .purple

        case "teal": .teal

        default: .gray
        }
    }
}

#Preview {
    NewsFeedView(
        eventTracker: EventTrackerFactory.create(),
        articles: Article.samples,
        alertManager: AlertManager(),
    )
}
