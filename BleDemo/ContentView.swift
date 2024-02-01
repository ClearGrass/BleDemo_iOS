//
//  ContentView.swift
//  BleDemo
//
//  Created by qingping on 2024/1/30.
//

import SwiftUI

struct ContentView: View {
    @State var selectedPrd = 0
    @State var onlyPairing = false
    @State private var isScanning = false
    @State var scanDevice: [ScanResultDevice] = [
        ScanResultDevice(name: "FakeDeivce", uuid: UUID(), rssi: -40, data: ScanResultParsed(
            frameControl: FrameControl(
                binding: true
            ), productId: 0x0d, mac: "AABBCCDDEEFF", rawData: Data())
        ),
        ScanResultDevice(name: "FakeDeivce", uuid: UUID(), rssi: -40, data: ScanResultParsed(
            frameControl: FrameControl(
                binding: false
            ), productId: 0x0d, mac: "AABBCCDDEEFF", rawData: Data())
        )
    ]
    @State var filterText = ""

    var body: some View {
        NavigationView {
            VStack() {
                FilterBar(
                    selectedPrd: $selectedPrd, onlyPairing: $onlyPairing, isLoading: $isScanning
                )
                TextField("过滤 MAC 地址或设备名称", text: $filterText)
                    .padding()
                List {
                    Section {
                        NavigationLink(destination: DetailPage(
                            uuid: UUID(),
                            deviceName: "tome")
                        ) {
                            Text("Item 1")
                        }
                    }
                    ForEach(onlyPairing ? try! scanDevice.filter { d in
                        d.data.frameControl.binding
                    } : scanDevice) { device in
                        Section {
                            NavigationLink(destination: DetailPage(
                                uuid: device.uuid,
                                deviceName: device.name,
                                advertisingData: device.data
                            )
                            ) {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Text(device.name)
                                        Spacer()
                                        Text("\(device.rssi)")
                                    }
                                    HStack {
                                        Text(device.data.mac)
                                        Spacer()
                                        if (device.data.frameControl.binding) {
                                            Text("binding").foregroundStyle(Color.red)
                                        }
                                    }
                                    Text(device.uuid.uuidString)
                                    Text(device.data.rawData.display())
                                }
                            }
                        }.padding(0)
                    }
                    
                    
                }.listSectionSpacing(10)
            }
            .frame(alignment: .top)
            
        }
    }
}

struct FilterBar: View {
    @Binding var selectedPrd: Int
    @Binding var onlyPairing: Bool
    @Binding var isLoading: Bool
    var body: some View {
        HStack(content: {
            Text("产品：")
            Picker("products", selection: $selectedPrd) {
                Text("不限").tag(0)
                Text("网关").tag(1)
                Text("门窗传感器").tag(2)
                Text("动作感应器").tag(3)
            }
            .disabled(isLoading)
            Toggle(isOn: $onlyPairing) {
                Text("仅binding：")
            }
            .disabled(isLoading)
            .padding(.trailing, 35)
            Spacer()
            if isLoading {
                Button(action: {
                    isLoading = false
                }) {
                    Image(systemName: "xmark")
                }
            } else {
                Button(action: {
                    isLoading = true
                }) {
                    Image(systemName: "magnifyingglass")
                }
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
                }, header: {Text(deviceName)})
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
