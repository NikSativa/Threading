# NQueue

[![Build-Test](https://github.com/NikSativa/NQueue/actions/workflows/Build_Test.yml/badge.svg)](https://github.com/NikSativa/NQueue/actions/workflows/Build_Test.yml)
[![GitHub license](https://img.shields.io/github/license/NikSativa/NQueue.svg)](https://github.com/NikSativa/NQueue/blob/main/LICENSE)
[![latest release](https://img.shields.io/github/release/NikSativa/NQueue)](https://GitHub.com/NikSativa/NQueue/releases/)
[![latest tag](https://img.shields.io/github/tag/NikSativa/NQueue)](https://GitHub.com/NikSativa/NQueue/tags/)

Wrapper of GCD queue with few cool features

safe execution of a synchronous task on the main thread **from any thread**
‘’’swift
Queue.main.sync {
    // your task on main thread
}
‘’’

**Queueable** protocol can help you test your code without threading by overriding real implementation via your own mock or existing Fake from SpryKit framework

**DelayedQueue** make it simple to manage task execution as parameter at your discretion

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

ps:
as all N-frameworks, this was covered by unit tests and contains independent TestHelpers framework.
