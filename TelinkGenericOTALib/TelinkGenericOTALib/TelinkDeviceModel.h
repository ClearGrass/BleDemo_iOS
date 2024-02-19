/********************************************************************************************************
 * @file     TelinkDeviceModel.h
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TelinkDeviceModel : NSObject
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSDictionary<NSString *,id> *advertisementData;//扫描到的蓝牙设备广播包完整数据
@property (nonatomic, strong) NSNumber *RSSI;

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) NSString *advName;//广播包中的CBAdvertisementDataLocalNameKey
@property (nonatomic, strong) NSString *bleName;//peripheral.name

- (instancetype)initWithPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI;

/// UI界面显示的设备名称，如果广播包存在CBAdvertisementDataLocalNameKey则显示该名称，不存在则显示peripheral.name
- (NSString *)showName;

@end

NS_ASSUME_NONNULL_END
