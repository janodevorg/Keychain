/// An interface to a store that reads and writes a single value.
public protocol ValueStore {
    func get() throws -> String?
    func set(_ value: String?) throws
}
