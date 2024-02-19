/********************************************************************************************************
 * @file     TelinkConst.h
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
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - Const string

UIKIT_EXTERN NSString * const kTelinkGenericOTALibVersion;//@"v2.0.0"
UIKIT_EXTERN NSString * const kOTAServiceUUID;//@"00010203-0405-0607-0809-0a0b0c0d1912"
UIKIT_EXTERN NSString * const kOTACharacteristicUUID;//@"00010203-0405-0607-0809-0a0b0c0d2b12"

#pragma mark - Const int

UIKIT_EXTERN UInt8 const kOTAWriteInterval;//6ms
UIKIT_EXTERN UInt8 const kOTAReadInterval;//8
UIKIT_EXTERN UInt8 const kOTAReadTimeout;//5

NS_ASSUME_NONNULL_END
