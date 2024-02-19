/********************************************************************************************************
 * @file     TelinkDeviceModel.m
 *
 * @brief    A concise description.
 *
 * @author       梁家誌
 * @date         2020/7/14
 *
 * @par
 *
 *           The information contained herein is confidential property of Telink
 *           Semiconductor (Shanghai) Co., Ltd. and is available under the terms
 *           of Commercial License Agreement between Telink Semiconductor (Shanghai)
 *           Co., Ltd. and the licensee or the terms described here-in. This heading
 *           MUST NOT be removed from this file.
 *
 *           Licensee shall not delete, modify or alter (or permit any third party to delete, modify, or
 *           alter) any information contained herein in whole or in part except as expressly authorized
 *           by Telink semiconductor (shanghai) Co., Ltd. Otherwise, licensee shall be solely responsible
 *           for any claim to the extent arising out of or relating to such deletion(s), modification(s)
 *           or alteration(s).
 *
 *           Licensees are granted free, non-transferable use of the information in this
 *           file under Mutual Non-Disclosure Agreement. NO WARRENTY of ANY KIND is provided.
 *
 *******************************************************************************************************/

#import "TelinkDeviceModel.h"

@implementation TelinkDeviceModel

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    self = [super init];
    if (self) {
        _peripheral = peripheral;
        _advertisementData = advertisementData;
        _RSSI = RSSI;
        
        _uuid = peripheral.identifier.UUIDString;
        _advName = advertisementData[CBAdvertisementDataLocalNameKey];
        _bleName = peripheral.name;        
    }
    return self;
}

/// UI界面显示的设备名称，如果广播包存在CBAdvertisementDataLocalNameKey则显示该名称，不存在则显示peripheral.name
- (NSString *)showName {
    NSString *tem = nil;
    if (_advName && _advName.length > 0) {
        tem = _advName;
    } else {
        if (_bleName && _bleName.length > 0) {
            tem = _bleName;
        }
    }
    return tem;
}

- (BOOL)isEqual:(id)object {
    if ([object isKindOfClass:[TelinkDeviceModel class]]) {
        return [_uuid isEqualToString:[(TelinkDeviceModel *)object uuid]];
    } else {
        return NO;
    }
}

@end
