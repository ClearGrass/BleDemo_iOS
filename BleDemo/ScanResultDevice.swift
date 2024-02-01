//
//  ScanResultDevice.swift
//  BleDemo
//
//  Created by qingping on 2024/2/1.
//

import Foundation
import CoreBluetooth
struct ScanResultDevice: Equatable, Identifiable {
    init(peripheral: CBPeripheral, data: [CBUUID : Data], rssi: Int) {
        self.name = peripheral.name ?? ""
        self.identifier = peripheral.identifier
        self.rssi = rssi
        self.data = ScanResultParsed(fdcdData: data[CBUUID(string: "FDCD")]!)!
    }
    
    var id: String {
        get {
            return identifier.uuidString
        }
    }
        
    var name: String
    var identifier: UUID
    var rssi: Int
    var data: ScanResultParsed
    var productId: UInt8 {
        return data.productId
    }
    var isBinding: Bool {
        return data.frameControl.binding
    }
    var mac: String {
        return data.mac
    }
    var clientId: String {
        return data.mac.replacing(try! Regex("[^0-9A-F]"), with: "").replacing(try! Regex("^0+"), with: "")
    }
    static func ==(lhs: ScanResultDevice, rhs: ScanResultDevice) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
