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


typealias DebugCommand = (action: String, uuid: String, data: Data?)

class QingpingDevice: NSObject, CBPeripheralDelegate, PeripheralCallback {
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
    private var connectCallback: ActionResult? = nil;
    private var registerNotifyCallback: ActionResult? = nil;
    private var readCallback: ValueCallback<UUIDAndData>? = nil;
    private var readRSSICallback: ValueCallback<Int>? = nil;
    private var writeCallback: ActionResult? = nil;
    
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
                    DispatchQueue.main.async {
                        responder(false)
                    }
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
                    DispatchQueue.main.async {
                        responder(qprotocol.resultSuccess)
                    }
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
                    if (result) {
                        self.onConnectedToPeripheral = connectionChange.onConnected
                        self.onDisconnectedFromPeripheral = connectionChange.onDisconnected
                        responder(result)
                    }
                }
            },
            onDisconnected: { [self] arg0 in
                connectionChange.onDisconnected(arg0)
                self.onDisconnectedFromPeripheral = connectionChange.onDisconnected
                responder(false)
            }
        ))
    }
    
    func writeInternalCommand(command: Data, responder: @escaping CommandResponder) {
        if (command.count < 2) {
            return;
        }
        reponseCollector.off()
        try! reponseCollector.setResponder(type: command[1], fromCharacteristic: UUIDs.COMMON_READ, responder: responder)
        debugCommandListener(DebugCommand("write", "0001", command))
        writeValue(command, toCharacteristic: UUIDs.COMMON_WRITE, inService: UUIDs.SERVICE)
    }
    
    func writeCommand(command: Data, responder: @escaping CommandResponder) {
        if (command.count < 2) {
            return;
        }
        reponseCollector.off()
        try! reponseCollector.setResponder(type: command[1], fromCharacteristic: UUIDs.MY_READ, responder: responder)
        debugCommandListener(DebugCommand("write", "0015", command))
        writeValue(command, toCharacteristic: UUIDs.MY_WRITE, inService: UUIDs.SERVICE)
    }
    
    func writeValue(_ data: Data, toCharacteristic characteristic: CBUUID, inService service: CBUUID) {
        peripheral.writeData(data, toCharacterisitc: characteristic, inService: service)
    }
    
    func readValueFrom(_ characteristic: CBUUID, inService service: CBUUID, responder: @escaping CommandResponder) {
        self.readCallback =  { uuidAndData in
            responder(uuidAndData.data)
        }
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
        writeCallback.map { invoker in
            writeCallback = nil
            invoker(result)
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
        print("blue", "collect \(fromUUID.simple()) \(data.display())", "waiting=\(waitingType) waitingChara=\(waitingCharacteristic?.uuidString) nextResponder=\(nextResponder)")
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
        print("parse data pager \(reponseHasMultiPage)")
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

typealias QProtocol = (
    type: UInt8,
    resultSuccess: Bool,
    data: Data?,
    count: Int,
    page: Int
)
class QpUtils {
    static func wrapProtocol(_ protocolType: UInt8, data: Data? = nil) -> Data {
        if let data = data {
            return Data([UInt8(data.count) + 1, protocolType]) + data
        } else {
            return Data([1, protocolType])
        }
    }
    
    static func parseProtocol(dataBytes: Data, withPage:Bool = false) -> QProtocol? {
        if (dataBytes.count < 2) {
            return nil
        }
        if (dataBytes[1].isFF()) {  //如： 0x04FF010000
            // 第一个字节是0x04，表示数据长度是0x04
            // 第二个字节是0xFF，表示这一包用于表示成功失败
            // 第三个字节是0x01，表示协议类型是 01 （绑定）
            // 第四五个字节是0x00 00，表示成功，在解析时：如果是 0x01 00 ，从后向前取每一个字节成为： 00 01，则==1

            
            let data = dataBytes.subdata(in: 3..<dataBytes.endIndex)
            let succ = data.number() == 0

            return QProtocol(dataBytes[2], succ, data, 1, 1)
        } else {
            // 解析协议
            // 其它如：0x06081122334466
            let type = dataBytes[1]
            // 从第三位开始，都是数据
            let data = dataBytes.subdata(in: 2..<dataBytes.endIndex)
            let succ = true
            if (!withPage || dataBytes.count < 3) {
                return QProtocol(type, succ, data, 1, 1)
            } else {
                // 对于长数据。如  0x13-07-1e-01-22-51-69-6e-67-70-69-6e-67-20-41-50-22-2c-34-2c
                // 第三位1e表示共几条，每四位的01表示这是第几条。计数从1开始。
                // 第五位22开始，都是数据
                let count: Int = Int(dataBytes[2])
                let page: Int = Int(dataBytes[3])
                return QProtocol(type, succ, data.subdata(in: 2..<data.endIndex), count, page)
            }
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
