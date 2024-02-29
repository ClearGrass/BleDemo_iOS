//
//  BluetoothManager.swift
//  BleDemo
//
//  Created by qingping on 2024/1/30.
//

import Foundation
import CoreBluetooth

typealias BlueAcceptCallback = (_ peripheral: CBPeripheral, _ advertisementData: [CBUUID: Data], _ rssi: Int, _ localname: String?) -> Void

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
   
    static let shared = BluetoothManager()
    var bleState = CBManagerState.unknown
    var peripherals = [UUID: CBPeripheral]()
    var peripheralCallbacks = [UUID: PeripheralCallback]()
    var onBlueAccept: BlueAcceptCallback? = nil
    var onBleStateChange: ((_ state: CBManagerState) -> Void)? = nil
    @objc dynamic var _tempDiscoverCharaCounter = 0;
    public var centralManager: CBCentralManager!
    private override init() {
        centralManager = CBCentralManager(delegate: nil, queue: nil)
    }
    
    func setOnBleStateChanged(callback: @escaping (_ state: CBManagerState) -> Void) {
        centralManager.delegate = self
        callback(centralManager.state)
        onBleStateChange = callback
    }
    
    var isScaning: Bool {
        get {centralManager?.isScanning ?? false}
    }
    func scan(onAccept: @escaping BlueAcceptCallback) {
        centralManager.delegate = self
        self.onBlueAccept = onAccept
        if (isScaning) {
            centralManager.stopScan()
        }
        centralManager.scanForPeripherals(withServices: [CBUUID(string: "FDCD")], options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: true
        ])
    }
    func stopScan() {
        self.onBlueAccept = nil
        centralManager.stopScan()
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
    
    func getPeripheral(byIdentifier uuid: UUID) -> CBPeripheral? {
        return peripherals[uuid]
    }

    // MARK: CentralManager delegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("blue", "centralManagerDidUpdateState(state: \(central.state.rawValue))")
        bleState = central.state
        onBleStateChange?(central.state)
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripherals[peripheral.identifier] = peripheral
        
        let serviceDatas = advertisementData[CBAdvertisementDataServiceDataKey] as! [CBUUID: Data]
        for data1 in serviceDatas.enumerated() {
            let serviceuuid = data1.element.key.uuidString
            let data = data1.element.value
            if (serviceuuid == "FDCD") {
                let localName = advertisementData[CBAdvertisementDataLocalNameKey]
                self.onBlueAccept?(peripheral, serviceDatas, RSSI.intValue, localName as? String)
                break;
            }
        }
        
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
        _tempDiscoverCharaCounter -= 1;
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
