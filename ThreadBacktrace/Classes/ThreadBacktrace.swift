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

/// Thread to mach 线程
private func _machThread(from thread: Thread) -> thread_t {
    var name: [Int8] = [Int8]()
    var count: mach_msg_type_number_t = 0
    var threads: thread_act_array_t!

    guard task_threads(mach_task_self_, &(threads), &count) == KERN_SUCCESS else {
        return mach_thread_self()
    }

    if thread.isMainThread {
        return get_mach_main_thread()
    }

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
