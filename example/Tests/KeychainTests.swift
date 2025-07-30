import Foundation
import Keychain
import os
import Testing

@Suite("ValueKeychainStore Low-Level Tests")
struct ValueKeychainStoreLowLevelTests {
    private let account = "test-safetodelete-\(UUID().uuidString)"
    private let log = Logger(subsystem: "dev.jano", category: "keychain")
    
    private var keychain: ValueKeychainStore {
        ValueKeychainStore(accountName: account, accessGroup: accessGroup)
    }

    @Test("Store and retrieve value")
    func storeRetrieveValue() async throws {
        let keychain = self.keychain
        
        // Clean up any existing value
        try? await keychain.set(nil as String?)
        
        let value = "green"
        try await keychain.set(value)
        let actual = try await keychain.get()
        #expect(actual == value)
        log.debug("It stores and retrieves a value.")
        
        // Clean up
        try? await keychain.set(nil as String?)
    }

    @Test("Update existing value")
    func updateValue() async throws {
        let keychain = self.keychain
        
        // Clean up any existing value
        try? await keychain.set(nil as String?)
        
        let originalValue = "orange"
        let updatedValue = "green"
        
        try await keychain.set(originalValue)
        try await keychain.set(updatedValue)
        let actual = try await keychain.get()
        #expect(actual == updatedValue)
        log.debug("It updates an existing value.")
        
        // Clean up
        try? await keychain.set(nil as String?)
    }

    @Test("Delete value")
    func deleteValue() async throws {
        let keychain = self.keychain
        
        // Clean up any existing value
        try? await keychain.set(nil as String?)
        
        let value = "green"
        try await keychain.set(value)
        try await keychain.set(nil as String?) // Delete by setting to nil
        
        let actual = try await keychain.get()
        #expect(actual == nil)
        log.debug("It deletes a value by setting to nil.")
    }
}
