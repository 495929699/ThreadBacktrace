//
//  ThreadBacktrace.swift
//  ThreadBacktrace
//
//  Created by 荣恒 on 2019/8/27.
//  Copyright © 2019 荣恒. All rights reserved.
//

import Foundation

public struct StackSymbol {
    public let symbol: String
    public let file: String
    public let address: UInt
    public let symbolAddress: UInt
    public let image: String
    public let offset: Int
    public let index: Int
    
    public var demangledSymbol: String {
        return _stdlib_demangleName(symbol)
    }

    public var info: String {
        return image.utf8CString.withUnsafeBufferPointer { (imageBuffer: UnsafeBufferPointer<CChar>) -> String in
            #if arch(x86_64) || arch(arm64)
            return String(format: "%-4ld%-35s 0x%016llx %@ + %ld \n", index, UInt(bitPattern: imageBuffer.baseAddress), address, demangledSymbol, offset)
            #else
            return String(format: "%-4d%-35s 0x%08lx %@ + %d \n", index, UInt(bitPattern: imageBuffer.baseAddress), address, demangledSymbol, offset)
            #endif
        }
    }

}

//MARK: Swift 方法名还原
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
            flags: 0
        )
        
        if let demangledNamePtr = demangledNamePtr {
            let demangledName = String(cString: demangledNamePtr)
            free(demangledNamePtr)
            return demangledName
        }
        return mangledName
    }
}


//MARK: private 快捷方法

/// 创建符号
func _stackSymbol(from address: UInt, index: Int) -> StackSymbol {
    var info = dl_info()
    _dladdr(address, &info)
    
    /*
         dladdr(UnsafeRawPointer(bitPattern: address), &info)
         可用此接口验证 dl_info 地址数据是否正确
     */

    return StackSymbol(symbol: _symbol(info: info),
                       file: _dli_fname(with: info),
                       address: address,
                       symbolAddress: unsafeBitCast(info.dli_saddr, to: UInt.self),
                       image: _image(info: info),
                       offset: _offset(info: info, address: address),
                       index: index
    )
}

/// the symbol nearest the address
private func _symbol(info: dl_info) -> String {
    if
        let dli_sname = info.dli_sname,
        let sname = String(validatingUTF8: dli_sname) {
        return sname
    }
    else if
        let dli_fname = info.dli_fname,
        let _ = String(validatingUTF8: dli_fname) {
        return _image(info: info)
    }
    else {
        return String(format: "0x%1x", UInt(bitPattern: info.dli_saddr))
    }
}

/// thanks to https://github.com/mattgallagher/CwlUtils/blob/master/Sources/CwlUtils/CwlAddressInfo.swift
/// the "image" (shared object pathname) for the instruction
private func _image(info: dl_info) -> String {
    guard
        let dli_fname = info.dli_fname,
        let fname = String(validatingUTF8: dli_fname),
        let _ = fname.range(of: "/", options: .backwards, range: nil, locale: nil)
    else {
        return "???"
    }
    
    return (fname as NSString).lastPathComponent
}

/// the address' offset relative to the nearest symbol
private func _offset(info: dl_info, address: UInt) -> Int {
    if
        let dli_sname = info.dli_sname,
        let _ = String(validatingUTF8: dli_sname) {
        return Int(address - UInt(bitPattern: info.dli_saddr))
    }
    else if
        let dli_fname = info.dli_fname,
        let _ = String(validatingUTF8: dli_fname) {
        return Int(address - UInt(bitPattern: info.dli_fbase))
    }
    else {
        return Int(address - UInt(bitPattern: info.dli_saddr))
    }
}

private func _dli_fname(with info: dl_info) -> String {
    if has_dli_fname(info) {
        return String(cString: info.dli_fname)
    }
    else {
        return "-"
    }
}
