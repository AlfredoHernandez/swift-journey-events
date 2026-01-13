//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import JourneyEvents
import SwiftUI

/// Detail view for reading an article.
struct ArticleDetailView: View {
    let article: Article
    let eventTracker: EventTracker
    let onShare: (Article) -> Void

    @State private var hasTrackedView = false
    @State private var hasTrackedRead = false
    @State private var scrollProgress: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                metadataSection
                contentSection
                actionsSection
            }
            .padding()
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).minY,
                    )
                },
            )
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            let progress = min(1, max(0, -value / 300))
            if progress > 0.7, !hasTrackedRead {
                hasTrackedRead = true
                trackArticleRead()
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { onShare(article) }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .task {
            await trackArticleViewed()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: article.category.iconName)
                Text(article.category.rawValue.uppercased())
                    .fontWeight(.semibold)
            }
            .font(.caption)
            .foregroundStyle(categoryColor)

            Text(article.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(article.summary)
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private var metadataSection: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.title2)
            VStack(alignment: .leading) {
                Text(article.author)
                    .fontWeight(.medium)
                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Label("\(article.readingTimeMinutes) min", systemImage: "clock")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.vertical, 8)
    }

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Simulated article image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryColor.opacity(0.2))
                Image(systemName: article.imageSystemName)
                    .font(.system(size: 60))
                    .foregroundStyle(categoryColor)
            }
            .frame(height: 200)

            // Simulated article paragraphs
            ForEach(0 ..< 5, id: \.self) { index in
                Text(generateParagraph(for: index))
                    .lineSpacing(6)
            }
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 16) {
            Divider()

            HStack(spacing: 24) {
                Button(action: { onShare(article) }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }

                Button(action: {}) {
                    Label("Save", systemImage: "bookmark")
                }

                Spacer()

                Button(action: {
                    trackCategoryViewed()
                }) {
                    Label("More \(article.category.rawValue)", systemImage: "arrow.right")
                }
            }
            .buttonStyle(.bordered)
        }
        .padding(.top)
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

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: article.publishedAt, relativeTo: Date())
    }

    private func generateParagraph(for index: Int) -> String {
        let paragraphs = [
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.",
            "Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident.",
            "Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis.",
            "Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.",
            "Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt.",
        ]
        return paragraphs[index % paragraphs.count]
    }

    private func trackArticleViewed() async {
        guard !hasTrackedView else { return }
        hasTrackedView = true

        await eventTracker.recordStep(
            "article_viewed",
            parameters: [
                "article_id": AnyHashableSendable(article.id),
                "category": AnyHashableSendable(article.category.rawValue),
            ],
        )
    }

    private func trackArticleRead() {
        Task {
            await eventTracker.recordStep(
                "article_read",
                parameters: [
                    "article_id": AnyHashableSendable(article.id),
                    "reading_time": AnyHashableSendable(article.readingTimeMinutes),
                ],
            )
        }
    }

    private func trackCategoryViewed() {
        Task {
            await eventTracker.recordStep(
                "category_article_viewed",
                parameters: [
                    "category": AnyHashableSendable(article.category.rawValue),
                ],
            )
        }
    }
}

/// Preference key for tracking scroll offset.
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(
            article: Article.samples[0],
            eventTracker: EventTrackerFactory.create(),
            onShare: { _ in },
        )
    }
}
