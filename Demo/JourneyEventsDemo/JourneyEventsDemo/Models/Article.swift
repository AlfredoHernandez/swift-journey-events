//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

import Foundation

/// Represents a news article in the feed.
struct Article: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let category: Category
    let author: String
    let publishedAt: Date
    let readingTimeMinutes: Int
    let imageSystemName: String

    enum Category: String, CaseIterable {
        case technology = "Technology"
        case sports = "Sports"
        case business = "Business"
        case entertainment = "Entertainment"
        case science = "Science"

        var iconName: String {
            switch self {
            case .technology: "laptopcomputer"

            case .sports: "sportscourt"

            case .business: "chart.line.uptrend.xyaxis"

            case .entertainment: "tv"

            case .science: "atom"
            }
        }

        var color: String {
            switch self {
            case .technology: "blue"

            case .sports: "green"

            case .business: "orange"

            case .entertainment: "purple"

            case .science: "teal"
            }
        }
    }
}

// MARK: - Sample Data

extension Article {
    static let samples: [Article] = [
        Article(
            id: "1",
            title: "Apple Unveils Revolutionary AI Chip",
            summary: "The new M5 chip promises 10x faster machine learning capabilities with unprecedented energy efficiency.",
            category: .technology,
            author: "Sarah Chen",
            publishedAt: Date().addingTimeInterval(-3600),
            readingTimeMinutes: 5,
            imageSystemName: "cpu",
        ),
        Article(
            id: "2",
            title: "Champions League Final Preview",
            summary: "A look at the tactics and key players ahead of this weekend's highly anticipated final.",
            category: .sports,
            author: "Marcus Johnson",
            publishedAt: Date().addingTimeInterval(-7200),
            readingTimeMinutes: 4,
            imageSystemName: "soccerball",
        ),
        Article(
            id: "3",
            title: "Stock Markets Reach All-Time High",
            summary: "Tech stocks lead the rally as investors show renewed confidence in the economy.",
            category: .business,
            author: "Emily Watson",
            publishedAt: Date().addingTimeInterval(-10800),
            readingTimeMinutes: 3,
            imageSystemName: "chart.bar.fill",
        ),
        Article(
            id: "4",
            title: "New Streaming Service Launches",
            summary: "The platform promises exclusive content and innovative features to compete with established players.",
            category: .entertainment,
            author: "David Park",
            publishedAt: Date().addingTimeInterval(-14400),
            readingTimeMinutes: 4,
            imageSystemName: "play.rectangle.fill",
        ),
        Article(
            id: "5",
            title: "Breakthrough in Quantum Computing",
            summary: "Scientists achieve quantum supremacy with a new 1000-qubit processor.",
            category: .science,
            author: "Dr. Lisa Monroe",
            publishedAt: Date().addingTimeInterval(-18000),
            readingTimeMinutes: 6,
            imageSystemName: "waveform.path.ecg",
        ),
        Article(
            id: "6",
            title: "Swift 6 Concurrency Deep Dive",
            summary: "Exploring the new concurrency features and how they improve app performance.",
            category: .technology,
            author: "Alex Rivera",
            publishedAt: Date().addingTimeInterval(-21600),
            readingTimeMinutes: 8,
            imageSystemName: "swift",
        ),
        Article(
            id: "7",
            title: "Olympic Games Preparation Update",
            summary: "Cities around the world prepare to host the upcoming Olympic events.",
            category: .sports,
            author: "Nina Patel",
            publishedAt: Date().addingTimeInterval(-25200),
            readingTimeMinutes: 5,
            imageSystemName: "figure.run",
        ),
        Article(
            id: "8",
            title: "Electric Vehicle Sales Surge",
            summary: "EV adoption accelerates as new models offer better range and lower prices.",
            category: .business,
            author: "Tom Bradley",
            publishedAt: Date().addingTimeInterval(-28800),
            readingTimeMinutes: 4,
            imageSystemName: "car.fill",
        ),
        Article(
            id: "9",
            title: "Mars Rover Discovers Water Ice",
            summary: "NASA's latest rover mission finds significant water ice deposits beneath the Martian surface.",
            category: .science,
            author: "Dr. James Foster",
            publishedAt: Date().addingTimeInterval(-32400),
            readingTimeMinutes: 7,
            imageSystemName: "globe.americas.fill",
        ),
        Article(
            id: "10",
            title: "Award Season Predictions",
            summary: "Film critics weigh in on the frontrunners for this year's major awards.",
            category: .entertainment,
            author: "Rachel Kim",
            publishedAt: Date().addingTimeInterval(-36000),
            readingTimeMinutes: 5,
            imageSystemName: "star.fill",
        ),
    ]
}
