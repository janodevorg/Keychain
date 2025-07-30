import Foundation
import Keychain
import Testing

@Suite("ValueKeychainStore Tests")
struct ValueKeychainStoreTests {
    @Test("Read and write operations")
    func readWrite() async throws {
        let account = "test-safeToDelete-\(UUID().uuidString)"
        let keychain = ValueKeychainStore(accountName: account, accessGroup: accessGroup)

        // initially empty
        let expectedNil = try await keychain.get()
        #expect(expectedNil == nil)

        // set a value
        let value = "bananas"
        try await keychain.set(value)
        let expectedValue = try await keychain.get()
        #expect(expectedValue == value)

        // remove the value
        try await keychain.set(nil as String?)
        let expectedRemoved = try await keychain.get()
        #expect(expectedRemoved == nil)
    }
}
