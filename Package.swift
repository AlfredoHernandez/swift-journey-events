// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-journey-events",
    products: [
        .library(name: "JourneyEvents", targets: ["JourneyEvents"]),
    ],
    targets: [
        .target(name: "JourneyEvents"),
        .testTarget(name: "JourneyEventsTests", dependencies: ["JourneyEvents"]),
    ],
)
