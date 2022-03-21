import Keychain
import XCTest

final class ObservedValueStoreTests: XCTestCase
{
    private var store: ObservedValueStore!
    private let account = "test-deleteme-\(UUID().uuidString)"
    private var observedValue: String? = ""

    func testObservation() async throws
    {
        let keychain = ValueKeychainStore(accountName: account, accessGroup: accessGroup)
        store = ObservedValueStore(valueStore: keychain)
        let observation = store.observeChanges { [weak self] value in
            self?.observedValue = value
        }

        // when writing, it notifies observers
        let bananas = "bananas"
        try store.set(bananas)
        XCTAssertEqual(observedValue, bananas)

        // when I stop observing and write, it doesn’t notify observers
        observation.stopObserving()
        let oranges = "oranges"
        try store.set(oranges)
        XCTAssertNotEqual(observedValue, oranges)
    }
}
