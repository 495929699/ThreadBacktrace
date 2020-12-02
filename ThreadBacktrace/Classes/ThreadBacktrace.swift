//
//  ThreadBacktrace.swift
//  ThreadBacktrace
//
//  Created by 荣恒 on 2019/9/5.
//  Copyright © 2019 荣恒. All rights reserved.
//

import Foundation
import Darwin

/// 获取主线程调用栈
public func BacktraceOfMainThread() -> [String] {
    return _mach_callstack(_machThread(from: .main))
        .map { $0.info }
}

/// 获取当前线程调用栈
public func BacktraceOfCurrentThread() -> [String] {
    return _mach_callstack(_machThread(from: .current))
        .map { $0.info }
}

/// 获取指定线程调用栈数据 StackSymbol
public func BacktraceOf(thread: Thread) -> [StackSymbol] {
    return _mach_callstack(_machThread(from: thread))
}

public func Dl_BacktraceOfCurrentThread() -> [StackSymbol] {
    return dl_mach_callstack(_machThread(from: .current))
}

public func Symbolic(of stack : [String]) -> [String] {
    guard !stack.isEmpty else {
        return []
    }
        
    let address : [UInt64] = stack.map { value in
        var address : UInt64 = 0
        Scanner(string: value).scanHexInt64(&address)
        return address
    }
    
    let symbols : [String] = address.map { value in
        return _stackSymbol(from: UInt(value), index: 0).info
    }
    
    return symbols
}

//MARK: 线程相关 私有
@_silgen_name("mach_backtrace")
public func backtrace(_ thread: thread_t,
                      stack: UnsafeMutablePointer<UnsafeMutableRawPointer?>,
                      maxSymbols: Int32) -> Int32

/// 获取 指定mach线程 回调栈
private func _mach_callstack(_ thread: thread_t) -> [StackSymbol] {
    var symbols : [StackSymbol] = []
    let stackSize : UInt32 = 128
    let addrs = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: Int(stackSize))
    defer { addrs.deallocate() }
    let frameCount = backtrace(thread, stack: addrs, maxSymbols: Int32(stackSize))
    
    let buf = UnsafeBufferPointer(start: addrs, count: Int(frameCount))

    for (index, addr) in buf.enumerated() {
        guard let addr = addr else { continue }
        let addrValue = UInt(bitPattern: addr)
        let symbol = _stackSymbol(from: addrValue, index: index)
        symbols.append(symbol)
    }
    return symbols
}

private func dl_mach_callstack(_ thread: thread_t) -> [StackSymbol] {
    var symbols : [StackSymbol] = []
    let stackSize : UInt32 = 128
    let addrs = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: Int(stackSize))
    defer { addrs.deallocate() }
    let frameCount = backtrace(thread, stack: addrs, maxSymbols: Int32(stackSize))
    
    let buf = UnsafeBufferPointer(start: addrs, count: Int(frameCount))

    for (index, addr) in buf.enumerated() {
        guard let addr = addr else { continue }
        let addrValue = UInt(bitPattern: addr)
        let symbol = dl_stackSymbol(from: addrValue, index: index)
        symbols.append(symbol)
    }
    return symbols
}

/// Thread to mach 线程
private func _machThread(from thread: Thread) -> thread_t {
    guard let (threads, count) = _machAllThread() else {
        return mach_thread_self()
    }

    if thread.isMainThread {
        return get_mach_main_thread()
    }

    var name : [Int8] = []
    let originName = thread.name
    
    for i in 0 ..< count {
        let index = Int(i)
        if let p_thread = pthread_from_mach_thread_np((threads[index])) {
            name.append(Int8(Character("\0").ascii ?? 0))
            pthread_getname_np(p_thread, &name, MemoryLayout<Int8>.size * 256)
            if (strcmp(&name, (thread.name!.ascii)) == 0) {
                thread.name = originName
                return threads[index]
            }
        }
    }

    thread.name = originName
    return mach_thread_self()
}

/// 获取所有线程
private func _machAllThread() -> (thread_act_array_t, mach_msg_type_number_t)? {
    /// 线程List
    var threads : thread_act_array_t?
    /// 线程数
    var count : mach_msg_type_number_t = 0
    /// 进程 ID
    let task = mach_task_self_
    
    guard task_threads(task, &(threads), &count) == KERN_SUCCESS else {
        return nil
    }
    
    return (threads!, count)
}

//MARK: extension
extension Character {
    var isAscii: Bool {
        return unicodeScalars.allSatisfy { $0.isASCII }
    }
    var ascii: UInt32? {
        return isAscii ? unicodeScalars.first?.value : nil
    }
}

extension String {
    var ascii : [Int8] {
        var unicodeValues = [Int8]()
        for code in unicodeScalars {
            unicodeValues.append(Int8(code.value))
        }
        return unicodeValues
    }
}
