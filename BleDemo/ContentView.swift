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
                    return d.name.lowercased().contains(filterText.lowercased())
                    || d.mac.replacing(pattern: "[^0-9A-F]", with: "").contains(filterText.uppercased())
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
                        BluetoothManager.shared.scan { peripheral, adver, rssi, localname  in
                            let device = ScanResultDevice(
                                peripheral: peripheral,
                                data: adver,
                                rssi: rssi,
                                localname: localname
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
            .scrollDismissesKeyboard(.immediately)
            
        }.onAppear {
            BluetoothManager.shared.setOnBleStateChanged { state in
                print("blue", "ui state=\(state.rawValue)")
                DispatchQueue.main.async {
                    bleStateReady = state == CBManagerState.poweredOn
                }
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
                Text("网关(0x0D)").lineLimit(1).tag(0xd)
                Text("门窗传感器(0x04)").lineLimit(1).tag(0x4)
                Text("人体传感器(0x12)").lineLimit(1).tag(0x12)
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

#Preview {
    ContentView()
}
