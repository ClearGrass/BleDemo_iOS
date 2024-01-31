//
//  BluetoothManager.swift
//  BleDemo
//
//  Created by qingping on 2024/1/30.
//

import Foundation
import CoreBluetooth

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let shared = BluetoothManager()
    var peripherals = [UUID: CBPeripheral]()
    var peripheralCallbacks = [UUID: PeripheralCallback]()
    
    @objc dynamic var _tempDiscoverCharaCounter = 0;
    private var centralManager: CBCentralManager!
    private override init() {
        centralManager = CBCentralManager(delegate: nil, queue: nil)
    }
    
    func scan() {
        centralManager.delegate = self
        centralManager.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
    }
    func connect(_ identifier: UUID, withCallback callback: PeripheralCallback) {
        if let peripheral = peripherals[identifier] {
          connect(peripheral, withCallback: callback)
        }
    }
    func connect(_ peripheral: CBPeripheral, withCallback callback: PeripheralCallback) {
        centralManager.delegate = self
        peripheral.delegate = self
        peripheralCallbacks[peripheral.identifier] = callback
        centralManager.connect(peripheral)
    }
    func disconnect(_ peripheral: CBPeripheral) {
        centralManager.delegate = self
        centralManager.cancelPeripheralConnection(peripheral)
    }

    // MARK: CentralManager delegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripherals[peripheral.identifier] = peripheral
        
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheralCallbacks[peripheral.identifier]?.onPeripheralConnected(peripheral)
    }
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        peripheralCallbacks[peripheral.identifier]?.onPeripheralDisconnected(peripheral, withError: error)
        peripheralCallbacks.removeValue(forKey: peripheral.identifier)
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        peripheralCallbacks[peripheral.identifier]?.onPeripheralDisconnected(peripheral, withError: error)
    }
    
    //MARK: Peripheral delegate
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        _tempDiscoverCharaCounter = peripheral.services?.count ?? 0
        for service in peripheral.services! {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (error != nil) {
            return;
        }
        if (_tempDiscoverCharaCounter == 0) {
            peripheralCallbacks[peripheral.identifier]?.onPeripheralReady(peripheral)
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        peripheralCallbacks[peripheral.identifier]?.onSetNotifyperipheral(peripheral, characteristic: characteristic, withResult:  error == nil)
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        peripheralCallbacks[peripheral.identifier]?.onWritePeripheral(peripheral, characteristic: characteristic, withResult: error == nil)
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        peripheralCallbacks[peripheral.identifier]?.onValueUpdated(characteristic.value ?? nil, peripheral: peripheral, characteristic: characteristic)
    }
    
}

protocol PeripheralCallback {
    func onPeripheralConnected(_ peripheral: CBPeripheral);
    func onPeripheralReady(_ peripheral: CBPeripheral);
    func onPeripheralDisconnected(_ peripheral: CBPeripheral, withError error: Error?);
    func onSetNotifyperipheral(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, withResult result: Bool);
    func onWritePeripheral(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, withResult result: Bool);
    func onValueUpdated(_ value: Data?, peripheral: CBPeripheral, characteristic: CBCharacteristic);
    
}
