//
//  QpUtils.swift
//  BleDemo
//
//  Created by qingping on 2024/2/5.
//

import Foundation


typealias QProtocol = (
    type: UInt8,
    resultSuccess: Bool,
    data: Data?,
    count: Int,
    page: Int
)
class QpUtils {
    static func wrapProtocol(_ protocolType: UInt8, data: Data? = nil) -> Data {
        if let data = data {
            return Data([UInt8(data.count) + 1, protocolType]) + data
        } else {
            return Data([1, protocolType])
        }
    }
    
    static func parseProtocol(dataBytes: Data, withPage:Bool = false) -> QProtocol? {
        if (dataBytes.count < 2) {
            return nil
        }
        if (dataBytes[1].isFF()) {  //如： 0x04FF010000
            // 第一个字节是0x04，表示数据长度是0x04
            // 第二个字节是0xFF，表示这一包用于表示成功失败
            // 第三个字节是0x01，表示协议类型是 01 （绑定）
            // 第四五个字节是0x00 00，表示成功，在解析时：如果是 0x01 00 ，从后向前取每一个字节成为： 00 01，则==1

            
            let data = dataBytes.subdata(in: 3..<dataBytes.endIndex)
            let succ = data.number() == 0

            return QProtocol(dataBytes[2], succ, data, 1, 1)
        } else {
            // 解析协议
            // 其它如：0x06081122334466
            let type = dataBytes[1]
            // 从第三位开始，都是数据
            let data = dataBytes.subdata(in: 2..<dataBytes.endIndex)
            let succ = true
            if (!withPage || dataBytes.count < 3) {
                return QProtocol(type, succ, data, 1, 1)
            } else {
                // 对于长数据。如  0x13-07-1e-01-22-51-69-6e-67-70-69-6e-67-20-41-50-22-2c-34-2c
                // 第三位1e表示共几条，每四位的01表示这是第几条。计数从1开始。
                // 第五位22开始，都是数据
                let count: Int = Int(dataBytes[2])
                let page: Int = Int(dataBytes[3])
                return QProtocol(type, succ, data.subdata(in: 2..<data.endIndex), count, page)
            }
        }
    }
    
    static func hexToData(hexString: String) -> Data {
        let randomHex = hexString
            .replacing(pattern: "^0x", with: "")
            .replacing(pattern: "[^0-9A-Fa-f]", with: "")
            .uppercased()

        var data = Data(capacity: randomHex.count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9ABCDEF]{2}", options: .caseInsensitive)
        let range = NSMakeRange(0, (randomHex as NSString).length)
        regex.matches(in: randomHex, range: range).forEach { nstext in
            let subs = randomHex[Range(nstext.range, in: randomHex)!]
            let num = UInt8(subs, radix: 16)!
            data.append(num)
        }
        
        return data
        
    }
}
