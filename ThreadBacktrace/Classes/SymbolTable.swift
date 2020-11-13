//
//  SymbolTable.swift
//  ThreadBacktrace
//
//  Created by rongheng on 2020/11/12.
//

import Foundation
import ObjectiveC
import MachO

/// 符号数据结构
public struct SymbolEntry: Codable {
    public let `class`: String
    public let name: String
    public let address: Int64
    
    public var log: String {
        return "calss: \(self.class)    name:\(name)   address:\(String(address, radix: 16))\n"
    }
}

/// APP 动态符号表
public private(set) var _appSymbolTable : [SymbolEntry] = []
/// ASLR
public private(set) var _aslr : Int = 0

private let _symbolQueue = DispatchQueue(label: "SymbolTableQueue")

/// Key 枚举
enum Key {
    static let version : String = "version"
    static let appVersion : String = "CFBundleShortVersionString"
    static let symbolTablePath : String = ""
}

//MARK: 符号表获取
/// 初始化符号表数据
public func InitializeSymbolTable() {
    _aslr = ASLR
    
    _symbolQueue.async {
        let version = UserDefaults.standard.string(forKey: Key.version)
        let appVersion = Bundle.main.infoDictionary?[Key.appVersion] as? String
        
        // 版本号发生变化时才重新生成符号表
        if version != appVersion && appVersion != nil {
            _appSymbolTable = AppSymbolTable()
            
            SaveSymbolTable(_appSymbolTable)
            
            UserDefaults.standard.setValue(appVersion, forKey: Key.version)
            UserDefaults.standard.synchronize()
        }
        else {
            // 从本地读取
            _appSymbolTable = GetSymbolTable()
            print(_appSymbolTable.count)
        }
    }
}

/// 动态获取 APP Mach-O 符号表
func AppSymbolTable() -> [SymbolEntry] {
    guard
        let imageName = _dyld_get_image_name(AppImageIndex())
    else {
        return []
    }
    
    // 获取当前 Image 所有 class
    var classCount : UInt32 = 0
    guard let classeList = objc_copyClassNamesForImage(imageName, &classCount) else {
        return []
    }
    
    // 当前运行 aslr
    let aslr = ASLR
    
    // 符号表
    var symbloTable : [SymbolEntry] = [];
    
    for i in 0 ..< classCount {
        let className = String(cString: classeList[Int(i)])
        var methodCount : UInt32 = 0
        
        // 获取 class 所有 OC MethodList
        guard
            let methodList = class_copyMethodList(
                NSClassFromString(className),
                &methodCount
            )
        else {
            continue
        }
        
        for i in 0 ..< methodCount {
            let method = methodList[Int(i)]
            let sel = method_getName(method)
            let imp = method_getImplementation(method)
            let name = NSStringFromSelector(sel) as String
            // Mach-O符号地址 = 方法表地址(真实运行地址) - ASLR
            let address = Int(bitPattern: imp) - aslr
            let symbol = SymbolEntry(
                class: className,
                name: name,
                address: Int64(address)
            )
            
            symbloTable.append(symbol)
            
            print("class : \(className)  sel: \(sel) imp:\(imp)")
        }
        
    }
    
    // 按地址 从低到高 排序
    symbloTable.sort { (entry0, entry1) -> Bool in
        entry0.address < entry1.address
    }
     
    return symbloTable
}

/// 获取当前可执行文件 Mach-O idx
func AppImageIndex() -> UInt32 {
    let imageCount = _dyld_image_count()
    var image_idx : UInt32 = 0
    
    for i in 0 ..< imageCount {
        let image_header = _dyld_get_image_header(i).pointee
        if image_header.filetype == MH_EXECUTE {
            image_idx = i
            break
        }
    }
    
    return image_idx
}

/// 获取运行的 ASLR
var ASLR : Int {
    return _dyld_get_image_vmaddr_slide(AppImageIndex())
}

/// 保存符号表
private func SaveSymbolTable(_ symbols: [SymbolEntry]) {
    guard
        !symbols.isEmpty,
        let data = try? JSONEncoder().encode(symbols),
        let symbolsURL = symbolTableURL
    else {
        return
    }
 
    let isSave = FileManager.default.fileExists(atPath: symbolsURL.absoluteString)
    if isSave {
        try? FileManager.default.removeItem(at: symbolsURL)
    }
    // 写入本地文件
    let success = FileManager.default.createFile(
        atPath: symbolsURL.absoluteString,
        contents: data,
        attributes: nil
    )
    if !success {
        print("创建文件失败")
    }
}

/// 获取符号表
private func GetSymbolTable() -> [SymbolEntry] {
    guard
        let symbolsURL = symbolTableURL,
        FileManager.default.fileExists(atPath: symbolsURL.absoluteString),
        let symbolsData = FileManager.default.contents(atPath: symbolsURL.absoluteString),
        let symbolTable = try? JSONDecoder().decode([SymbolEntry].self, from: symbolsData)
    else {
        return []
    }
    
    return symbolTable
}

/// 符号表FileURL
private var symbolTableURL: URL? {
    guard
        let documentPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true
        ).first
    else {
        return nil
    }
    
    let symbolsDirectory = "\(documentPath)/SymbolTable"
    guard !FileManager.default.fileExists(atPath: symbolsDirectory) else {
        return URL(string: "\(symbolsDirectory)/symbol.text")
    }
    
    do {
        try FileManager.default.createDirectory(
            atPath: symbolsDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    } catch let error {
        print(error)
        return nil
    }
    
    return URL(fileURLWithPath: "\(symbolsDirectory)/symbol.text")
}
