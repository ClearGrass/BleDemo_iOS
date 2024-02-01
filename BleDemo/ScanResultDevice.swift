//
//  ScanResultDevice.swift
//  BleDemo
//
//  Created by qingping on 2024/2/1.
//

import Foundation
@propertyWrapper
struct DataValue<Value> {
    var wrappedValue: Value
}

struct ScanResultDevice: Equatable, Identifiable {
    var id: String {
        get {
            return uuid.uuidString
        }
    }
        
    @DataValue var name: String
    @DataValue var uuid: UUID
    @DataValue var rssi: Int
    @DataValue var data: ScanResultParsed
    static func ==(lhs: ScanResultDevice, rhs: ScanResultDevice) -> Bool {
        return lhs.uuid == rhs.uuid
    }
}
