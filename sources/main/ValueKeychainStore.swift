import Foundation
import os
import Security

/// Stores a value as a generic password.
public final class ValueKeychainStore: ValueStore
{
    private let log = Logger(subsystem: "dev.jano", category: "keychain")
    private let lock = NSRecursiveLock()
    private let keychain: Keychain

    /**
     Initializes a keychain with an account name.
     - Parameter accountName: Name of the account
     */
    public init(accountName: String, accessGroup: String) {
        keychain = Keychain(type:
            KeychainType.genericPassword(
                account: accountName,
                accessGroup: accessGroup
            )
        )
    }

    /**
     Sets a value.

     If value is nil
        - if value existed is removed
        - if value didn’t exist nothing is done

     If value is not nil
        - if value existed it is updated
        - if value didn’t exist it is created

     - Throws: KeychainError if the operation fails.
    */
    public func set(_ value: String?) throws {
        lock.lock()
        defer { lock.unlock() }

        if let value = value {
            switch try get() {
            case .some: try keychain.update(value)
            case .none: try keychain.create(value)
            }
        } else {
            switch try get() {
            case .some: try keychain.delete()
            case .none: () /* nothing to do */
            }
        }
    }

    /**
     Reads the value.

     - Returns: the value or nil if it didn’t exist.
     - Throws: KeychainError if the operation fails with other than not found.
     */
    public func get() throws -> String? {
        lock.lock()
        defer { lock.unlock() }

        let string: String?
        do {
            string = try keychain.read()
        } catch let KeychainError.unexpectedStatus(status, _) where status == errSecItemNotFound {
            // -25300 The specified item could not be found in the keychain.
            return nil
        } catch let keychainError as KeychainError {
            log.error("\(keychainError)")
            throw keychainError
        }
        return string
    }
}
