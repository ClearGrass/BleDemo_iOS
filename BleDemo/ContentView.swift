//
//  ContentView.swift
//  BleDemo
//
//  Created by qingping on 2024/1/30.
//

import SwiftUI
import CoreBluetooth
struct ContentView: View {
    @State private var bleStateReady = false
    @State var selectedPrd = 0
    @State var onlyPairing = false
    @State private var isScanning = false
    @State var filterText = ""
    @State var scanDevice: [ScanResultDevice] = []
    var filtedScanDevice: [ScanResultDevice] {
        get {
            if (!onlyPairing && selectedPrd == 0 && filterText.isEmpty) {
                return scanDevice
            }
            return scanDevice.filter { d in
                if (onlyPairing && d.data.frameControl.binding == false) {
                    return false
                }
                if (selectedPrd > 0 && d.data.productId != selectedPrd) {
                    return false
                }
                if (!filterText.isEmpty) {
                    return d.name.lowercased().contains(filterText.lowercased()) || d.mac.replacing(try! Regex("[^0-9A-F]"), with: "").contains(filterText.uppercased())
                }
                return true
            }
        }
    }
    
    
    var body: some View {
        NavigationView {
            VStack() {
                FilterBar(
                    bleReady: $bleStateReady,
                    selectedPrd: $selectedPrd, onlyPairing: $onlyPairing, isLoading: $isScanning
                ) { scan in
                    if (scan) {
                        scanDevice.removeAll()
                        isScanning = true
                        BluetoothManager.shared.scan { peripheral, adver, rssi  in
                            let device = ScanResultDevice(
                                peripheral: peripheral,
                                data: adver,
                                rssi: rssi
                            )
                            scanDevice.removeAll { element in
                                return element == device
                            }
                            scanDevice.append(device)
                            scanDevice.sort()
                        }
                    } else {
                        isScanning = false
                        BluetoothManager.shared.stopScan()
                    }
                }
                TextField("过滤 MAC 地址或设备名称", text: $filterText)
                    .padding()
                List {
                    ForEach(filtedScanDevice) { device in
                        Section(content: {
                            NavigationLink(destination: DetailPage(
                                uuid: device.identifier,
                                deviceName: device.name,
                                advertisingData: device.data,
                                qingpingDevice: QingpingDevice(
                                    peripheral: BluetoothManager.shared.getPeripheral(byIdentifier: device.identifier)!
                                )
                            )) {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(device.name)
                                        Spacer()
                                        Text("\(device.rssi)")
                                    }
                                    HStack {
                                        if (device.mac.starts(with: "06:66")) {
                                            Text("clientid: \(device.clientId)")
                                        } else {
                                            Text("MAC: \(device.mac)")
                                        }
                                    }
                                    
                                    HStack {
                                        Text("PID:\(device.productId.display(prefix: true)) (\(device.productId))").foregroundStyle(.primary)
                                        Spacer()
                                        if (device.isBinding) {
                                            Text("binding").foregroundStyle(Color.red)
                                        }
                                    }
                                    Divider()
                                    Text(device.data.rawData.display(dimter: " "))
                                }
                            }
                        }, footer: {
                            Text(device.id)
                        }).padding(0)
                        
                        
                    }.listSectionSpacing(10)
                }
            }
            .frame(alignment: .top)
            
        }.onAppear {
            BluetoothManager.shared.setOnBleStateChanged { state in
                bleStateReady = state == CBManagerState.poweredOn
            }
        }
    }
}

struct FilterBar: View {
    @Binding var bleReady: Bool
    @Binding var selectedPrd: Int
    @Binding var onlyPairing: Bool
    @Binding var isLoading: Bool
    var onClickButton: (_ startScan: Bool) -> Void
    var body: some View {
        HStack(content: {
            Text("产品")
            Picker("products", selection: $selectedPrd) {
                Text("不限").lineLimit(1).tag(0)
                Text("网关").lineLimit(1).tag(0xd)
                Text("门窗传感器").lineLimit(1).tag(0x4)
                Text("人体传感器").lineLimit(1).tag(0x12)
            }.frame(width: 120)
            .disabled(isLoading)
            Toggle(isOn: $onlyPairing) {
                Text("仅binding:").lineLimit(1)
            }
            .disabled(isLoading)
            .padding(.trailing, 35)
            Spacer()
            if (bleReady) {
                if isLoading {
                    Button(action: {
                        onClickButton(false)
                    }) {
                        Image(systemName: "xmark")
                    }.disabled(!bleReady)
                } else {
                    Button(action: {
                        onClickButton(true)
                    }) {
                        Image(systemName: "magnifyingglass")
                    }.disabled(!bleReady)
                }
            } else {
                Image(systemName: "gear.badge.questionmark")
            }
        }).padding(Edge.Set.vertical, 0)
            .padding(.horizontal)
    }
}


struct DetailPage: View {
    
    @State var showConnectingDialog = false
    @State var inputToken = "ABCDEFGHIJK"
    var uuid = UUID()
    var deviceName = "蓝牙设备"
    var advertisingData: ScanResultParsed? = nil
    
    @State var isLoading = false
    @State var isConnected = false
    
    @State var toCommonCharacteristic = true
    @State var debugCommands: [DebugCommand] = [
        DebugCommand("init","0000",nil)
    ]
    @State var qingpingDevice: QingpingDevice?
    var deviceMacParsedFromMac: String {
        return advertisingData?.mac ?? "none mac"
    }
    var onDeviceConnectionChanged: ConnectionStatusChanged {
        return (
            onConnected: { _ in
                print("blue", "device connected")
                debugCommands.append(DebugCommand("[Connected]", deviceMacParsedFromMac, nil))
                isConnected = true
            },
            onDisconnected: { _ in
                print("blue", "device disconnected")
                debugCommands.append(DebugCommand("[Disonnected]", deviceMacParsedFromMac, nil))
                isConnected = false
                isLoading = false
                toCommonCharacteristic = true
            }
        )
    }
    var body: some View {
        VStack() {
            List() {
                Section(content: {
                    Text((advertisingData?.rawData.display())!)
                }, header: {Text(deviceName)}) {
                    Text("\(uuid.uuidString)")
                }
                Section {
                    ForEach(debugCommands.indices, id: \.self) { index in
                        Text(
                            ((debugCommands[index].action
                             + "   -> "
                             + debugCommands[index].uuid
                             ) + (debugCommands[index].data?.display(prefix:"\n0x") ?? "")
                            ).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                        )
                    }
                }
            }
            Inputer(
                enabled: !isLoading && isConnected,
                // 网关有0015特征，其它没有。
                targetUuid: toCommonCharacteristic ? "0x0001" : (advertisingData?.productId == 0xd ? "0x0015" : "0x0001"),
                menuItems: (advertisingData?.productId == 0xd ? [
                    ("写到0001", "0x0001", { index in
                        toCommonCharacteristic = true
                        return nil
                    }),
                    ("写到0015", "0x0015", { index in
                        toCommonCharacteristic = false
                        return nil
                    }),
                    ("", "", nil),
                    ("AP LIST(07)", "0107", nil),
                    ("连接WIFI(01)", "", { index in
                        return "0F012241414141222c224243444546474822"
                    }),
                    ("client_id(1E)", "011E", nil)
                ].reversed(): [])
            ) { message in
                sendMessage(message, toDevice: qingpingDevice!, toCommonCharacteristic: toCommonCharacteristic) { response in
                    if (!toCommonCharacteristic) {
                        print("blue", "ble response  \(response.display())")
                        //这里把比较特殊的协议回应解析后显示到界面上中方便查看。
                        // WIFI列表
                        if (response[0].isFF() && response[1] == 0x7) {
                            // 这是WIFI 列表
                            debugCommands.append(DebugCommand("parse", "WIFI列表", response))
                        }

                        // 连接WIFI结果
                        if (response[1] == 0x01) {
                            debugCommands.append(DebugCommand("parse", (response[2] == 1) ? "连接WIFI成功" : "连接WIFI失败", response))
                        }
                    } else {
                        if (response[0].isFF() && response[1] == 0x1e) {
                            // 这是 client_id
                            debugCommands.append(DebugCommand(
                                "parse",
                                "0002; client_id",
                                response
                            ))
                        }
                    }
                }
            }
        }.confirmationDialog("请问执行【连接验证】还是执行【连接并绑定】设备？", isPresented: $showConnectingDialog, titleVisibility: .visible, actions: {
            Button("连接验证") { [self]
                print("blue", "start connect")
                isLoading = true
                
                toCommonCharacteristic = true
                debugCommands.append(DebugCommand("Connecting and Verify!",
                    deviceMacParsedFromMac,
                    QpUtils.wrapProtocol(1, data: inputToken.toData())
                ))
                
                qingpingDevice?.connectVerify(tokenString: inputToken, connectionChange: self.onDeviceConnectionChanged){ verifyResult in
                    print("blue", "connectVerify: = \(verifyResult)")
                    debugCommands.append(DebugCommand(
                        "[Verify] Result",
                        verifyResult ? "SUCCESS" : "FAILED",
                        nil
                    ))
                    isLoading = false
                    if (verifyResult && advertisingData?.productId == 0xd) {
                        // 只有网关可写到0015
                        toCommonCharacteristic = false
                    } else {
                        toCommonCharacteristic = true
                    }
                }
            }
            Button("连接并绑定") {
                print("blue", "start connect")
                isLoading = true
                toCommonCharacteristic = true
                debugCommands.append(DebugCommand("Connecting and Bind!",
                    deviceMacParsedFromMac,
                    QpUtils.wrapProtocol(1, data: inputToken.toData())
                ))
                
                qingpingDevice?.connectBind(tokenString: inputToken, connectionChange: self.onDeviceConnectionChanged) { bindResult in
                    print("blue", "connectBind: = \(bindResult)")
                    debugCommands.append(DebugCommand(
                        "[Bind] Result",
                        bindResult ? "SUCCESS" : "FAILED",
                        nil
                    ))
                    isLoading = false
                    if (bindResult && advertisingData?.productId == 0xd) {
                        // 只有网关可写到0015
                        toCommonCharacteristic = false
                    } else {
                        toCommonCharacteristic = true
                    }
                }
            }
        }) {
            Text("Token: \(inputToken)")
        }
        .onAppear {
            BluetoothManager.shared.stopScan()
            qingpingDevice?.debugCommandListener = { command in
                self.debugCommands.append(command)
            }
            
        }
        .navigationTitle(deviceMacParsedFromMac).toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if (isLoading) {
                    ProgressView()
                } else {
                    if (isConnected) {
                        Button(action: {
                            print("blue", "start disconnect")
                            isConnected = false
                            qingpingDevice?.disconnect()
                            toCommonCharacteristic = true
                        }) {
                            Image(systemName: "cable.connector.slash")
                        }
                    } else {
                        Button(action: {
                            showConnectingDialog = true
                        }) {
                            Image(systemName: "cable.connector")
                        }
                    }
                }
                
            }
        }
    }
}


func sendMessage(_ message: String, toDevice qingpingDevice: QingpingDevice, toCommonCharacteristic: Bool, responder: @escaping CommandResponder) {
    if (!toCommonCharacteristic) {
        // 通常是指网关的命令，或其它设备的高级命令
        qingpingDevice.writeCommand(command: QpUtils.hexToData(hexString: message), responder: responder)
    } else {
        qingpingDevice.writeInternalCommand(command: QpUtils.hexToData(hexString: message), responder: responder)
    }
}

struct Inputer: View {
    @State var inputText = ""
    let enabled: Bool
    let targetUuid: String
    let menuItems: Array<(text: String, hex: String, onMenuClick: ((Int)->String?)? )>
    let onSendMessage: (String) -> Void
    var body: some View {
        VStack {
            HStack {
                Menu {
                    ForEach(0 ..< menuItems.count) { index in
                        let (text, hex, onClick) = menuItems[index]
                        if (text.isEmpty) {
                            Divider()
                        } else {
                            if (targetUuid == hex) {
                                Button(text, systemImage:  "checkmark.circle") {
                                    if (!hex.isEmpty) {
                                        onSendMessage(hex)
                                    }
                                    
                                    if let newHex = onClick?(index) {
                                        onSendMessage(newHex)
                                    }
                                }
                            } else {
                                Button(text) {
                                    if (!hex.isEmpty) {
                                        onSendMessage(hex)
                                    }
                                    
                                    if let newHex = onClick?(index) {
                                        onSendMessage(newHex)
                                    }
                                }
                            }
                            
                        }
                    
                    }
                } label: {
                    Image(systemName: "filemenu.and.selection").padding()
                }.disabled(menuItems.isEmpty)
                
                TextField("Command", text: $inputText, onEditingChanged: { changed in
                    if (changed) {
                        inputText = try! inputText.uppercased().replacing(Regex("[^0-9A-F]"), with: "")
                    }
                }) {
                    
                }
                .padding()
                    
                    .border(Color.black, width: 1)
                    .font(.system(size: 20))
                    .keyboardType(.numberPad)
                    
                
                Button(action: {
                    onSendMessage(inputText)
                    inputText = ""
                }, label: {
                    Image(systemName: "paperplane")
                }).padding()
            }.padding(0)
            HStack {
                KeyboardKey(text: "A") {
                    inputText += "A"
                }
                KeyboardKey(text: "B") {
                    inputText += "B"
                }
                KeyboardKey(text: "C") {
                    inputText += "C"
                }
                KeyboardKey(text: "D") {
                    inputText += "D"
                }
                KeyboardKey(text: "E") {
                    inputText += "E"
                }
                KeyboardKey(text: "F") {
                    inputText += "F"
                }
            }.padding(.horizontal)
        }.disabled(!enabled)
    }
}

struct KeyboardKey: View {
    let text: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(text)
                .frame(height: 40)
                .frame(maxWidth: .infinity)
                .border(Color.black)
        }
    }
}



//#Preview {
////    E()
//}
