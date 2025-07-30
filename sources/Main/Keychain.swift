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
    private let log = LoggerFactory.keychain.logger()
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
        attributes[String(kSecValueData)] = Data(value.utf8) as AnyObject
        try throwIfError(
            SecItemAdd(attributes as CFDictionary, nil)
        )
    }

    /**
     Reads the item as String.
     - Returns: The value, or nil if not present.
     - Throws: KeychainError if operation fails
     */
    func readString() throws -> String?
    {
        guard
            let data: Data = try readData(),
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
    func readData() throws -> Data?
    {
        var query = baseAttributes
        query[String(kSecReturnData)] = kCFBooleanTrue as AnyObject

        var itemCopy: AnyObject?
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
        let data = Data(value.utf8)
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
        let keychainError = KeychainError.unexpectedStatus(statusCopy, message)
        if status == errSecMissingEntitlement {
            // -34018 A required entitlement isn't present.
            let accessGroup = baseAttributes[kSecAttrAccessGroup as String]?.description ?? ""
            log.error("""
                \n🚨 \(String(status)) \(message ?? "")
                Edit your app entitlements file to include the access group \"\(accessGroup)\"
                For troubleshooting see https://developer.apple.com/forums/thread/114456
            """)
        }
        throw keychainError
    }
}
