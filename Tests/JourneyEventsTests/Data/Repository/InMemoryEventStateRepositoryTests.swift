//
//  Copyright © 2026 Jesús Alfredo Hernández Alarcón. All rights reserved.
//

@testable import JourneyEvents
import Testing

@Suite("InMemoryEventStateRepository Tests")
struct InMemoryEventStateRepositoryTests {
    // MARK: - Counter Tests

    @Suite("Counter Operations")
    struct CounterOperationTests {
        @Test("GetCount returns zero for new policy ID")
        func getCount_returnsZeroForNewPolicyID() async {
            let repository = InMemoryEventStateRepository()

            let count = await repository.getCount(policyID: "new_policy")

            #expect(count == 0)
        }

        @Test("IncrementCount increments counter correctly")
        func incrementCount_incrementsCounterCorrectly() async {
            let repository = InMemoryEventStateRepository()

            await repository.incrementCount(policyID: "test_policy")
            await repository.incrementCount(policyID: "test_policy")
            await repository.incrementCount(policyID: "test_policy")

            let count = await repository.getCount(policyID: "test_policy")

            #expect(count == 3)
        }

        @Test("IncrementCount maintains separate counters for different policies")
        func incrementCount_maintainsSeparateCountersForDifferentPolicies() async {
            let repository = InMemoryEventStateRepository()

            await repository.incrementCount(policyID: "policy_a")
            await repository.incrementCount(policyID: "policy_a")
            await repository.incrementCount(policyID: "policy_b")

            let countA = await repository.getCount(policyID: "policy_a")
            let countB = await repository.getCount(policyID: "policy_b")

            #expect(countA == 2)
            #expect(countB == 1)
        }

        @Test("ResetCount resets counter to zero")
        func resetCount_resetsCounterToZero() async {
            let repository = InMemoryEventStateRepository()

            await repository.incrementCount(policyID: "test_policy")
            await repository.incrementCount(policyID: "test_policy")
            await repository.resetCount(policyID: "test_policy")

            let count = await repository.getCount(policyID: "test_policy")

            #expect(count == 0)
        }

        @Test("ResetCount handles non-existent policy gracefully")
        func resetCount_handlesNonExistentPolicyGracefully() async {
            let repository = InMemoryEventStateRepository()

            await repository.resetCount(policyID: "non_existent")

            let count = await repository.getCount(policyID: "non_existent")

            #expect(count == 0)
        }
    }

    // MARK: - Last Action Timestamp Tests

    @Suite("Last Action Timestamp Operations")
    struct LastActionTimestampTests {
        @Test("GetLastActionTriggeredTimestamp returns nil for policy without timestamp")
        func getLastActionTriggeredTimestamp_returnsNilForPolicyWithoutTimestamp() async {
            let repository = InMemoryEventStateRepository()

            let timestamp = await repository.getLastActionTriggeredTimestamp(
                policyID: "test_policy",
            )

            #expect(timestamp == nil)
        }

        @Test("SetLastActionTriggeredTimestamp stores and retrieves timestamp")
        func setLastActionTriggeredTimestamp_storesAndRetrievesTimestamp() async {
            let repository = InMemoryEventStateRepository()
            let testTimestamp: Int64 = 1_234_567_890_000

            await repository.setLastActionTriggeredTimestamp(
                policyID: "test_policy",
                timestamp: testTimestamp,
            )

            let retrieved = await repository.getLastActionTriggeredTimestamp(
                policyID: "test_policy",
            )

            #expect(retrieved == testTimestamp)
        }

        @Test("SetLastActionTriggeredTimestamp updates existing timestamp")
        func setLastActionTriggeredTimestamp_updatesExistingTimestamp() async {
            let repository = InMemoryEventStateRepository()
            let firstTimestamp: Int64 = 1000
            let secondTimestamp: Int64 = 2000

            await repository.setLastActionTriggeredTimestamp(
                policyID: "test_policy",
                timestamp: firstTimestamp,
            )
            await repository.setLastActionTriggeredTimestamp(
                policyID: "test_policy",
                timestamp: secondTimestamp,
            )

            let retrieved = await repository.getLastActionTriggeredTimestamp(
                policyID: "test_policy",
            )

            #expect(retrieved == secondTimestamp)
        }

        @Test("SetLastActionTriggeredTimestamp maintains separate timestamps for policies")
        func setLastActionTriggeredTimestamp_maintainsSeparateTimestampsForPolicies() async {
            let repository = InMemoryEventStateRepository()

            await repository.setLastActionTriggeredTimestamp(
                policyID: "policy_a",
                timestamp: 1000,
            )
            await repository.setLastActionTriggeredTimestamp(
                policyID: "policy_b",
                timestamp: 2000,
            )

            let timestampA = await repository.getLastActionTriggeredTimestamp(
                policyID: "policy_a",
            )
            let timestampB = await repository.getLastActionTriggeredTimestamp(
                policyID: "policy_b",
            )

            #expect(timestampA == 1000)
            #expect(timestampB == 2000)
        }
    }

    // MARK: - Last Counted Step Timestamp Tests

    @Suite("Last Counted Step Timestamp Operations")
    struct LastCountedStepTimestampTests {
        @Test("GetLastCountedStepTimestamp returns nil for policy without timestamp")
        func getLastCountedStepTimestamp_returnsNilForPolicyWithoutTimestamp() async {
            let repository = InMemoryEventStateRepository()

            let timestamp = await repository.getLastCountedStepTimestamp(
                policyID: "test_policy",
            )

            #expect(timestamp == nil)
        }

        @Test("SetLastCountedStepTimestamp stores and retrieves timestamp")
        func setLastCountedStepTimestamp_storesAndRetrievesTimestamp() async {
            let repository = InMemoryEventStateRepository()
            let testTimestamp: Int64 = 5000

            await repository.setLastCountedStepTimestamp(
                policyID: "test_policy",
                timestamp: testTimestamp,
            )

            let retrieved = await repository.getLastCountedStepTimestamp(
                policyID: "test_policy",
            )

            #expect(retrieved == testTimestamp)
        }

        @Test("SetLastCountedStepTimestamp updates existing timestamp")
        func setLastCountedStepTimestamp_updatesExistingTimestamp() async {
            let repository = InMemoryEventStateRepository()

            await repository.setLastCountedStepTimestamp(
                policyID: "test_policy",
                timestamp: 1000,
            )
            await repository.setLastCountedStepTimestamp(
                policyID: "test_policy",
                timestamp: 2000,
            )

            let retrieved = await repository.getLastCountedStepTimestamp(
                policyID: "test_policy",
            )

            #expect(retrieved == 2000)
        }

        @Test("SetLastCountedStepTimestamp maintains separate timestamps for policies")
        func setLastCountedStepTimestamp_maintainsSeparateTimestampsForPolicies() async {
            let repository = InMemoryEventStateRepository()

            await repository.setLastCountedStepTimestamp(
                policyID: "policy_a",
                timestamp: 3000,
            )
            await repository.setLastCountedStepTimestamp(
                policyID: "policy_b",
                timestamp: 4000,
            )

            let timestampA = await repository.getLastCountedStepTimestamp(
                policyID: "policy_a",
            )
            let timestampB = await repository.getLastCountedStepTimestamp(
                policyID: "policy_b",
            )

            #expect(timestampA == 3000)
            #expect(timestampB == 4000)
        }
    }

    // MARK: - Integration Tests

    @Suite("Integration Scenarios")
    struct IntegrationScenarios {
        @Test("Repository handles complete policy lifecycle correctly")
        func repository_handlesCompletePolicyLifecycleCorrectly() async {
            let repository = InMemoryEventStateRepository()
            let policyID = "lifecycle_policy"

            // Initial state
            let initialCount = await repository.getCount(policyID: policyID)
            #expect(initialCount == 0)

            // Increment counter multiple times
            await repository.incrementCount(policyID: policyID)
            await repository.incrementCount(policyID: policyID)
            await repository.incrementCount(policyID: policyID)

            let countAfterIncrement = await repository.getCount(policyID: policyID)
            #expect(countAfterIncrement == 3)

            // Record action timestamp
            await repository.setLastActionTriggeredTimestamp(
                policyID: policyID,
                timestamp: 1000,
            )

            // Reset counter (action triggered)
            await repository.resetCount(policyID: policyID)

            let countAfterReset = await repository.getCount(policyID: policyID)
            let timestamp = await repository.getLastActionTriggeredTimestamp(
                policyID: policyID,
            )

            #expect(countAfterReset == 0)
            #expect(timestamp == 1000)
        }
    }
}
