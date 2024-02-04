//
//  Inputer.swift
//  BleDemo
//
//  Created by qingping on 2024/2/4.
//

import Foundation
import SwiftUI

typealias MenuClicked = (Int) -> Void

struct Inputer: View {
    @State var inputText = ""
    let enabled: Bool
    let targetUuid: String
    let menuItems: Array<(text: String, hex: String, onMenuClick: MenuClicked? )>
    let onSendMessage: (String) -> Void
    var body: some View {
        VStack {
            HStack {
                Menu {
                    ForEach(0 ..< menuItems.count) { index in
                        let (text, hex, onMenuClick) = menuItems[index]
                        if (text.isEmpty) {
                            Divider()
                        } else {
                            if (targetUuid == hex) {
                                Button(text, systemImage:  "checkmark.circle") {
                                    if (!hex.isEmpty) {
                                        onSendMessage(hex)
                                    }
                                    onMenuClick?(index)
                                }
                            } else {
                                Button(text) {
                                    if (!hex.isEmpty) {
                                        onSendMessage(hex)
                                    }
                                    onMenuClick?(index)
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
