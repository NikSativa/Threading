# Threading
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FThreading%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/NikSativa/Threading)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FNikSativa%2FThreading%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/NikSativa/Threading)

Wrapper of GCD queue with few cool features

Safe execution of a synchronous task on the main thread **from any thread including main**
```swift
Queue.main.sync {
    // your task on main thread
}
```

### Queueable
Protocol can help you test your code without threading by overriding real implementation via your own mock or existing Fake from SpryKit framework.

### DelayedQueue
Make it simple to manage task execution as parameter at your discretion. You can manage not only in what Queue to execute but also how - sync or async.

Use standart queues
```swift
Queue.background.async
```

```swift
Queue.utility.asyncAfter
```

or easily make your own
```swift
Queue.custom(label: “my line”).async
```

```swift
Queue.custom(label: “my line”, qos: .utility).async
```

you can never go wrong with creating a queue due to explicit parameters
```swift
Queue.custom(label: “my line”, attributes: .serial).async
```

### Concurrency workarounds

Some times very difficult to avoid concurrency isolation issues. This is a simple solution to avoid it. Just use isolatedMain queue to execute your task on the main thread without any side effects.

```swift
Queue.isolatedMain.sync {
    // your task on main thread
}

Queue.isolatedMain.sync {
    // or return value from main thread
    return 42
}

Queue.isolatedMain.sync {
    // or throw error from main thread
    return try someThrowingFunction()
}
```

UnSendable - is a struct that helps you to avoid concurrency check of non-Sendable objects (ex. using UI elements). It is not a silver bullet, but it can help you to avoid some issues.
> [!WARNING]
> **Use at your own risk.**

```swift
let unsafe = UnSendable(ImageView())
Queue.main.async {
    let view = unsafe.value
    // make your magic
}
```
