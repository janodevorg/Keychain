import Foundation
import os
import Security

/**
 Provides CRUD operations to store pairs of key/value on the keychain.
 The items are stored as generic password items where the key is the
 account and the value is the password.

 This is not thread-safe.
*/
final class Keychain
{
    private let log = Logger(subsystem: "dev.jano", category: "keychain")
    private let baseAttributes: [String: AnyObject]

    init(type: KeychainType) {
        switch type {
        case let .genericPassword(account, accessGroup):
            baseAttributes = [
                String(kSecClass): kSecClassGenericPassword,
                String(kSecAttrAccount): account as AnyObject,
                kSecAttrAccessGroup as String: accessGroup as AnyObject
            ]
        case let .internetPassword(account, service):
            baseAttributes = [
                String(kSecClass): kSecClassInternetPassword,
                String(kSecAttrAccount): account as AnyObject,
                String(kSecAttrService): service as AnyObject
            ]
        }
    }

    /**
     Adds a value.
     - Parameter value: string value to store.
     - Parameter extraAttributes: extra attributes to use on creation, like kSecAttrDescription or kSecAttrLabel.
     - Throws: KeychainError if operation fails, e.g. value already exists.
     */
    func create(_ value: String, extraAttributes: [String: AnyObject] = [:]) throws
    {
        var attributes = baseAttributes
        attributes.merge(extraAttributes) { current, _ in current }
        attributes[String(kSecValueData)] = value.data(using: .utf8)! as AnyObject
        try throwIfError(
            SecItemAdd(attributes as CFDictionary, nil)
        )
    }

    /**
     Reads the item as String.
     - Returns: The value, or nil if not present.
     - Throws: KeychainError if operation fails
     */
    func read() throws -> String?
    {
        guard
            let data: Data = try read(),
            let string = String(data: data, encoding: .utf8) else
        {
            return nil
        }
        return string
    }

    /**
     Reads the item as Data.
     - Returns: The value, or nil if not present.
     - Throws: KeychainError if operation fails
     */
    func read() throws -> Data?
    {
        var query = baseAttributes
        query[String(kSecReturnData)] = kCFBooleanTrue as AnyObject

        var itemCopy: AnyObject? = nil
        try throwIfError(
            SecItemCopyMatching(query as CFDictionary, &itemCopy)
        )
        return itemCopy as? Data
    }

    /**
     Updates a String value.
     - Parameter value: value to update.
     - Returns: true if value is
     - Throws: KeychainError if operation fails. e.g. value doesn’t exist
     */
    func update(_ value: String) throws
    {
        let data = value.data(using: .utf8)!
        try update(data)
    }

    /**
     Updates a Data value.
     - Parameter value: value to update.
     - Returns: true if value is
     - Throws: KeychainError if operation fails. e.g. value doesn’t exist
     */
    func update(_ value: Data) throws
    {
        let query = baseAttributes as CFDictionary
        let attributesToUpdate = [String(kSecValueData): value as AnyObject] as CFDictionary
        try throwIfError(
            SecItemUpdate(query, attributesToUpdate)
        )
    }

    /**
     Removes a value.
     - Returns: true on success.
     - Throws: KeychainError if operation fails. e.g. value doesn’t exist
     */
    func delete() throws
    {
        try throwIfError(
            SecItemDelete(baseAttributes as CFDictionary)
        )
    }

    /**
     - Returns: true if status == errSecSuccess.
     - Throws: KeychainError if status is not successful.
     */
    func throwIfError(_ status: OSStatus) throws
    {
        let statusCopy = Int32(status)
        guard status != errSecSuccess else {
            return
        }
        let message = SecCopyErrorMessageString(status, nil) as String?
        throw KeychainError.unexpectedStatus(statusCopy, message)
    }
}
