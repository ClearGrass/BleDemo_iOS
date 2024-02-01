//
//  QingpingDevice.swift
//  BleDemo
//
//  Created by qingping on 2024/1/31.
//

import Foundation
import CoreBluetooth

typealias UUIDAndData = (CBUUID, Data)
typealias ValueCallback<T> = ((T) -> ())?
typealias ActionResult = ValueCallback<Bool>

typealias Command = (action: String, uuid: String, data: Data?)

protocol OnConnectionStatusCallback {
    func onPeripheralConnected(_ peripheral: CBPeripheral);
    func onPeripheralDisconnected(_ peripheral: CBPeripheral, withError error: Error?);
}
class QingpingDevice: NSObject, CBPeripheralDelegate, PeripheralCallback {
    let peripheral: CBPeripheral
    let advertisementData:  [String : Any]
    let rssi: Int
    
    var name: String {
        get {
            peripheral.name ?? ""
        }
    }
    var identifier: UUID {
        get {
            peripheral.identifier
        }
    }
        
    private var connectStatusCallback: OnConnectionStatusCallback? = nil;
    private var connectCallback: ActionResult = nil;
    private var registerNotifyCallback: ActionResult = nil;
    private var readCallback: ValueCallback<UUIDAndData> = nil;
    private var notifyCallback: ValueCallback<UUIDAndData> = nil;
    private var readRSSICallback: ValueCallback<Int> = nil;
    private var writeCallback: ActionResult = nil;
    private var debugCommandListener: (Command) -> Void = { command in
        print("blue", "debugCommandListener not set. ", command)
    }
    
    init(peripheral: CBPeripheral, advertisementData: [String : Any], rssi: Int) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
    }
    private func connect() {
        BluetoothManager.shared.connect(peripheral, withCallback: self)
    }
    
    func disconnect() {
        peripheral.setNotifyOff()
        BluetoothManager.shared.disconnect(peripheral)
    }
    
    private func bind(randomBytes: Data, responder: ActionResult) {

    }
    
    private func verify(tokenBytes: Data, responder: ActionResult) {
        
    }
    
    func connectBind() {
        
    }
    
    func connectVerify() {
        
    }
    
    func writeInternalCommand(data: Data) {
        debugCommandListener(Command("write", "0001", data))
    }
    
    func writeCommand(data: Data) {
        debugCommandListener(Command("write", "0015", data))
    }
    
    func writeValue(_ data: Data, toCharacteristic characteristic: CBUUID, inService service: CBUUID) {
        peripheral.writeData(data, toCharacterisitc: characteristic, inService: service)
    }
    
    func readValueFrom(_ characteristic: CBUUID, inService service: CBUUID) {
        peripheral.readDataFrom(characteristic, inService: service)
    }
    
    // MARK: PeripheralCallback
    func onPeripheralConnected(_ peripheral: CBPeripheral) {
        // 蓝牙连接上了。什么都不用干。
        peripheral.discoverServices(nil)
    }
    
    func onPeripheralReady(_ peripheral: CBPeripheral) {
        // 发现了服务
        registerNotifyCallback = nil
        if let readChara = peripheral.findCharacteristic(withUUID: UUIDs.COMMON_READ, inServiceUUID: UUIDs.SERVICE) {
            registerNotifyCallback = { result in
                if result {
                    self.connectStatusCallback?.onPeripheralConnected(peripheral)
                }
            }
            peripheral.setNotifyValue(true, for: readChara)
        }
    }
    
    func onPeripheralDisconnected(_ peripheral: CBPeripheral, withError error: Error?) {
        self.connectStatusCallback?.onPeripheralDisconnected(peripheral, withError: error)
    }
    
    func onSetNotifyperipheral(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, withResult result: Bool) {
        registerNotifyCallback.map { invoker in
            registerNotifyCallback = nil
            invoker(result)
        }
    }
    
    func onWritePeripheral(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, withResult result: Bool) {
        writeCallback.map { invoker in
            writeCallback = nil
            invoker(result)
        }
    }
    
    func onValueUpdated(_ value: Data?, peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        if let readback = readCallback {
            readCallback = nil
            if (value != nil) {
                readback((characteristic.uuid, value!))
            }
        } else if let notifyCallback = notifyCallback {
            if (value != nil) {
                notifyCallback((characteristic.uuid, value!))
            }
        }
    }
}


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
    
    func readDataFrom(_ characteristic: CBUUID, inService service: CBUUID) {
        if let chara = self.findCharacteristic(withUUID: characteristic, inServiceUUID: service) {
            self.readValue(for: chara)
        }
    }
    
    func writeData(_ data: Data, toCharacterisitc characteristic: CBUUID, inService service: CBUUID, withResponse reponse: Bool = true) {
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


class QpUtils {
    static func wrapProtocol(_ protocolType: UInt8, data: Data? = nil) -> Data {
        if let data = data {
            return Data([UInt8(data.count) + 1, protocolType]) + data
        } else {
            return Data([1, protocolType])
        }
    }
    static func hexToData(hexString: String) -> Data {
        let randomHex = try! hexString.trimmingPrefix("0x").replacing(Regex("[^0-9A-Fa-f]"), with: "").uppercased()

        var data = Data(capacity: randomHex.count / 2)
        
        let regex = try! Regex("[0-9ABCDEF]{2}")
        randomHex.matches(of: regex).forEach { checkResult in
            let bs = randomHex[checkResult.range]
            let num = UInt8(bs, radix: 16)!
            data.append(num)
        }
        
        return data
        
    }
}
