//
//  QingpingDevice.swift
//  BleDemo
//
//  Created by qingping on 2024/1/31.
//

import Foundation
import CoreBluetooth

typealias UUIDAndData = (uuid: CBUUID, data: Data)
typealias ValueCallback<T> = ((T) -> ())
typealias ActionResult = ValueCallback<Bool>
typealias CommandResponder = (Data) -> ()

typealias OnConnectedToPeripheral = ValueCallback<CBPeripheral>
typealias OnDisconnectedFromPeripheral = ValueCallback<(peripheral: CBPeripheral, error: Error?)>
typealias ConnectionStatusChanged = (onConnected: OnConnectedToPeripheral, onDisconnected: OnDisconnectedFromPeripheral)

struct DebugCommand {
    let id = UUID()
    let action: String
    let uuid: String
    let data: Data?
}
//typealias DebugCommand = (action: String, uuid: String, data: Data?)

class QingpingDevice: NSObject, PeripheralCallback {
    let peripheral: CBPeripheral
    var rssi: Int
    
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
        
    private var onConnectedToPeripheral: OnConnectedToPeripheral? = nil;
    private var onDisconnectedFromPeripheral: OnDisconnectedFromPeripheral? = nil;
    private var registerNotifyCallback: ActionResult? = nil;
    private var readCallback: ValueCallback<UUIDAndData>? = nil;
    private var writeCallback: ActionResult? = nil;
    private var readRSSICallback: ValueCallback<Int>? = nil;
    private var writeQueue: [Data] = []
    
    private let reponseCollector = ResponseCollector();
    
    public var debugCommandListener: (DebugCommand) -> Void = { command in
        print("blue", "debugCommandListener not set. ", command, command.data?.display() ?? "0x")
    }
    
    init(peripheral: CBPeripheral, rssi: Int = -100) {
        self.peripheral = peripheral
        self.rssi = rssi
    }
    private func connect(connectionChange: ConnectionStatusChanged) {
        self.onConnectedToPeripheral = connectionChange.onConnected
        self.onDisconnectedFromPeripheral = connectionChange.onDisconnected
        BluetoothManager.shared.connect(peripheral, withCallback: self)
    }
    
    func disconnect() {
        peripheral.setNotifyOff()
        BluetoothManager.shared.disconnect(peripheral)
    }
    
    private func bind(token: Data, responder: @escaping ActionResult) {
        var callOnce = false
        writeInternalCommand(command: QpUtils.wrapProtocol(1, data: token)) { [self] response in
            if let qprotocol = QpUtils.parseProtocol(dataBytes: response), qprotocol.resultSuccess {
                verify(token: token, responder: responder)
            } else {
                if (!callOnce) {
                    responder(false)
                    callOnce = true
                }
            }
        }
    }
    
    private func verify(token: Data, responder: @escaping ActionResult) {
        var callOnce = false
        writeInternalCommand(command: QpUtils.wrapProtocol(2, data: token)) { [self] response in
            if let qprotocol = QpUtils.parseProtocol(dataBytes: response) {
                if (!callOnce) {
                    responder(qprotocol.resultSuccess)
                    callOnce = true
                }
                if (qprotocol.resultSuccess) {
                    writeInternalCommand(command: QpUtils.wrapProtocol(0x0D)) { [self] response in
                        if let readChara = self.peripheral.findCharacteristic(withUUID: UUIDs.MY_READ, inServiceUUID: UUIDs.SERVICE) {
                            registerNotifyCallback = { result in
                                print("blue", "registerNotify(0016): result: \(result)")
                            }
                            peripheral.setNotifyValue(true, for: readChara)
                        }
                    }
                }
            }
        }
    }
    
    func connectBind(tokenString: String, connectionChange: ConnectionStatusChanged, responder: @escaping ActionResult) {
        connect(connectionChange: (
            onConnected: { [self] peripheral in
                connectionChange.onConnected(peripheral)
                bind(token: tokenString.toData()) { result in
                    self.onConnectedToPeripheral = connectionChange.onConnected
                    self.onDisconnectedFromPeripheral = connectionChange.onDisconnected
                    responder(result)
                }
            },
            onDisconnected: { [self] arg0 in
                connectionChange.onDisconnected(arg0)
                self.onDisconnectedFromPeripheral = connectionChange.onDisconnected
                responder(false)
            }
        ))
    }
    
    func connectVerify(tokenString: String, connectionChange: ConnectionStatusChanged, responder: @escaping ActionResult) {
        connect(connectionChange: (
            onConnected: { [self] peripheral in
                connectionChange.onConnected(peripheral)
                verify(token: tokenString.toData()) { result in
                    self.onConnectedToPeripheral = connectionChange.onConnected
                    self.onDisconnectedFromPeripheral = connectionChange.onDisconnected
                    responder(result)
                }
            },
            onDisconnected: { [self] arg0 in
                connectionChange.onDisconnected(arg0)
                self.onDisconnectedFromPeripheral = connectionChange.onDisconnected
                responder(false)
            }
        ))
    }
    
    func writeInternalCommand(command: Data, responder: @escaping CommandResponder, withCallback writeCallback: ActionResult? = nil) {
        if (command.count < 2) {
            return;
        }
        reponseCollector.off()
        try! reponseCollector.setResponder(type: command[1], fromCharacteristic: UUIDs.COMMON_READ, responder: responder)
        debugCommandListener(DebugCommand(action: "write", uuid: "0001", data: command))
        writeValue(command, toCharacteristic: UUIDs.COMMON_WRITE, inService: UUIDs.SERVICE, withCallback: writeCallback)
    }
    
    func writeCommand(command: Data, responder: @escaping CommandResponder, withCallback writeCallback: ActionResult? = nil) {
        if (command.count < 2) {
            return;
        }
        reponseCollector.off()
        try! reponseCollector.setResponder(type: command[1], fromCharacteristic: UUIDs.MY_READ, responder: responder)
        debugCommandListener(DebugCommand(action: "write", uuid: "0015", data: command))
        writeValue(command, toCharacteristic: UUIDs.MY_WRITE, inService: UUIDs.SERVICE, withCallback: writeCallback)
    }
    
    /**
        * 这里实现了写长Data时自动分割
     */
    func writeValue(_ data: Data, toCharacteristic characteristic: CBUUID, inService service: CBUUID, withCallback callback: ActionResult? = nil) {
        print("blue", "writeValue: \(data.display()) to: \(characteristic.simple())")
        writeCallback = callback
        if (data.count <= 20) {
            // 可以直接发
            peripheral.writeValue(data, for: characteristic, inService: service, withResponse: callback != nil);
            return;
        }
        var wroteCount = 0;
        while (wroteCount < data.count) {
            let thisPackageCount = min(20, data.count - wroteCount) // 最多20字节
            let subData = data.subdata(in: wroteCount..<(wroteCount+thisPackageCount))
            writeQueue.append(subData)
            wroteCount += thisPackageCount
        }
        
        print("blue", "writing data split into \(writeQueue.count) packs")

        // 写第一包，且等待回调后写第二包。
        let firstPack = writeQueue.removeFirst();
        print("blue", "writing first pack", firstPack.display(), "\(writeQueue.count) in Queue")
        peripheral.writeValue(firstPack, for: characteristic, inService: service, withResponse: true)
        
    }
    
    func readValueFrom(_ characteristic: CBUUID, inService service: CBUUID, responder: @escaping CommandResponder) {
        print("blue", "readValueFrom: \(characteristic.simple())")
        self.readCallback =  { uuidAndData in
            responder(uuidAndData.data)
        }
        peripheral.readValue(for: characteristic, inService: service)
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
                print("blue", "registerNotify(0002): result: \(result)")
                if result {
                    DispatchQueue.main.async {
                        self.onConnectedToPeripheral?(peripheral)
                    }
                }
            }
            peripheral.setNotifyValue(true, for: readChara)
        }
    }
    
    func onPeripheralDisconnected(_ peripheral: CBPeripheral, withError error: Error?) {
        DispatchQueue.main.async {
            self.onDisconnectedFromPeripheral?((peripheral, error))
        }
    }
    
    func onSetNotifyperipheral(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, withResult result: Bool) {
        registerNotifyCallback.map { invoker in
            registerNotifyCallback = nil
            invoker(result)
        }
    }
    
    func onWritePeripheral(_ peripheral: CBPeripheral, characteristic: CBCharacteristic, withResult result: Bool) {
        if (writeQueue.count > 0) {
            // 写下一包，且等待回调后写下下包。
            let nextPack = writeQueue.removeFirst()
            print("blue", "writing next pack", nextPack.display(), "\(writeQueue.count) in Queue");
            let needResponse = writeQueue.count > 0;
            peripheral.writeValue(nextPack, for: characteristic, type: .withResponse)
        } else {
            print("blue", "write to \(characteristic.uuid.simple()) done");
            if let writeCallback = writeCallback {
                self.writeCallback = nil
                writeCallback(result)
            }
        }
    }
    
    func onValueUpdated(_ value: Data?, peripheral: CBPeripheral, characteristic: CBCharacteristic) {
        if let readCallback = self.readCallback {
            self.readCallback = nil
            debugCommandListener(DebugCommand(action: "read", uuid: characteristic.uuid.simple(), data: value!))
            readCallback((characteristic.uuid, value!))
        } else {
            debugCommandListener(DebugCommand(action: "notify", uuid: characteristic.uuid.simple(), data: value!))
            reponseCollector.collect(fromUUID: characteristic.uuid, data: value!)
        }
    }
}


enum ResponderError: Error {
    case badState(String)
}

internal class ResponseCollector {
    var waitingType: UInt8 = 0
    var waitingCharacteristic: CBUUID? = nil
    var isCollecting = false
    private var nextResponder: CommandResponder? = nil
    private var respMap: [Int: Data] = [:]
    public func setResponder(type: UInt8, fromCharacteristic: CBUUID, responder: @escaping CommandResponder) throws {
        if (isCollecting) {
            throw ResponderError.badState("ResponseCollector is collecting")
        }
        if (waitingType > 0) {
            throw ResponderError.badState("ResponseCollector is waiting for 0x${waitingType.toString(16)}, not 0x${type.toString(16)}")
        }
        waitingCharacteristic = fromCharacteristic
        nextResponder = responder
        waitingType = type
        respMap.removeAll()
    }
    public func collect(uuidAndData: UUIDAndData) {
        return collect(fromUUID: uuidAndData.uuid, data: uuidAndData.data)
    }
    public func collect(fromUUID: CBUUID, data: Data) {
        if (waitingCharacteristic != fromUUID) {
            // 如果不是目标特征的响应 则忽略
            return
        }
        if (waitingType == 0 || nextResponder == nil) {
            // 不是一马事儿，忽略
            return
        }
        /**
         *
         * 目前 0x1E 命令 是多页的。是取clientid的
         * 目前 0x07 和 0x04 命令 是多页的。都是获取wifi列表命令，0x04已废弃。
         */
        let reponseHasMultiPage =
                (waitingCharacteristic == UUIDs.MY_READ
                        && (waitingType == 0x7 || waitingType == 0x4))
                || (waitingCharacteristic == UUIDs.COMMON_READ && waitingType == 0x1e)
        if (data[1].isFF() || !reponseHasMultiPage) {
            // 是 04FF010000 格式数据，或 非分页，直接回调
            if let responder = nextResponder {
                /**
                 * 先设置reponder为空，再回调。
                 * 防止在回调中再次调用
                 * 防止invoke里的responder无法被设置
                 */
                self.off();
                responder(data)
            }
            return
        }

        isCollecting = true;
        if let qprotocol = QpUtils.parseProtocol(dataBytes: data, withPage: reponseHasMultiPage) {
            if (qprotocol.type == waitingType) {
                respMap[qprotocol.page] = qprotocol.data!
            }
            if (respMap.count == qprotocol.count) {
                // 已收集到所有
                // 组合成一个符合协议格式的数据,不写长度，因为可能长度已经超出byte了。
                var data = Data() // byteArrayOf(UInt8.max, waitingType)
                for i in 1...qprotocol.count {
                    data.append(respMap[i]!)
                }
                data.insert(waitingType, at: 0)
                data.insert(UInt8.max, at: 0)
                if let responder = nextResponder {
                    /**
                     * 先设置reponder为空，再回调。
                     * 防止在回调中再次调用
                     * 防止invoke里的responder无法被设置
                     */
                    self.off();
                    responder(data)
                }
            }
        }
    }

    func off() {
        nextResponder = nil
        waitingType = 0
        waitingCharacteristic = nil
        isCollecting = false
        respMap.removeAll()
    }
}
