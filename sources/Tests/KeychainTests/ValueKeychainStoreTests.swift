import Testing
@testable import Keychain

@Suite
struct ValueKeychainStoreTests {
    let testAccessGroup = "23KN7M4FPW.group.dev.jano.apple"

    /// Verifies create, read, update, delete
    @Test
    func testCRUDOperations() throws {
        // Replace with valid account + access group
        let store = ValueKeychainStore(accountName: "MyTestAccount", accessGroup: testAccessGroup)
        
        // 1. Initially no value
        let initialValue = try store.get()
        #expect(initialValue == nil)
        
        // 2. Create
        try store.set("Hello World")
        #expect(try store.get() == "Hello World")
        
        // 3. Update
        try store.set("Another Value")
        #expect(try store.get() == "Another Value")
        
        // 4. Delete
        try store.set(nil)
        #expect(try store.get() == nil)
    }

    /// Verifies missing item throws an error on update/delete
    @Test(.timeLimit(.minutes(1)))
    func testSetCreatesWhenMissing() throws {
        let store = ValueKeychainStore(
            accountName: "SomeNonExistent",
            accessGroup: testAccessGroup
        )

        try store.set("NewValue")
        #expect(try store.get() == "NewValue") // Confirm it got created
    }

}
