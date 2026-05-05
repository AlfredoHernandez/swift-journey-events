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
- **Pluggable Logging**: Bring your own `JourneyLogger` to bridge into any telemetry pipeline

## Requirements

- iOS 16.0+ / macOS 13.0+ / tvOS 16.0+ / watchOS 9.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/AlfredoHernandez/swift-journey-events.git", from: "2.0.0")
]
```

The package ships two library products:

- `JourneyEvents` — the production policy engine.
- `JourneyEventsTesting` — reusable in-memory repositories, builders, fixtures, and a `RecordingJourneyLogger` spy. Add this only to test targets (or debug-only build configurations).

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
import JourneyEvents

let policyProvider = MyPolicyProvider()

// Provide your own JourneyStepRepository / EventStateRepository implementations.
// Production wiring typically pairs UserDefaultsEventStateRepository with a
// session-scoped repository for policies that don't persist across sessions.
let journeyStepRepository: any JourneyStepRepository = MyJourneyStepRepository()
let eventStateRepository: any EventStateRepository = MyEventStateRepository()

let trackJourneyStep = TrackJourneyStep(
    journeyStepRepository: journeyStepRepository,
    eventStateRepository: eventStateRepository,
    policyProvider: policyProvider,
    sequenceMatcher: SequenceMatcher()
)

let evaluateEventPolicy = EvaluateEventPolicy(
    eventStateRepository: eventStateRepository,
    logger: NoOpJourneyLogger(),
    timeProvider: SystemTimeProvider()
)

let eventTracker = EventTracker(
    trackJourneyStep: trackJourneyStep,
    evaluateEventPolicy: evaluateEventPolicy,
    policyProvider: policyProvider,
    logger: NoOpJourneyLogger()
)
```

`NoOpJourneyLogger` swallows everything. To bridge journey events into telemetry, conform your own type to `JourneyLogger` and forward the calls.

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

## Migrating from 1.x to 2.0

Version 2.0 removes the bundled OSLog-based logger implementations and splits the
library into two products. Update call sites as follows:

### Logger replacements

`OSLogJourneyLogger` and `CompactJourneyLogger` have been deleted. Replace them with
either `NoOpJourneyLogger()` or your own `JourneyLogger` adapter.

```swift
// Before (1.x)
let logger = OSLogJourneyLogger()

// After (2.0)
let logger = NoOpJourneyLogger()
// or, to bridge into telemetry, conform your own type to JourneyLogger.
```

### EventTracker requires an explicit logger

`EventTracker.init` no longer provides a default logger. Pass one explicitly.

### AnyHashableSendable is now a closed enum (not a wrapper type)

In 1.x, `AnyHashableSendable` was a type-erased wrapper using `@unchecked Sendable`.
In 2.0, it is a finite enum with explicit cases: `string`, `int`, `double`, `bool`, `date`.

**Update code that manually constructs `AnyHashableSendable`:**

```swift
// Before (1.x)
let value = AnyHashableSendable("some_string")

// After (2.0)
let value: AnyHashableSendable = "some_string"  // ExpressibleByStringLiteral
let value = AnyHashableSendable.string("some_string")  // explicit case
```

Dictionary literals automatically use the correct conformances, so most call sites need no changes:

```swift
let parameters: [String: AnyHashableSendable] = [
    "id": "123",        // automatically .string("123")
    "count": 5,         // automatically .int(5)
    "active": true,     // automatically .bool(true)
    "rating": 4.5,      // automatically .double(4.5)
]
```

Retrieve typed values by pattern-matching on the case or calling `value(as:)`:

```swift
if case let .string(id) = parameters["id"] {
    print("ID: \(id)")
}
// or
if let id = parameters["id"]?.value(as: String.self) {
    print("ID: \(id)")
}
```

### Session-scoped repositories renamed; legacy in-memory copies moved to `JourneyEventsTesting`

The non-persistent repositories now ship in two places, with different intent:

| Old name (1.x) | New home in 2.0 | Intent |
| --- | --- | --- |
| `InMemoryEventStateRepository` | `SessionEventStateRepository` (in `JourneyEvents`) | Production-safe session-only store. Use this in your composition root. |
| `InMemoryJourneyStepRepository` | `SessionJourneyStepRepository` (in `JourneyEvents`) | Production-safe session-only store. Use this in your composition root. |
| `InMemoryEventStateRepository` | `InMemoryEventStateRepository` (in `JourneyEventsTesting`) | Test scaffolding. Use only from test targets. |
| `InMemoryJourneyStepRepository` | `InMemoryJourneyStepRepository` (in `JourneyEventsTesting`) | Test scaffolding. Use only from test targets. |

**Production wiring.** If you were instantiating `InMemoryEventStateRepository` /
`InMemoryJourneyStepRepository` from app code, switch to the `Session…`
counterparts; they live in the main `JourneyEvents` module:

```swift
import JourneyEvents

let stepRepository = SessionJourneyStepRepository()
let stateRepository = SessionEventStateRepository()
```

**Test wiring.** If you were using the in-memory repositories from tests, the
old types are still available but now ship from `JourneyEventsTesting`. Add the
dependency to your test target and import it explicitly:

```swift
import JourneyEvents
import JourneyEventsTesting   // new — required for the in-memory repos
```

`EventStateRepositorySelector`'s persistent and session parameters now both
default to the production repositories (`UserDefaultsEventStateRepository` and
`SessionEventStateRepository` respectively). You can omit them when the
defaults fit, or supply alternatives for tests:

```swift
let selector = EventStateRepositorySelector(policyProvider: policies)
```

### Platform requirements

The minimum deployment target moved to iOS 16 / macOS 13 / tvOS 16 / watchOS 9 to
support `OSAllocatedUnfairLock` in `JourneyEventsTesting`.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Author

Jesús Alfredo Hernández Alarcón
