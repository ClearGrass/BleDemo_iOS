//
//  UUIDs.swift
//  BleDemo
//
//  Created by qingping on 2024/1/31.
//

import Foundation
import CoreBluetooth.CBUUID
class UUIDs {
    public static let SERVICE = UUIDHelper.fromString("22210000-554a-4546-5542-46534450464d");
    public static let COMMON_WRITE = UUIDHelper.fromString("0001");
    public static let COMMON_READ = UUIDHelper.fromString("0002");
    public static let MY_WRITE = UUIDHelper.fromString("0015");
    public static let MY_READ = UUIDHelper.fromString("0016");

    public static let DFU_SERVICE = UUIDHelper.fromString("fe59");
    public static let DFU_POINT = UUIDHelper.fromString("8ec90001-f315-4f60-9fb8-838830daea50");
    public static let DFU_PACKET = UUIDHelper.fromString("8ec90002-f315-4f60-9fb8-838830daea50");
    public static let DFU_INTO = UUIDHelper.fromString("8ec90003-f315-4f60-9fb8-838830daea50");

    public static let INFO_SERVICE = UUIDHelper.fromString("180a");
    public static let INFO_CHAR = UUIDHelper.fromString("0010");
    public static let INFO_VERSION_CHAR = UUIDHelper.fromString("2a26");
}
class UUIDHelper {
    static let UUID_BASE = "0000XXXX-0000-1000-8000-00805f9b34fb";
    static func fromString(_ uuidString: String) -> CBUUID {
        if (uuidString.count == 4) {
            return CBUUID(string: UUID_BASE.replacing(pattern: "XXXX", with: uuidString))
        }
        return CBUUID(string: uuidString)
    }
    
    static func simpler(uuidString: String) -> String {
        return uuidString.lowercased()
            .replacingOccurrences(of: "-0000-1000-8000-00805f9b34fb", with: "")
            .replacing(pattern: "^0000", with: "")
    }
}
extension UUID {
    func simple() -> String {
        return UUIDHelper.simpler(uuidString: self.uuidString)
    }
}
extension CBUUID {
    func simple() -> String {
        return UUIDHelper.simpler(uuidString: self.uuidString)
    }
}
