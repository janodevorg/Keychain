
/// An interface to a store that reads and writes a single value.
public protocol ValueStore {
    /// Synchronously retrieves the value from the store.
    func get() throws -> String?

    /// Synchronously sets the value in the store.
    func set(_ value: String?) throws

    /// Asynchronously retrieves the value from the store.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func get() async throws -> String?

    /// Asynchronously sets the value in the store.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func set(_ value: String?) async throws
}
