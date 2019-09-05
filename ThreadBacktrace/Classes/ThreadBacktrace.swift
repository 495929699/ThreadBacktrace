//
//  ThreadBacktrace.swift
//  ThreadBacktrace
//
//  Created by 荣恒 on 2019/9/5.
//  Copyright © 2019 荣恒. All rights reserved.
//

import Foundation

/// 获取主线程调用栈
public func backtraceOfMainThread() -> [BacktraceFrame] {
    let info = BSBacktraceLogger.bs_backtrace(of: Thread.main)
    return info.map(BacktraceFrame.init(info: ))
}

/// 获取当前线程调用栈
public func backtraceOfCurrentThread() -> [BacktraceFrame] {
    let info = BSBacktraceLogger.bs_backtrace(of: Thread.current)
    return info.map(BacktraceFrame.init(info: ))
}

/// 线程回调栈帧模型
public struct BacktraceFrame: CustomDebugStringConvertible {
    let imageName: String
    let address: String
    let funcName: String
    let offset: String
    
    public var debugDescription: String {
        return imageName.utf8CString.withUnsafeBufferPointer { (imageBuffer: UnsafeBufferPointer<CChar>) -> String in
            #if arch(x86_64) || arch(arm64)
            return String(format: "%-35s 0x%016llx %@ + %@", UInt(bitPattern: imageBuffer.baseAddress), address, funcName, offset)
            #else
            return String(format: "%-35s 0x%08lx %@ + %@", UInt(bitPattern: imageBuffer.baseAddress), address, funcName, offset)
            #endif
        }
    }
    
    internal init(info: [AnyHashable: Any]) {
        self.imageName = (info[BacktraceImageName] as? String) ?? "???"
        self.address = (info[BacktraceAddress] as? String) ?? "???"
        self.offset = (info[BacktraceOffset] as? String) ?? "???"
        let _funcName = (info[BacktraceFuncName] as? String) ?? "???"
        self.funcName = _stdlib_demangleName(_funcName)
    }
}

extension Array where Element == BacktraceFrame {
    /// 打印调用栈
    public func log() {
        for value in self {
            print(" \(value)")
        }
    }
}

@_silgen_name("swift_demangle")
func _stdlib_demangleImpl(
    mangledName: UnsafePointer<CChar>?,
    mangledNameLength: UInt,
    outputBuffer: UnsafeMutablePointer<CChar>?,
    outputBufferSize: UnsafeMutablePointer<UInt>?,
    flags: UInt32
    ) -> UnsafeMutablePointer<CChar>?

/// 将Swift方法名还原
func _stdlib_demangleName(_ mangledName: String) -> String {
    return mangledName.utf8CString.withUnsafeBufferPointer {
        (mangledNameUTF8CStr) in
        
        let demangledNamePtr = _stdlib_demangleImpl(
            mangledName: mangledNameUTF8CStr.baseAddress,
            mangledNameLength: UInt(mangledNameUTF8CStr.count - 1),
            outputBuffer: nil,
            outputBufferSize: nil,
            flags: 0)
        
        if let demangledNamePtr = demangledNamePtr {
            let demangledName = String(cString: demangledNamePtr)
            free(demangledNamePtr)
            return demangledName
        }
        return mangledName
    }
}


