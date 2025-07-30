# Design: Concurrency and Thread-Safety

This library provides a thread-safe, modern Swift interface for the system Keychain. But how does it handle concurrency safely and efficiently?

The Keychain APIs are synchronous and not inherently thread-safe. This library solves that by providing both a thread-safe synchronous API and a modern `async/await` API. This is achieved through a combination of a high-performance lock and a clean internal design pattern.

### The Implemented Solution: `NSLock` with a Worker Pattern

The core of the concurrency model is a standard `**NSLock**` combined with a **private worker** pattern.

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
*   **Maximizes Performance:** It allows the use of `NSLock`, which is more performant than its recursive counterpart.
*   **Is Clean:** It cleanly separates the responsibility of synchronization from the core keychain logic.

### Alternatives Considered

Several other concurrency models were considered but ultimately rejected.

#### `NSRecursiveLock`

A recursive lock allows a single thread to acquire the same lock multiple times. While it would have prevented the deadlock caused by re-entrant calls (`readString()` calling `readData()`), it was not chosen for the final design.

The need for a recursive lock is often a "code smell" that indicates tightly coupled internal methods. It solves the symptom (the deadlock) but not the root cause, and it is less performant than a standard `NSLock`.

#### `actor`

Using an `actor` is the most modern approach to state isolation in Swift. An actor would serialize access to the keychain and be perfectly thread-safe. However, it was not a suitable choice for the core `Keychain` type for one primary reason:

*   **An `actor` forces an `async` API.** All interactions with an actor must be `await`ed. A key requirement for this library was to provide **both** a simple, thread-safe *synchronous* API and a modern `async` one. An `actor`-based implementation would have made the synchronous API impossible.

### Conclusion

The final design using `NSLock` with a private worker pattern provides the optimal balance of thread-safety, performance, and API flexibility, successfully supporting both synchronous and asynchronous callers without compromising on robustness.