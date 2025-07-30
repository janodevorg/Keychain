import Foundation
import os

/// Result from an observer registration.
/// This object can be used by observers to unregister themselves.
public final class KeychainObservation {
    private let unregister: () -> Void
    public init(unregister: @escaping () -> Void) {
        self.unregister = unregister
    }
    public func stopObserving() {
        unregister()
    }
}

/// A store for a value that can be observed.
public final class ObservedValueStore: ValueStore
{
    private let log = Logger(subsystem: "dev.jano", category: "mytumblr")
    private let lock = NSLock()
    private let valueStore: ValueKeychainStore
    private var observers = [UUID: (String?) -> Void]()

    /// - Parameter valueStore: Implementation backing the value.
    public init(valueStore: ValueKeychainStore) {
        self.valueStore = valueStore
    }

    public func get() throws -> String? {
        lock.lock()
        defer { lock.unlock() }
        
        return try valueStore.get()
    }

    public func set(_ value: String?) throws {
        let localObservers: [(String?) -> Void]
        lock.lock()
        try valueStore.set(value)
        localObservers = Array(observers.values)
        lock.unlock()

        for notify in localObservers {
            notify(value)
        }
    }

    @discardableResult
    public func observeChanges(callback: @escaping (String?) -> Void) -> KeychainObservation {
        lock.lock()
        defer { lock.unlock() }

        let id = UUID()
        observers[id] = callback

        return KeychainObservation { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            defer { self.lock.unlock() }
            self.observers.removeValue(forKey: id)
        }
    }
}
