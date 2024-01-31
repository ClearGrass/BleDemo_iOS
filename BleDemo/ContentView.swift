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
                        NavigationLink(destination: DetailPage()) {
                            Text("Item 1")
                        }
                    }
                    Section {
                        NavigationLink(destination: DetailPage()) {
                            Text("Item 1")
                        }
                    }.padding(0)
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
                ProgressView()
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
    var body: some View {
        VStack() {
            List() {
                Section {
                    Text("0x1122334455667788")
                }
                Section {
                    Text("asdf")
                    Text("asdf")
                }
            }
            Inputer(
                enabled: true,
                targetUuid: "0001",
                menuItems: [
                    ("AP LIST(07)", "0107"),
                    ("连接WIFI(01)", ""),
                    ("client_id(1E)", "011E")
                ]
            ) { message in
                                
            }
        }.navigationTitle("asdf")
            
    }
}

struct Inputer: View {
    @State var inputText = ""
    let enabled: Bool
    let targetUuid: String
    let menuItems: Array<(String, String)>
    let onSendMessage: (String) -> Void
    var body: some View {
        VStack {
            HStack {
                Button(action: {
                    onSendMessage(inputText.uppercased())
                }) {
                    Image(systemName: "filemenu.and.selection")
                }.padding()
                
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
    NavigationView {
        ContentView()
    }
}
