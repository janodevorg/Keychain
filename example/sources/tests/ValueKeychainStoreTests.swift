import Keychain
import XCTest

final class ValueKeychainStoreTests: XCTestCase
{
    func testReadWrite() async throws
    {
        let account = "test-safeToDelete-\(UUID().uuidString)"
        let keychain = ValueKeychainStore(accountName: account, accessGroup: accessGroup)

        // initially empty
        let expectedNil = try keychain.get()
        XCTAssertNil(expectedNil)

        // set a value
        let value = "bananas"
        try keychain.set(value)
        let expectedValue = try keychain.get()
        XCTAssertEqual(expectedValue, value)

        // remove the value
        try keychain.set(nil)
        let expectedRemoved = try keychain.get()
        XCTAssertNil(expectedRemoved)
    }
}
