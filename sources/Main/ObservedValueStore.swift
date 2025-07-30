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
public final class ObservedValueStore: ValueStore, @unchecked Sendable
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
        try lock.withLock {
            try valueStore.get()
        }
    }

    public func set(_ value: String?) throws {
        try valueStore.set(value)
        let localObservers = lock.withLock { Array(observers.values) }
        for notify in localObservers {
            notify(value)
        }
    }

    @discardableResult
    public func observeChanges(callback: @escaping (String?) -> Void) -> KeychainObservation {
        let id = lock.withLock {
            let id = UUID()
            observers[id] = callback
            return id
        }

        return KeychainObservation { [weak self] in
            _ = self?.lock.withLock {
                self?.observers.removeValue(forKey: id)
            }
        }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public extension ObservedValueStore {
    func get() async throws -> String? {
        try await valueStore.get()
    }

    func set(_ value: String?) async throws {
        try await valueStore.set(value)
        let localObservers = lock.withLock { Array(observers.values) }
        for notify in localObservers {
            notify(value)
        }
    }
}



