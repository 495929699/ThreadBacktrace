# ThreadBacktrace

[![CI Status](https://img.shields.io/travis/495929699g@gmail.com/ThreadBacktrace.svg?style=flat)](https://travis-ci.org/495929699g@gmail.com/ThreadBacktrace)
[![Version](https://img.shields.io/cocoapods/v/ThreadBacktrace.svg?style=flat)](https://cocoapods.org/pods/ThreadBacktrace)
[![License](https://img.shields.io/cocoapods/l/ThreadBacktrace.svg?style=flat)](https://cocoapods.org/pods/ThreadBacktrace)
[![Platform](https://img.shields.io/cocoapods/p/ThreadBacktrace.svg?style=flat)](https://cocoapods.org/pods/ThreadBacktrace)

## Example

获取主线程调用栈
```swift
    BacktraceOfMainThread()
```
获取当前线程调用栈
```swift
    BacktraceOfMainThread()
```

解析堆栈符号，需真实的 ASLR
```swift
Symbolic(of stack: [UInt], aslr: Int)
```

## Requirements

## Installation

ThreadBacktrace is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ThreadBacktrace'
```

## Author

公子荣, rongheng.rh@gmail.com

## License

ThreadBacktrace is available under the MIT license. See the LICENSE file for more info.
