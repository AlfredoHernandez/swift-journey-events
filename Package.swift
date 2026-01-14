// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-journey-events",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7),
    ],
    products: [
        .library(name: "JourneyEvents", targets: ["JourneyEvents"]),
    ],
    targets: [
        .target(name: "JourneyEvents"),
        .testTarget(name: "JourneyEventsTests", dependencies: ["JourneyEvents"]),
    ],
)
