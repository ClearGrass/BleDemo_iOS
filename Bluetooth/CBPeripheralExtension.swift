//
//  PeripheralWriter.swift
//  BleDemo
//
//  Created by qingping on 2024/2/5.
//

import Foundation
import CoreBluetooth


extension CBPeripheral {
    func findService(withUUID uuid: CBUUID) -> CBService? {
        if(self.services == nil) {
            return nil
        }
        for service in self.services! {
            if (service.uuid == uuid) {
                return service
            }
        }
        return nil
    }
    func findCharacteristic(withUUID uuid: CBUUID, inService service: CBService?) -> CBCharacteristic? {
        guard let service = service, service.characteristics != nil else {
            return nil
        }
        for chara in service.characteristics! {
            if (chara.uuid == uuid) {
                return chara
            }
        }
        return nil
    }
    func findCharacteristic(withUUID uuid: CBUUID, inServiceUUID serviceUUID: CBUUID) -> CBCharacteristic? {
        return findCharacteristic(withUUID: uuid, inService: findService(withUUID: serviceUUID))
    }
    
    func readValue(for characteristic: CBUUID, inService service: CBUUID) {
        if let chara = self.findCharacteristic(withUUID: characteristic, inServiceUUID: service) {
            self.readValue(for: chara)
        }
    }
    
    func writeValue(_ data: Data, for characteristic: CBUUID, inService service: CBUUID, withResponse reponse: Bool = true) {
        if let chara = self.findCharacteristic(withUUID: characteristic, inServiceUUID: service) {
            self.writeValue(data, for: chara, type: reponse ? .withResponse : .withoutResponse)
        }
    }
    
    func setNotifyOff() {
        if(self.services == nil) {
            return
        }
        for service in self.services! {
            if (service.characteristics == nil) {
                continue;
            }
            for chara in service.characteristics! {
                if (chara.isNotifying) {
                    self.setNotifyValue(false, for: chara)
                }
            }
        }
    }
}
