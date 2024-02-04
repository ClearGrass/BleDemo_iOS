//
//  Inputer.swift
//  BleDemo
//
//  Created by qingping on 2024/2/4.
//

import Foundation
import SwiftUI

typealias MenuClicked = (Int, _ onCommandCreated: ((String) -> Void)?) -> Void

struct Inputer: View {
    @State var inputText = ""
    let enabled: Bool
    @Binding var toCommonCharacteristic: Bool
    let menuItems: Array<(text: String, hex: String, onMenuClick: MenuClicked? )>
    let onSendMessage: (String) -> Void
    var body: some View {
        VStack {
            HStack {
                Menu {
                    Button("写到0001", systemImage:  toCommonCharacteristic ? "checkmark.circle": "cirle") {
                        toCommonCharacteristic = true
                    }
                    
                    Button("写到0015", systemImage:  !toCommonCharacteristic ? "checkmark.circle": "cirle") {
                        toCommonCharacteristic = false
                    }
                    Divider()
                    ForEach(0 ..< menuItems.count) { index in
                        let (text, hex, onMenuClick) = menuItems[index]
                        Button(text) {
                            if (!hex.isEmpty) {
                                onSendMessage(hex)
                            }
                            onMenuClick?(index) { newHex in
                                if !newHex.isEmpty {
                                    onSendMessage(newHex)
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




typealias OnWifiInput = ((_ ssid: String, _ pass: String) -> ())

struct WifiInputer: View {
    @State var inputSSID = ""
    @State var inputPass = ""
    @FocusState private var keyboardFocused: Bool
    @Binding var showing: Bool
    @Binding var onInputSsidPass: OnWifiInput?
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack() {
                Text("SSID")
                TextField(
                    "SSID", text: $inputSSID
                )
                .focused($keyboardFocused)
                .keyboardType(.alphabet)
                .font(.system(size: 18))
                .padding(10)
                .border(.gray)
                .padding(10)
                .frame(maxWidth: .infinity)
                .focusable()
            }
            HStack() {
                Text("Pass")
                TextField(
                    "Password", text: $inputPass
                )
                .keyboardType(.alphabet)
                .font(.system(size: 18))
                .padding(10)
                .border(.gray)
                .padding(10)
                .frame(maxWidth: .infinity)
            }
        }.frame(maxWidth: .infinity).padding(30)
            .onAppear {
                UITextField.appearance().clearButtonMode = .whileEditing
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    keyboardFocused = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("连接") {
                        self.onInputSsidPass?(inputSSID, inputPass)
                        onInputSsidPass = nil
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
//                        onInputSsidPass = nil
                    }
                }
            }
    }
}


struct FakeForWifi : View {
    @State var show = false
    @State var callback: OnWifiInput? = {ssid, pass in
    }
    var body: some View {
        WifiInputer(showing: $show, onInputSsidPass: $callback)
    }
}

#Preview(body: {
    NavigationView(content: {
        FakeForWifi()
    })
})
