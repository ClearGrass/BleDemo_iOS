/********************************************************************************************************
 * @file     TelinkOtaManager.h
 *
 * @brief    A concise description.
 *
 * @author       梁家誌
 * @date         2020/7/21
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

typedef void(^otaProgressCallBack)(float progress);

/// 表格 7-4 CMD 的 opcode
/// - seeAlso: AN_20111001-C_Telink B91 BLE Single Connection SDK Developer Handbook.pdf  (page.303)
/// Note:
/// Use:To identify the command use in Legacy protocol、Extend protocol or both of all
/// Legacy: Only use in the Legacy protocol
/// Extend: Only use in the Extend protocol
/// All: use both in the Legacy protocol and Extend protocol
typedef enum : UInt16 {
    /// (Legacy)该命令为获得 slave 当前 firmware 版本号的命令，user 若采用 OTA Legacy protocol 进行 OTA 升级，可以选 择使用，在使用该命令时，可通过 slave 端预留的回调函数来完成 firmware 版本号的传递。
    TelinkOtaOpcode_otaVersion = 0xFF00,
    /// (Legacy)该命令为 OTA 升级开始命令，master 发这个命令给 slave，用来正式启动 OTA 更新。该命令仅供 Legacy Protocol 进行使用，user 若采用 OTA Legacy protocol，则必须使用该命令。
    TelinkOtaOpcode_otaStart = 0xFF01,
    /// (All)该命令为结束命令，OTA 中的 legacy 和 extend protocol 均采用该命令为结束命令，当 master 确定所有的 OTA 数据都被 slave 正确接收后，发送 OTA end 命令。为了让 slave 再次确定已经完全收到了 master 所有数据 (double check，加一层保险)，OTA end 命令后面带 4 个有效的 bytes，后面详细介绍。
    TelinkOtaOpcode_otaEnd = 0xFF02,
    /// (Extend)该命令为 extend protocol 中的 OTA 升级开始命令，master 发这个命令给 slave，用来正式启动 OTA 更新。 user 若采用 OTA extend protocol 则必须采用该命令作为开始命令。
    TelinkOtaOpcode_otaStartExtend = 0xFF03,
    /// (Extend)该命令为 OTA 升级过程中的版本比较请求命令，该命令由 client 发起给 Server 端，请求获取版本号和升级许 可。
    TelinkOtaOpcode_otaFirmWareVersionRequest = 0xFF04,
    /// (Extend)该命令为版本响应命令，server 端在收到 client 发来的版本比较请求命令(CMD_OTA_FW_VERSION_REQ) 后，会将已有的 firmware 版本号与 client 端请求升级的版本号进行对比，确定是否升级，相关信息通过该命令返 回发送给 client.
    TelinkOtaOpcode_otaFirmWareVersionResponse = 0xFF05,
    /// (All)该命令为 OTA 结果返回命令，OTA 结束后 slave 会将结果信息发送给 master，在整个 OTA 过程中，无论成功 或失败，OTA_result 只会上报一次，user 可根据返回的结果来判断升级是否成功。
    TelinkOtaOpcode_otaResult = 0xFF06,
} TelinkOtaOpcode;

/// Result:OTA 结果信息，所有可能的返回结果如下表所示:
/// - seeAlso: AN_20111001-C_Telink B91 BLE Single Connection SDK Developer Handbook.pdf  (page.307)
typedef enum : UInt8 {
    /// success
    TelinkOtaResultCode_success = 0x00,
    /// OTA data packet sequence number error: repeated OTA PDU or lost some OTA PDU.
    TelinkOtaResultCode_dataPacketSequenceError = 0x01,
    /// invalid OTA packet: 1. invalid OTA command; 2. addr_index out of range; 3.not standard OTA PDU length.
    TelinkOtaResultCode_packetInvalid = 0x02,
    /// packet PDU CRC err.
    TelinkOtaResultCode_dataCRCError = 0x03,
    /// write OTA data to flash ERR.
    TelinkOtaResultCode_writeFlashError = 0x04,
    /// lost last one or more OTA PDU.
    TelinkOtaResultCode_dataUncomplete = 0x05,
    /// peer device send OTA command or OTA data not in correct flow.
    TelinkOtaResultCode_flowError = 0x06,
    /// firmware CRC check error.
    TelinkOtaResultCode_firmwareCheckError = 0x07,
    /// the version number to be update is lower than the current version.
    TelinkOtaResultCode_versionCompareError = 0x08,
    /// PDU length error: not 16*n, or not equal to the value it declare in "CMD_OTA_START_EXT" packet.
    TelinkOtaResultCode_pduLengthError = 0x09,
    /// firmware mark error: not generated by telink's BLE SDK.
    TelinkOtaResultCode_firmwareMarkError = 0x0A,
    /// firmware size error: no firmware_size; firmware size too small or too big.
    TelinkOtaResultCode_firmwareSizeError = 0x0B,
    /// time interval between two consequent packet exceed a value(user can adjust this value).
    TelinkOtaResultCode_dataPacketTimeout = 0x0C,
    /// OTA flow total timeout.
    TelinkOtaResultCode_timeout = 0x0D,
    /// OTA fail due to current connection terminate(maybe connection timeout or local/peer device terminate connection).
    TelinkOtaResultCode_failDueToConnectionTerminate = 0x0E,
    // 0x0F~0xFF,Reserved for future use.
} TelinkOtaResultCode;

typedef enum : UInt8 {
    TelinkOtaProtocol_legacy = 0,
    TelinkOtaProtocol_extend = 1,
} TelinkOtaProtocol;

@interface OTASettingsModel : NSObject
@property (strong, nonatomic) NSString *serviceUuidString;
@property (strong, nonatomic) NSString *characteristicUuidString;
@property (assign, nonatomic) UInt8 readInterval;
/// 为了兼容iOS11以下系统而新增的发包间隔，单位毫秒。
@property (assign, nonatomic) UInt16 writeInterval;
@property (strong, nonatomic) NSString *filePath;
@property (assign, nonatomic) TelinkOtaProtocol protocol;
@property (assign, nonatomic) BOOL versionCompare;
@property (assign, nonatomic) UInt16 binVersion;
/// Extend模式的OTA，发送当个OTA包的最大OTA数据的长度，为16的倍数，范围是16*1~16*15。默认为16*1
@property (assign, nonatomic) UInt8 pduLength;

- (instancetype)initWithOTASettingsModel:(OTASettingsModel *)model;
- (NSDictionary *)outputSettingsDictionary;
- (void)inputSettingsDictionary:(NSDictionary *)dictionary;
- (NSString *)getDetailString;

@end

@interface TelinkOtaManager : NSObject
@property (strong, nonatomic) OTASettingsModel *settings;

+ (instancetype)share;

/**
    开始OTA接口，注意：需要客户已经调用`startConnectPeripheral:`连接设备成功的前提下才可以调用该OTA方法，且不可重复调用该接口。
 
 @param otaData data for OTA
 @param per peripheral for OTA
 @param otaProgressAction callback with single model OTA progress
 @param otaResultAction callback when peripheral OTA finish, OTA is successful when error is nil.
 @return  true when call API success;false when call API fail.
 */
- (BOOL)startOTAWithOtaData:(NSData *)otaData peripheral:(CBPeripheral *)per otaProgressAction:(otaProgressCallBack)otaProgressAction otaResultAction:(peripheralResultCallBack)otaResultAction;

/// 结束OTA接口
- (void)stopOTA;

@end

NS_ASSUME_NONNULL_END
