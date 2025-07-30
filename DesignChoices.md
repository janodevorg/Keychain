# Design: Concurrency and Thread-Safety

### `NSLock` with a Worker Pattern

The Keychain APIs are synchronous and not inherently thread-safe. This library provides thread-safe operations using `NSLock` and a private worker pattern.

Public-facing methods are responsible for acquiring the lock, while the actual keychain operations are delegated to private "worker" methods that don't handle locking themselves.

{% highlight swift %}
final class Keychain {
    private let lock = NSLock()

    // Public method handles locking
    public func readData() throws -> Data? {
        try lock.withLock {
            try _readData()
        }
    }

    // Private "worker" does the actual work, no lock here
    private func _readData() throws -> Data? {
        // ... actual SecItemCopyMatching logic ...
    }
}
{% endhighlight %}

This design was chosen because it:
*   **Prevents Deadlocks:** It completely avoids the possibility of re-entrant calls that would cause a deadlock.
*   **Maximizes Performance:** It allows the use of `NSLock`, which is more performant than its recursive counterpart (NSRecursiveLock).
*   **Is Clean:** It cleanly separates the responsibility of synchronization from the core keychain logic.

### Alternatives Considered

#### `NSRecursiveLock`

A recursive lock allows a single thread to acquire the same lock multiple times. However,  the need for a recursive lock is often a "code smell" that indicates tightly coupled internal methods. It solves the symptom (the deadlock) but not the root cause, and it is less performant than a standard `NSLock`.

#### `actor`

Using an `actor` is the most modern approach to state isolation in Swift. An actor would serialize access to the keychain and be perfectly thread-safe. However, it forces an `async` API. All interactions with an actor must be `await`ed. This library provide both a simple, thread-safe synchronous API and a modern `async` one.

### Conclusion

Using `NSLock` with a private worker pattern provides thread-safety, performance, and supports both synchronous and asynchronous callers.
