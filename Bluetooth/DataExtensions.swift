//
//  DataExtensions.swift
//  BleDemo
//
//  Created by qingping on 2024/2/1.
//

import Foundation


extension Data {
    func display(range: Range<Index>? = nil, dimter: String = "-", prefix: String = "0x") -> String {
        var sb = ""
        (range != nil ? self.subdata(in: range!) :self).forEach { byte in
            sb += byte.display() + dimter
        }
        return prefix + String(sb.dropLast())
    }
    
    func number() -> UInt16 {
        let num2 = UInt16(littleEndian: self.withUnsafeBytes { $0.load(as: UInt16.self) })
        return num2
    }
    func string() -> String {
        return String(data: self, encoding: .utf8)!
    }
    
}
extension UInt8 {
    func display(prefix: Bool = false) -> String {
        return prefix ? String(format:"0x%02x", self) : String(format:"%02x", self)
    }
    func isFF() -> Bool {
        return self == UInt8.max
    }
}
extension String {
    func isGoodToken() -> Bool {
        return matches(of: try! Regex("^[0-9a-zA-Z!@#$%^&()_=]{12,16}$")).count > 1
    }
    func isHex() -> Bool {
        return matches(of: try! Regex("^[0-9A-Fa-f]*$")).count > 1
    }
    func toData() -> Data {
        return self.data(using: String.Encoding.utf8)!
    }
}
