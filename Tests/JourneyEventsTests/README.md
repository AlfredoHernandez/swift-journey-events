# JourneyEvents Test Suite

Comprehensive test suite for the swift-journey-events package using Swift Testing framework (WWDC 2024).

## Test Coverage

### Total: 106 tests across 30 test suites

## Test Organization

```
Tests/JourneyEventsTests/
├── Domain/
│   ├── Model/
│   │   ├── JourneyStepTests.swift (10 tests)
│   │   ├── AnyHashableSendableTests.swift (10 tests)
│   │   ├── JourneyPatternTests.swift (7 tests)
│   │   ├── EventPolicyTests.swift (6 tests)
│   │   └── PolicyEvaluationTests.swift (5 tests)
│   └── UseCase/
│       ├── SequenceMatcherTests.swift (16 tests)
│       ├── TrackJourneyStepTests.swift (11 tests)
│       └── EvaluateEventPolicyTests.swift (11 tests)
├── Data/
│   └── Repository/
│       ├── InMemoryJourneyStepRepositoryTests.swift (8 tests)
│       └── InMemoryEventStateRepositoryTests.swift (14 tests)
├── Presentation/
│   └── EventTrackerTests.swift (13 tests)
└── Helpers/
    └── TestHelpers.swift (Mock implementations)
```

## Test Suites

### Domain Layer - Models

#### JourneyStep Tests
Tests for journey step creation, parameters, and equality:
- Creating steps with name only
- Creating steps with parameters (String, Int, Bool, Double)
- Custom timestamps
- Equality comparisons

#### AnyHashableSendable Tests
Tests for type-erased parameter wrapper:
- Wrapping and unwrapping different value types
- Literal expression support
- Hashability and equality
- String representation

#### JourneyPattern Tests
Tests for pattern configuration:
- Single-step patterns
- Multi-step patterns (strict/loose)
- Pattern equality
- Edge cases

#### EventPolicy Tests
Tests for policy configuration:
- Basic policies with defaults
- Policies with cooldown
- Session-only policies
- Full custom configuration

#### PolicyEvaluation Tests
Tests for evaluation results:
- Action trigger scenarios
- Cooldown states
- Result equality

### Domain Layer - Use Cases

#### SequenceMatcher Tests
Tests for sequence matching algorithms:
- **Strict Sequence Matching** (7 tests)
  - Exact matches
  - Rejecting intermediates
  - Incomplete sequences
  - Wrong order
- **Loose Sequence Matching** (7 tests)
  - Matches with intermediates
  - Multiple intermediates
  - Order validation
- **Convenience Method** (2 tests)

#### TrackJourneyStep Tests
Tests for step tracking and policy evaluation:
- **Single-Step Pattern Tracking** (4 tests)
  - Recording steps
  - Counter increments
  - Multiple policies
- **Multi-Step Pattern Tracking** (5 tests)
  - Strict sequence completion
  - Loose sequence completion
  - Double-counting prevention
- **Edge Cases** (2 tests)

#### EvaluateEventPolicy Tests
Tests for policy evaluation logic:
- **Basic Threshold Evaluation** (6 tests)
  - Threshold checking
  - Counter reset
  - Logging
- **Cooldown Evaluation** (6 tests)
  - Initial trigger
  - Active cooldown blocking
  - Cooldown expiration
  - Timestamp recording
- **Evaluation Result Content** (2 tests)

### Data Layer - Repositories

#### InMemoryJourneyStepRepository Tests
Tests for in-memory step storage:
- Step recording and counting
- History management
- Recent steps retrieval
- History clearing
- Empty repository handling

#### InMemoryEventStateRepository Tests
Tests for in-memory state storage:
- **Counter Operations** (5 tests)
  - Increment, reset, multiple policies
- **Last Action Timestamp Operations** (4 tests)
  - Storage and retrieval
  - Updates
  - Multiple policies
- **Last Counted Step Timestamp Operations** (4 tests)
  - Storage and retrieval
  - Updates
  - Multiple policies
- **Integration Scenarios** (1 test)
  - Complete policy lifecycle

### Presentation Layer

#### EventTracker Tests
Tests for the main API entry point:
- **Basic Step Recording** (2 tests)
  - Step recording with logging
  - Parameter handling
- **Policy Evaluation** (4 tests)
  - No matching policies
  - Threshold not reached
  - Threshold reached
  - Evaluation logging
- **Policy Trigger Stream** (2 tests)
  - AsyncStream emission
  - No emission when not triggered
- **Manual Policy Checking** (2 tests)
  - RecordStepOnly
  - Manual checking
- **Multiple Policies** (2 tests)
  - Related policy evaluation
  - Multiple matching policies

## Test Helpers

### Mock Implementations
- **MockTimeProvider**: Controllable time for cooldown testing
- **MockPolicyProvider**: Configurable policy provider
- **MockLogger**: Logger that captures all events
- **TestFactory**: Helper methods for creating test objects

## Running Tests

```bash
# Run all tests
swift test

# Run with verbose output
swift test --verbose

# Run specific test suite
swift test --filter "SequenceMatcher Tests"

# Run specific test
swift test --filter "Matches exact sequence"
```

## Swift Testing Features Used

### Macros
- `@Test`: Define individual tests with descriptive names
- `@Suite`: Group related tests into suites
- `#expect()`: Soft assertions that continue on failure
- `#require()`: Hard assertions that stop test on failure (with throws)

### Traits
- Display names for better test output
- Nested suites for logical organization

### Async/Await Support
- Native async test support
- Actor-based test concurrency

## Test Patterns

### Arrange-Act-Assert
All tests follow the AAA pattern:
```swift
@Test("Description of what is tested")
func testName() async {
    // Arrange: Set up test dependencies
    let repository = InMemoryEventStateRepository()

    // Act: Perform the action
    await repository.incrementCount(policyID: "test")

    // Assert: Verify the result
    let count = await repository.getCount(policyID: "test")
    #expect(count == 1)
}
```

### Factory Pattern
TestFactory provides consistent test object creation:
```swift
let policy = TestFactory.createPolicy(
    id: "test_policy",
    actionKey: "test_action",
    steps: ["step1", "step2"],
    threshold: 5
)
```

## Test Coverage Areas

✅ Domain Models
✅ Domain Use Cases
✅ Repository Implementations
✅ Presentation Layer API
✅ Sequence Matching (Strict & Loose)
✅ Policy Evaluation (Threshold & Cooldown)
✅ Async Stream Integration
✅ Concurrency Safety
✅ Edge Cases

## Notes

- All tests use the modern Swift Testing framework (not XCTest)
- Tests are designed for Swift 6 concurrency
- Mock implementations use thread-safe patterns
- Tests verify behavior, not implementation details
