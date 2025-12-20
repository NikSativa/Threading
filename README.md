# Threading

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FThreading%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NikSativa/Threading)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FThreading%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NikSativa/Threading)
[![NikSativa CI](https://github.com/NikSativa/Threading/actions/workflows/swift_macos.yml/badge.svg)](https://github.com/NikSativa/Threading/actions/workflows/swift_macos.yml)
[![License](https://img.shields.io/github/license/Iterable/swift-sdk)](https://opensource.org/licenses/MIT)

Threading is a framework that provides type-safe abstractions for thread synchronization and concurrent programming in Swift. It offers a set of tools for working with locks, mutexes, and atomic operations, making concurrent code safer and easier to write.

## Overview

Threading provides several key components:

- **Queue**: A type-safe wrapper around Grand Central Dispatch queues
- **Mutexing**: A protocol for thread-safe value access
- **Locking**: A protocol for basic synchronization primitives
- **AtomicValue**: A property wrapper for thread-safe properties

## Topics

### Queue Management

- ``Queue``: A type-safe wrapper for GCD queues; provides convenient access to system queues, custom queue creation, and safe main-thread access.
- ``Queueable``: A protocol for queue-like types that exposes a common interface for queue operations.
- ``DelayedQueue``: A queue with built-in delay support, ideal for throttling, rate limiting, and cancelable delayed operations.

### Synchronization

- ``Mutexing``: A protocol for synchronized access to values; supports blocking and non-blocking execution with error propagation. Supports `@dynamicCallable` and `@dynamicMemberLookup` for convenient syntax.
- ``Locking``: A protocol for lock implementations, supporting core locking behaviors, including recursive locks. Supports `@dynamicCallable` for functional-style syntax.
- ``AnyMutex``: A type-erased wrapper around any `Mutexing` implementation.
- ``AnyLock``: A type-erased wrapper around any `Locking` implementation.

### Mutex Implementations

- ``SyncMutex``: A native mutex using the system synchronization framework (macOS 15.0+, iOS 18.0+); supports recursive locking and integrates with debugging tools.
- ``OSAllocatedUnfairMutex``: A high-performance mutex using OS-allocated unfair locks (macOS 13.0+, iOS 16.0+).
- ``QueueBarrier``: A mutex that uses dispatch queue barriers for synchronization; useful for queue-based concurrency patterns.
- ``LockedValue``: A generic mutex-backed value container that allows custom locking strategies.

### Property Wrappers

- ``AtomicValue``: A property wrapper that synchronizes access to a property using a configurable mutex.

### Concurrency Utilities

- ``USendable``: A lightweight wrapper for non-Sendable types, useful when bridging legacy types into concurrency contexts. Requires manual thread safety.

## Usage

### Working with Queues

Perform synchronous work on the main thread safely:

```swift
Queue.main.sync {
    // Your task on main thread
}
```

Perform asynchronous work:

```swift
Queue.main.async {
    // Your task on main thread
}
```

Create custom queues with explicit parameters:

```swift
let customQueue = Queue.custom(
    label: "com.example.queue",
    qos: .utility,
    attributes: .serial
)

customQueue.async {
    // Your work here
}
```

Use `DelayedQueue` for delayed or conditional execution:

```swift
// Execute after a delay
let delayed = DelayedQueue.n.asyncAfter(deadline: .now() + 2, queue: .main)
delayed.fire {
    print("Executed after 2 seconds")
}

// Synchronous execution
let sync = DelayedQueue.n.sync(.main)
sync.fire {
    print("Executed synchronously")
}

// Asynchronous execution
let async = DelayedQueue.n.async(.background)
async.fire {
    print("Executed asynchronously")
}
```

### Thread-Safe Value Access

Use mutexes to protect shared values:

```swift
let counter = LockedValue(initialValue: 0)

// Safely modify the value
counter.sync { value in
    value += 1
}

// Get the current value
let currentValue = counter.sync { value in
    return value
}

// Using dynamic callable syntax (functional style)
counter { $0 += 1 }
let doubled = counter { $0 * 2 }
```

Use `trySync` for non-blocking access:

```swift
if let value = counter.trySync({ $0 }) {
    print("Current value: \(value)")
}
```

### AtomicValue Properties

Use the `@AtomicValue` property wrapper for thread-safe properties:

```swift
@AtomicValue var counter = 0

// Using sync method
$counter.sync { $0 += 1 }

// Using dynamic callable syntax (functional style)
$counter { $0 = 10 }

// Direct property access (thread-safe)
counter = 5
let value = counter
```

You can also specify a custom mutex type:

```swift
@AtomicValue(mutexing: SyncMutex.self) var counter = 0
@AtomicValue(lock: .osAllocatedUnfair()) var highPerformance = 0
```

### Concurrency Workarounds

When working with `@MainActor`-isolated APIs:

```swift
Queue.isolatedMain.sync {
    // Access UI elements safely
    view.backgroundColor = .red
}
```

### Working with Non-Sendable Types

The `USendable` type provides a way to work with non-Sendable types in concurrent contexts. It's particularly useful when you need to:

- Access UIKit/AppKit objects from concurrent contexts
- Work with legacy code that hasn't been updated for Swift concurrency
- Bridge between synchronous and asynchronous code

> [!WARNING]
> **Important:** `USendable` doesn't make the wrapped value thread-safe. It only marks the type as `@unchecked Sendable`. You must ensure thread safety through other means, such as:
> - Accessing the value only on the main thread
> - Using proper synchronization mechanisms
> - Following the value's thread-safety requirements

```swift
// Wrap a UIKit view
let unsafe = USendable(ImageView())

// Access it safely on the main thread
Queue.main.async {
    let view = unsafe.value
    view.backgroundColor = .red
}

// Or use it in a Task with proper synchronization
Task { @MainActor in
    let view = unsafe.value
    view.backgroundColor = .blue
}
```

## Advanced Features

### Dynamic Callable Syntax

Both `Locking` and `Mutexing` protocols support `@dynamicCallable`, allowing functional-style syntax:

```swift
// Using Locking protocol
let lock: Locking = AnyLock.default
lock {
    // Critical section
    performWork()
}

// Using Mutexing protocol
let counter = LockedValue(initialValue: 0)
counter { $0 += 1 }
let value = counter { $0 }

// Using AtomicValue
@AtomicValue var count = 0
$count.sync { $0 += 1 }

// Or using dynamic callable syntax (works for any type)
$count { $0 += 1 }
```

### Dynamic Member Lookup

`Mutexing` and `AtomicValue` support `@dynamicMemberLookup` for convenient property access:

```swift
@AtomicValue var user = User(name: "Alice", age: 30)

// Thread-safe property access
let name = user.name  // Automatically synchronized
user.age = 31        // Thread-safe mutation
```

## Best Practices

1. **Keep Critical Sections Short**
   ```swift
   // Good
   counter.sync { value in
       value += 1
   }

   // Avoid
   counter.sync { value in
       // Long-running operations block other threads
       performExpensiveOperation()
   }
   ```

2. **Choose Appropriate Mutex Type**
   - Use `SyncMutex` for general-purpose synchronization (macOS 15.0+, iOS 18.0+)
   - Use `OSAllocatedUnfairMutex` for high-performance scenarios (macOS 13.0+, iOS 16.0+)
   - Use `QueueBarrier` when working with GCD queues
   - Use `LockedValue` when you need custom lock behavior
   - Use `AnyLock.default` (recursive pthread) as a safe default

3. **Handle Errors Properly**
   ```swift
   do {
       try mutex.sync { value in
           try performRiskyOperation(value)
       }
   } catch {
       // Handle error appropriately
   }
   ```

4. **Use Try-Lock for Non-Blocking Operations**
   ```swift
   // Non-blocking access
   if let result = lock.trySync({ computeValue() }) {
       // Lock acquired, work completed
   } else {
       // Lock busy, handle accordingly
   }
   ```

## Requirements

- iOS 13.0+ / macOS 11.0+ / tvOS 13.0+ / watchOS 6.0+ / visionOS 1.0+
- Swift 5.5+
- Xcode 13.0+

> **Note:** Some features require newer platform versions:
> - `SyncMutex`: macOS 15.0+, iOS 18.0+, tvOS 18.0+, watchOS 11.0+, visionOS 2.0+
> - `OSAllocatedUnfairMutex` / `OSAllocatedUnfairLock`: macOS 13.0+, iOS 16.0+, tvOS 16.0+, watchOS 9.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/NikSativa/Threading.git", from: "1.0.0")
]
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
