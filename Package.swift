// swift-tools-version: 6.2

import PackageDescription

let package = Package(
	name: "swift-journey-events",
	platforms: [
		.iOS(.v16),
		.macOS(.v13),
		.tvOS(.v16),
		.watchOS(.v9),
	],
	products: [
		.library(name: "JourneyEvents", targets: ["JourneyEvents"]),
	],
	targets: [
		.target(name: "JourneyEvents"),
		.testTarget(name: "JourneyEventsTests", dependencies: ["JourneyEvents"]),
	],
)
