//
//  ScanResultParsed.swift
//  BleDemo
//
//  Created by qingping on 2024/2/1.
//

import Foundation
struct ScanResultParsed: Equatable {
    init?(fdcdData: Data) {
        self.rawData = fdcdData
        self.productId = fdcdData[1]
        self.mac = Data(fdcdData.subdata(in: 2..<8).reversed()).display(dimter:":", prefix: "").uppercased()
        self.frameControl = FrameControl(byte0: fdcdData.first!)
    }
    
    static func == (lhs: ScanResultParsed, rhs: ScanResultParsed) -> Bool {
        return lhs.productId == rhs.productId && lhs.mac == rhs.mac
    }
    
    let frameControl: FrameControl
    let productId: UInt8
    let mac: String
    let rawData: Data
}


struct FrameControl {
    init(byte0: UInt8) {
        aes = byte0 & 0x1 > 0
        binding = byte0 & 0x2 > 0
        isBooting = byte0 & 0x4 > 0
        version = (byte0 >> 3) & 0x07
        isEvent = byte0 & 0x40 > 0
        hasBind = byte0 & UInt8(0x80) > 0
    }
    let aes: Bool
    let binding: Bool
    let isBooting: Bool
    let version: UInt8
    let isEvent: Bool
    let hasBind: Bool
}
