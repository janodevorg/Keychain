import Foundation
import Keychain
import Testing

@Suite("ObservedValueStore Tests")
struct ObservedValueStoreTests {
    @Test("Observation functionality")
    func observation() async throws {
        let account = "test-deleteme-\(UUID().uuidString)"
        let keychain = ValueKeychainStore(accountName: account, accessGroup: accessGroup)
        let store = ObservedValueStore(valueStore: keychain)
        
        var observedValue: String? = ""
        let observation = store.observeChanges { value in
            observedValue = value
        }

        // when writing, it notifies observers
        let bananas = "bananas"
        try await store.set(bananas)
        #expect(observedValue == bananas)

        // when I stop observing and write, it doesn't notify observers
        observation.stopObserving()
        let oranges = "oranges"
        try await store.set(oranges)
        #expect(observedValue != oranges)
        
        // Clean up
        try? await store.set(nil as String?)
    }
}
