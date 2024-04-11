# Threading

Wrapper of GCD queue with few cool features

Safe execution of a synchronous task on the main thread **from any thread including main**
‘’’swift
Queue.main.sync {
    // your task on main thread
}
‘’’

### Queueable
Protocol can help you test your code without threading by overriding real implementation via your own mock or existing Fake from SpryKit framework.
### DelayedQueue
Make it simple to manage task execution as parameter at your discretion. You can manage not only in what Queue to execute but also how sync or async.

Use standart queues
‘’’swift
Queue.background.async
‘’’

‘’’swift
Queue.utility.asyncAfter
‘’’

or easily make your own
‘’’swift
Queue.custom(label: “my line”).async
‘’’

‘’’swift
Queue.custom(label: “my line”, qos: .utility).async
‘’’

you can never go wrong with creating a queue due to explicit parameters
‘’’swift
Queue.custom(label: “my line”, attributes: .serial).async
‘’’
