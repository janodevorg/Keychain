# Design Choices: Locking and Concurrency in the Keychain Library

This document outlines the evolution of the concurrency model in this library, specifically the choices made regarding thread-safety and locking mechanisms.

## V1: The Initial Problem - Lack of Thread-Safety

The original version of the library was not thread-safe. Direct calls to the Keychain APIs from multiple threads could lead to race conditions, unpredictable behavior, and crashes. The first priority was to introduce a locking mechanism to serialize access and guarantee data integrity.

## V2: The Deadlock - `NSLock` and Re-entrant Calls

The initial attempt at thread-safety involved adding a standard `NSLock` to serialize all public methods. While simple, this approach immediately introduced a deadlock.

The deadlock occurred because of an internal re-entrant call pattern:

1.  The public `readString()` method would acquire the `NSLock`.
2.  While still holding the lock, it would call the public `readData()` method.
3.  The `readData()` method would then attempt to acquire the *same* `NSLock` that was already held by the current thread.

Since `NSLock` is a non-recursive lock, this second acquisition attempt by the same thread resulted in a permanent deadlock, causing the test suite to hang.

## V3: The Pragmatic Fix - `NSRecursiveLock`

To immediately resolve the deadlock with minimal code changes, the `NSLock` was replaced with an `NSRecursiveLock`. A recursive lock allows a single thread to acquire the same lock multiple times without deadlocking.

While this fixed the hanging test, the need for a recursive lock is often considered a "code smell." It indicates that the internal responsibilities and call patterns of the class are tightly coupled. It solves the symptom (the deadlock) but not the underlying design issue.

## V4: The Final Solution - Refactoring for Robustness and Performance

The best long-term solution was to refactor the internal logic to eliminate the need for re-entrant locking altogether. This approach provides a cleaner design and allows the use of the more performant `NSLock`.

The final design follows this pattern:

1.  **Private Worker Methods**: Core logic that interacts directly with the `Security` framework was moved into private "worker" methods (e.g., `_readData()`). These private methods **do not** acquire any locks.
2.  **Public Locking Methods**: The public methods (`readString()`, `readData()`, etc.) are now responsible for a single task: acquiring the `NSLock` and calling the appropriate private worker method.

This refactoring breaks the re-entrant call chain. For example, `readString()` now acquires the lock and calls the private `_readData()`, which does not attempt to acquire the lock again.

This final architecture is superior because it:
-   **Eliminates Deadlocks**: The design makes re-entrant deadlocks impossible.
-   **Improves Performance**: It allows the use of the more efficient `NSLock`.
-   **Enhances Clarity**: It cleanly separates the concerns of synchronization (locking) from the core keychain operations.
