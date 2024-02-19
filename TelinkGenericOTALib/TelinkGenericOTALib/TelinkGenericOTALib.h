/********************************************************************************************************
 * @file     TelinkGenericOTALib.h
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

//! Project version number for TelinkGenericOTALib.
FOUNDATION_EXPORT double TelinkGenericOTALibVersionNumber;

//! Project version string for TelinkGenericOTALib.
FOUNDATION_EXPORT const unsigned char TelinkGenericOTALibVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <TelinkGenericOTALib/PublicHeader.h>

#if DEBUG
#define TelinkDebugLog(format, ...) \
NSLog((format),##__VA_ARGS__);
#else
#define TelinkDebugLog(format, ...)
#endif

#import <CoreBluetooth/CoreBluetooth.h>

#import <TelinkGenericOTALib/TelinkConst.h>
#import <TelinkGenericOTALib/TelinkDeviceModel.h>
#import <TelinkGenericOTALib/TelinkBluetoothManager.h>
#import <TelinkGenericOTALib/TelinkOtaManager.h>
