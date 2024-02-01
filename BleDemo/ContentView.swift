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
    @State var scanDevice: [ScanResultDevice] = []
    var filtedScanDevice: [ScanResultDevice] {
        get {
            if (!onlyPairing && selectedPrd == 0) {
                return scanDevice
            }
            return scanDevice.filter { d in
                if (onlyPairing && d.data.frameControl.binding == false) {
                    return false
                }
                if (selectedPrd > 0 && d.data.productId != selectedPrd) {
                    return false
                }
                return true
            }
        }
    }
    
    @State var filterText = ""
    
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
                                advertisingData: device.data
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
    var uuid = UUID()
    var deviceName = "蓝牙设备"
    var advertisingData: ScanResultParsed? = nil
    @State var toCommonCharacteristic = true
    @State var debugCommands: [Command] = [
        Command("init","0000",nil)
    ]
    var body: some View {
        VStack() {
            List() {
                Section(content: {
                    Text("0x1122334455667788")
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
                enabled: true,
                targetUuid: toCommonCharacteristic ? "0x0001" : "0x0015",
                menuItems: [
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
                ].reversed()
            ) { message in
                debugCommands.append(Command(
                    "write",
                    toCommonCharacteristic ? "0x0001" : "0x0015",
                    QpUtils.hexToData(hexString: message)
                ))
                
            }
        }.navigationTitle(advertisingData?.mac ?? "MAC EMPTY")
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
                            Button(text, systemImage: targetUuid == hex ? "checkmark" : "", role: .cancel) {
                                if (!hex.isEmpty) {
                                    onSendMessage(hex)
                                }
                                
                                if let newHex = onClick?(index) {
                                    onSendMessage(newHex)
                                }
                            }
                        }
                    
                    }
                } label: {
                    Image(systemName: "filemenu.and.selection").padding()
                }
                
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
        }
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
#Preview {
    ContentView()
}
