@testable import Keychain
import os
import XCTest

final class KeychainTests: XCTestCase
{
    private let account = "test-safetodelete-\(UUID().uuidString)"
    private var keychain: Keychain!
    private let log = Logger(subsystem: "dev.jano", category: "keychain")

    override func setUp() async throws {
        keychain = Keychain(type:
            KeychainType.genericPassword(
                account: account,
                accessGroup: accessGroup
            )
        )
        do {
            let _: String? = try keychain.read()
            try keychain.delete()
        } catch let KeychainError.unexpectedStatus(status, _) where status == errSecItemNotFound {
            // -25300 The specified item could not be found in the keychain.
        } catch {
            XCTFail()
        }
        log.debug("Setup completed.")
    }

    func testCreateRead() async throws {
        let value = "green"
        try keychain.create(value, extraAttributes: [
            String(kSecAttrDescription): NSString("A twitter password"), // human readable
            String(kSecAttrLabel): NSString("Twitter password.") // visible label
        ])
        let actual: String? = try keychain.read()
        XCTAssertEqual(value, actual)
        log.debug("It reads a value created.")
    }

    func testCreateUpdateRead() async throws {
        let value = "green"
        try keychain.create("orange")
        try keychain.update(value)
        let actual: String? = try keychain.read()
        XCTAssertEqual(value, actual)
        log.debug("It creates, updates, and reads the updated value.")
    }

    func testCreateDelete() async throws {
        let value = "green"
        try keychain.create(value)
        try keychain.delete()
        do {
            let _: String? = try keychain.read()
            XCTFail("Expected to throw not found -25300")
        } catch {
            guard case let KeychainError.unexpectedStatus(status, _) = error, status == -25300 else {
                XCTFail("Expected item not to be found.")
                return
            }
        }
        log.debug("It creates, deletes, and can’t find the value deleted.")
    }
}
