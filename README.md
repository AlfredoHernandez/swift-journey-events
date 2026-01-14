# swift-journey-events

A Swift package for tracking user journey events and triggering actions based on behavior patterns. Supports sequence matching, thresholds, cooldowns, and Swift 6 concurrency.

## Features

- **Event Tracking**: Record user journey steps with optional parameters
- **Pattern Matching**: Single-step or multi-step sequence patterns
- **Flexible Matching**: Strict (exact order) or loose (allows intermediate steps)
- **Thresholds**: Trigger actions after N occurrences
- **Cooldowns**: Prevent repeated triggers within a time window
- **Async Streams**: Subscribe to policy triggers with `AsyncStream`
- **Swift 6 Concurrency**: Full actor isolation and `Sendable` compliance
- **Verbose Logging**: Debug-friendly OSLog output

## Requirements

- iOS 14.0+ / macOS 11.0+ / tvOS 14.0+ / watchOS 7.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/AlfredoHernandez/swift-journey-events.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** and enter the repository URL.

## Quick Start

### 1. Define Your Policies

```swift
import JourneyEvents

final class MyPolicyProvider: PolicyProvider {
    func getActivePolicies() -> [EventPolicy] {
        [
            // Trigger after viewing 3 articles
            EventPolicy(
                id: "subscription_prompt",
                actionKey: "show_subscription",
                pattern: JourneyPattern(steps: ["article_viewed"]),
                threshold: 3,
                cooldownMinutes: 15,
                persistAcrossSessions: true
            ),

            // Trigger after completing a journey sequence
            EventPolicy(
                id: "onboarding_complete",
                actionKey: "show_welcome",
                pattern: JourneyPattern(
                    steps: ["signup", "profile_created", "first_action"],
                    strictSequence: false  // Allows other steps in between
                ),
                threshold: 1,
                cooldownMinutes: 0,
                persistAcrossSessions: false
            )
        ]
    }
}
```

### 2. Create the EventTracker

```swift
let policyProvider = MyPolicyProvider()
let journeyStepRepository = InMemoryJourneyStepRepository()
let eventStateRepository = InMemoryEventStateRepository()

let trackJourneyStep = TrackJourneyStep(
    journeyStepRepository: journeyStepRepository,
    eventStateRepository: eventStateRepository,
    policyProvider: policyProvider,
    sequenceMatcher: SequenceMatcher()
)

let evaluateEventPolicy = EvaluateEventPolicy(
    eventStateRepository: eventStateRepository,
    logger: OSLogJourneyLogger(),
    timeProvider: SystemTimeProvider()
)

let eventTracker = EventTracker(
    trackJourneyStep: trackJourneyStep,
    evaluateEventPolicy: evaluateEventPolicy,
    policyProvider: policyProvider,
    logger: OSLogJourneyLogger()
)
```

### 3. Record Events

```swift
// Record a step - policies are automatically checked
await eventTracker.recordStep("article_viewed", parameters: [
    "article_id": AnyHashableSendable("123"),
    "category": AnyHashableSendable("tech")
])
```

### 4. Listen for Policy Triggers

```swift
// Subscribe to policy triggers
Task {
    for await evaluation in eventTracker.policyTriggers {
        switch evaluation.actionKey {
        case "show_subscription":
            showSubscriptionPrompt()
        case "show_welcome":
            showWelcomeScreen()
        default:
            break
        }
    }
}
```

## Core Concepts

### JourneyStep

Represents a single user action:

```swift
let step = JourneyStep(
    name: "article_viewed",
    parameters: ["id": AnyHashableSendable("123")]
)
```

### JourneyPattern

Defines the sequence of steps to match:

```swift
// Single step pattern
let single = JourneyPattern(steps: ["button_tapped"])

// Multi-step strict sequence (exact order required)
let strict = JourneyPattern(
    steps: ["step_a", "step_b", "step_c"],
    strictSequence: true
)

// Multi-step loose sequence (allows intermediate steps)
let loose = JourneyPattern(
    steps: ["start", "middle", "end"],
    strictSequence: false
)
```

### EventPolicy

Combines a pattern with trigger conditions:

```swift
EventPolicy(
    id: "unique_policy_id",
    actionKey: "action_to_trigger",
    pattern: JourneyPattern(steps: ["event_name"]),
    threshold: 5,              // Trigger after 5 occurrences
    cooldownMinutes: 30,       // Wait 30 min before re-triggering
    persistAcrossSessions: true // Survive app restarts
)
```

### PolicyEvaluation

Result of evaluating a policy:

```swift
let evaluation = await eventTracker.checkPoliciesForStep("event_name")

if evaluation.shouldTriggerAction {
    print("Policy: \(evaluation.policyID)")
    print("Action: \(evaluation.actionKey)")
    print("Count: \(evaluation.currentCount)/\(evaluation.threshold)")
    print("Reason: \(evaluation.reason)")
}
```

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     EventTracker                        │
│  (Main entry point - orchestrates tracking & policies)  │
└─────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┴───────────────┐
            ▼                               ▼
┌───────────────────────┐       ┌───────────────────────┐
│   TrackJourneyStep    │       │  EvaluateEventPolicy  │
│  (Records & matches)  │       │ (Checks thresholds)   │
└───────────────────────┘       └───────────────────────┘
            │                               │
            ▼                               ▼
┌───────────────────────┐       ┌───────────────────────┐
│ JourneyStepRepository │       │  EventStateRepository │
│   (Step history)      │       │  (Counters & times)   │
└───────────────────────┘       └───────────────────────┘
```

## Demo App

The repository includes a demo iOS app (`Demo/JourneyEventsDemo`) showcasing a news feed application with journey tracking:

- **article_viewed_subscription**: Prompt after viewing 3 articles
- **engagement_journey**: Trigger after Feed → View → Share sequence
- **category_recommendation**: Suggest content after 2 category views
- **onboarding_feedback**: Request feedback after onboarding journey

Run the demo in Xcode to see journey events in action.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

Jesús Alfredo Hernández Alarcón
