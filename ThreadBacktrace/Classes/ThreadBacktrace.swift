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
public func BacktraceOfMainThread() -> [BacktraceFrame] {
    return br_backtraceOfNSThread(Thread.main)
        .map(BacktraceFrame.init(info: ))
}

/// 获取当前线程调用栈
public func BacktraceOfCurrentThread() -> [BacktraceFrame] {
    return br_backtraceOfNSThread(Thread.current)
        .map(BacktraceFrame.init(info: ))
}

/// 获取指定线程调用栈
public func BacktraceOf(thread: Thread) -> [BacktraceFrame] {
    return br_backtraceOfNSThread(thread)
        .map(BacktraceFrame.init(info: ))    
}

/**
 NSArray<NSArray<NSDictionary*>*>* bs_backtraceOfAllThread() {
 thread_act_array_t threads;
 mach_msg_type_number_t thread_count = 0;
 const task_t this_task = mach_task_self();
 kern_return_t kr = task_threads(this_task, &threads, &thread_count);
 
 NSMutableArray *result = [NSMutableArray array];
 if(kr != KERN_SUCCESS) {
 return result;
 }
 
 for(int i = 0; i < thread_count; i++) {
 NSArray *array = _bs_backtraceOfThread(threads[i], nil);
 [result addObject:array];
 }
 return [result copy];
 }
 */

/// 线程回调栈帧模型
public struct BacktraceFrame: CustomDebugStringConvertible {
    /// 镜像名/模块名
    let imageName: String
    /// 方法地址
    let address: UInt
    /// 方法名
    let funcName: String
    /// 偏移量
    let offset: Int
    
    public var debugDescription: String {
        return imageName.utf8CString.withUnsafeBufferPointer { (imageBuffer: UnsafeBufferPointer<CChar>) -> String in
            #if arch(x86_64) || arch(arm64)
            return String(format: "%-35s 0x%016llx %@ + %ld", UInt(bitPattern: imageBuffer.baseAddress), address, funcName, offset)
            #else
            return String(format: "%-35s 0x%08lx %@ + %ld", UInt(bitPattern: imageBuffer.baseAddress), address, funcName, offset)
            #endif
        }
    }
    
    internal init(info: [AnyHashable: Any]) {
        self.imageName = (info[BRBacktraceImageName] as? String) ?? "???"
        self.address = (info[BRBacktraceAddress] as? UInt) ?? 0
        self.offset = (info[BRBacktraceOffset] as? Int) ?? 0
        self.funcName = _stdlib_demangleName(
            (info[BRBacktraceFuncName] as? String) ?? "???"
        )
    }
}

extension Array where Element == BacktraceFrame {
    /// 打印调用栈
    public func log() {
        print("------------------------------------------------------")
        for (i, value) in self.enumerated() {
            print(String(format:"%-4ld %@", i,value.debugDescription))
        }
        print("------------------------------------------------------")
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


