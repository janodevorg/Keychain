import Foundation
import os
import Security

/// Stores a value as a generic password.
public final class ValueKeychainStore: ValueStore, @unchecked Sendable
{
    private let log = LoggerFactory.keychain.logger()
    private let lock = NSLock()
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
        try lock.withLock {
            if let value = value {
                do {
                    try keychain.update(value)
                } catch let KeychainError.unexpectedStatus(status, _) where status == errSecItemNotFound {
                    try keychain.create(value)
                }
            } else {
                do {
                    try keychain.delete()
                } catch let KeychainError.unexpectedStatus(status, _) where status == errSecItemNotFound {
                    () // Do nothing, item does not exist.
                }
            }
        }
    }

    /**
     Reads the value.

     - Returns: the value or nil if it didn’t exist.
     - Throws: KeychainError if the operation fails with other than not found.
     */
    public func get() throws -> String? {
        try lock.withLock {
            let string: String?
            do {
                string = try keychain.readString()
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
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ValueKeychainStore {
    func get() async throws -> String? {
        try await Task.detached {
            try self.get()
        }.value
    }

    func set(_ value: String?) async throws {
        try await Task.detached {
            try self.set(value)
        }.value
    }
}



