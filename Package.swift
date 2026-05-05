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
		.library(name: "JourneyEventsTesting", targets: ["JourneyEventsTesting"]),
	],
	targets: [
		.target(name: "JourneyEvents"),
		.target(name: "JourneyEventsTesting", dependencies: ["JourneyEvents"]),
		.testTarget(
			name: "JourneyEventsTests",
			dependencies: ["JourneyEvents", "JourneyEventsTesting"],
		),
	],
)
