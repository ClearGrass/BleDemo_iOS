//
//  ScanResultParsed.swift
//  BleDemo
//
//  Created by qingping on 2024/2/1.
//

import Foundation
struct ScanResultParsed: Equatable {
    static func == (lhs: ScanResultParsed, rhs: ScanResultParsed) -> Bool {
        return lhs.productId == rhs.productId && lhs.mac == rhs.mac
    }
    
    let frameControl: FrameControl
    let productId: UInt8
    let mac: String
    let rawData: Data
}


struct FrameControl {
    let binding: Bool
}
