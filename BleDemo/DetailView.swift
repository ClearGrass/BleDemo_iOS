//
//  DetailView.swift
//  BleDemo
//
//  Created by qingping on 2024/2/4.
//

import Foundation
import SwiftUI
import CoreBluetooth
import TelinkGenericOTALib

struct DetailPage: View {
    
    @State var showConnectingDialog = false
    @State var showInputWiFi = false
    @State var onInputWiFiSsidPass: OnWifiInput? = {ssid, pass in
    }
    @State var inputToken = "ABCDEFGHIJK"
    var uuid = UUID()
    var deviceName = "蓝牙设备"
    var advertisingData: ScanResultParsed? = nil
    
    @State var isLoading = false
    @State var isConnected = false
    
    @State var toCommonCharacteristic = true
    @State var debugCommands: [DebugCommand] = [
        DebugCommand(action: "init",uuid: "0000",data: nil)
    ]
    @State var qingpingDevice: QingpingDevice?
    var deviceMacParsedFromMac: String {
        return advertisingData?.mac ?? "none mac"
    }
    var onDeviceConnectionChanged: ConnectionStatusChanged {
        return (
            onConnected: { _ in
                print("blue", "device connected")
                debugCommands.append(DebugCommand(action: "[Connected]", uuid: deviceMacParsedFromMac, data: nil))
                isConnected = true
            },
            onDisconnected: { _ in
                print("blue", "device disconnected")
                debugCommands.append(DebugCommand(action: "[Disonnected]", uuid: deviceMacParsedFromMac, data: nil))
                isConnected = false
                isLoading = false
                toCommonCharacteristic = true
            }
        )
    }
    var body: some View {
        VStack() {
            ScrollViewReader { scrollView  in
                List() {
                    Section(content: {
                        Text((advertisingData?.rawData.display())!)
                    }, header: {Text(deviceName)}) {
                        Text("\(uuid.uuidString)")
                    }
                    Section {
                        ForEach(debugCommands, id: \.id) { cmd in
                            VStack(alignment: .leading) {
                                Text(
                                    ((cmd.action
                                      + "   -> "
                                      + cmd.uuid
                                     ) + (cmd.data?.display(prefix:"\n0x") ?? "")
                                    ).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                                )
                                if let data: Data = cmd.data, (data.count > 5 && !data[1].isFF()) {
                                    Text(
                                        "[string: \(Data(data.subdata(in: 2..<data.count)).string().replacing("\t", with: "\n"))]"
                                    )
                                }
                            }
                        }
                    }
                }.onChange(of: debugCommands.count) { _, _ in
                    if let lastid = debugCommands.last?.id {
                        scrollView.scrollTo(lastid)
                    }
                }
            }
            Inputer(
                enabled: !isLoading && isConnected,
                // 网关有0015特征，其它没有。
                toCommonCharacteristic: $toCommonCharacteristic,
                menuItems: (advertisingData?.productId == 0xd ? [
                    ("AP LIST(07)", "0107", nil),
                    ("连接WIFI(01)", "", { index, onCommandCreated in
                        showInputWiFi = true
                        onInputWiFiSsidPass = {ssid, pass in
                            let wifidata = QpUtils.wrapProtocol(1, data: "\"\(ssid)\",\"\(pass)\"".toData())
                            debugCommands.append(DebugCommand(action: "input", uuid: "WIFI信息", data: wifidata))
                            onCommandCreated?(wifidata.display())
                        }
                    }),
                    ("client_id(1E)", "011E", nil)
                ].reversed(): [
                    ("固件更新", "", { _, _ in
                        var filename = ""
                        if (advertisingData?.productId == 0x04) {
                            filename = "0x04_hodor_2_1_6"
                        } else if (advertisingData?.productId == 0x12) {
                            filename = "0x12_parrot_2_6_0"
                        } else {
                            debugCommands.append(DebugCommand(action: "Upgrading", uuid: "Firmware not found 0x${device?.productType?.toString(16)}", data: nil))
                            return
                        }
                        let fileUrl = Bundle.main.url(forResource: "Files/\(filename)", withExtension: "bin")!
                        let localFile = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appending(path: "\(filename).bin")
                        if !FileManager.default.fileExists(atPath: localFile.path()) {
                            try! FileManager.default.copyItem(at: fileUrl, to: localFile)
                        }
                        let fileData = try! Data(contentsOf: localFile)
                        
                        
                        let otaManager = TelinkOtaManager.share()
                        TelinkBluetoothManager.shareCentral().centralManager = BluetoothManager.shared.centralManager
                        TelinkBluetoothManager.shareCentral().centralManager.delegate = TelinkBluetoothManager.shareCentral() as! any CBCentralManagerDelegate
                        otaManager.startOTA(withOtaData: fileData, peripheral: qingpingDevice!.peripheral, otaProgressAction: { progress in
                            print("progress \(progress)")
                            if debugCommands.last?.action == "OTA_Progress" {
                                debugCommands.remove(at: debugCommands.count - 1)
                            }
                            debugCommands.append(DebugCommand(action: "OTA_Progress", uuid: "\(Float(Int(progress * 1000)) / 10.0)%", data: nil))
                        }, otaResultAction: { peripheral, err  in
                            print("result = \(peripheral)   info = \(String(describing: err))")
                            if let err = err {
                                debugCommands.append(DebugCommand(action: "OTA_Error", uuid: "OTA_Error \(err)", data: nil))
                            } else {
                                debugCommands.append(DebugCommand(action: "OTA_Succ", uuid: "OTA_Succ", data: nil))
                            }
                            if (peripheral.state == .disconnected) {
                                self.isConnected = false
                            }
                            self.isLoading = false
                        })
                        debugCommands.append(DebugCommand(action: "OTA_Start", uuid: "\(localFile.path())", data: nil))
                        self.isLoading = true
                    })
                ])
            ) { message in
                sendMessage(message, toDevice: qingpingDevice!, toCommonCharacteristic: toCommonCharacteristic) { response in
                    if (!toCommonCharacteristic) {
                        print("blue", "ble response  \(response.display())")
                        //这里把比较特殊的协议回应解析后显示到界面上中方便查看。
                        // WIFI列表
                        if (response[0].isFF() && response[1] == 0x7) {
                            // 这是WIFI 列表
                            debugCommands.append(DebugCommand(action: "parse", uuid: "WIFI列表", data: response))
                        }

                        // 连接WIFI结果
                        if (response[1] == 0x01) {
                            debugCommands.append(DebugCommand(action: "parse", uuid: (response[2] == 1) ? "连接WIFI成功" : "连接WIFI失败", data: response))
                        }
                    } else {
                        if (response[0].isFF() && response[1] == 0x1e) {
                            // 这是 client_id
                            debugCommands.append(DebugCommand(
                                action: "parse",
                                uuid: "0002; client_id",
                                data: response
                            ))
                        }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .confirmationDialog("请问执行【连接验证】还是执行【连接并绑定】设备？", isPresented: $showConnectingDialog, titleVisibility: .visible, actions: {
            Button("连接验证") { [self]
                print("blue", "start connect")
                isLoading = true
                
                toCommonCharacteristic = true
                debugCommands.append(DebugCommand(action: "Connecting and Verify!",
                                                  uuid: deviceMacParsedFromMac,
                                                  data: QpUtils.wrapProtocol(1, data: inputToken.toData())
                ))
                
                qingpingDevice?.connectVerify(tokenString: inputToken, connectionChange: self.onDeviceConnectionChanged){ verifyResult in
                    print("blue", "connectVerify: = \(verifyResult)")
                    debugCommands.append(DebugCommand(
                        action: "[Verify] Result",
                        uuid: verifyResult ? "SUCCESS" : "FAILED",
                        data: nil
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
                debugCommands.append(DebugCommand(action: "Connecting and Bind!",
                                                  uuid:deviceMacParsedFromMac,
                                                  data: QpUtils.wrapProtocol(1, data: inputToken.toData())
                ))
                
                qingpingDevice?.connectBind(tokenString: inputToken, connectionChange: self.onDeviceConnectionChanged) { bindResult in
                    print("blue", "connectBind: = \(bindResult)")
                    debugCommands.append(DebugCommand(
                        action: "[Bind] Result",
                        uuid: bindResult ? "SUCCESS" : "FAILED",
                        data: nil
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
        .sheet(isPresented: $showInputWiFi, onDismiss: {
            showInputWiFi = false
            onInputWiFiSsidPass = nil
        },  content: {
            NavigationView {
                WifiInputer(showing: $showInputWiFi, onInputSsidPass: $onInputWiFiSsidPass)
            }.presentationDetents([.height(200)])
            .presentationDragIndicator(.automatic)
        })
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
