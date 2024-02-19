/********************************************************************************************************
 * @file     TelinkOtaManager.m
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

#import "TelinkOtaManager.h"

@implementation OTASettingsModel
- (instancetype)init {
    if (self = [super init]) {
        _serviceUuidString = nil;
        _characteristicUuidString = nil;
        if (@available(iOS 11.0, *)) {
            _readInterval = 0;
            _writeInterval = 0;
        } else {
            _readInterval = kOTAReadInterval;
            _writeInterval = kOTAWriteInterval;
        }
        _filePath = nil;
        _protocol = TelinkOtaProtocol_legacy;
        _versionCompare = NO;
        _binVersion = 0x0;
        _pduLength = 16*1;
    }
    return self;
}

- (instancetype)initWithOTASettingsModel:(OTASettingsModel *)model {
    if (self = [super init]) {
        _serviceUuidString = model.serviceUuidString;
        _characteristicUuidString = model.characteristicUuidString;
        _readInterval = model.readInterval;
        _writeInterval = model.writeInterval;
        _filePath = model.filePath;
        _protocol = model.protocol;
        _versionCompare = model.versionCompare;
        _binVersion = model.binVersion;
        _pduLength = model.pduLength;
    }
    return self;
}

- (void)setPduLength:(UInt8)pduLength {
    if (pduLength >= 16*1 && pduLength <= 16*15 && pduLength % 16 == 0) {
        _pduLength = pduLength;
        TelinkDebugLog(@"set pduLength to %d success!",pduLength);
    }
}

- (NSDictionary *)outputSettingsDictionary {
    NSMutableDictionary *mDict = [NSMutableDictionary dictionary];
    if (_serviceUuidString) {
        [mDict setValue:_serviceUuidString forKey:@"serviceUuidString"];
    }
    if (_characteristicUuidString) {
        [mDict setValue:_characteristicUuidString forKey:@"characteristicUuidString"];
    }
    [mDict setValue:@(_readInterval) forKey:@"readInterval"];
    [mDict setValue:@(_writeInterval) forKey:@"writeInterval"];
    if (_filePath) {
        [mDict setValue:_filePath forKey:@"filePath"];
    }
    [mDict setValue:@(_protocol) forKey:@"protocol"];
    [mDict setValue:@(_versionCompare) forKey:@"versionCompare"];
    [mDict setValue:@(_binVersion) forKey:@"binVersion"];
    [mDict setValue:@(_pduLength) forKey:@"pduLength"];
    return mDict;
}

- (void)inputSettingsDictionary:(NSDictionary *)dictionary {
    if ([dictionary.allKeys containsObject:@"serviceUuidString"]) {
        _serviceUuidString = dictionary[@"serviceUuidString"];
    }
    if ([dictionary.allKeys containsObject:@"characteristicUuidString"]) {
        _characteristicUuidString = dictionary[@"characteristicUuidString"];
    }
    if ([dictionary.allKeys containsObject:@"readInterval"]) {
        _readInterval = [dictionary[@"readInterval"] intValue];
    }
    if ([dictionary.allKeys containsObject:@"writeInterval"]) {
        _writeInterval = [dictionary[@"writeInterval"] intValue];
    }
    if ([dictionary.allKeys containsObject:@"filePath"]) {
        _filePath = dictionary[@"filePath"];
    }
    if ([dictionary.allKeys containsObject:@"protocol"]) {
        _protocol = [dictionary[@"protocol"] intValue];
    }
    if ([dictionary.allKeys containsObject:@"versionCompare"]) {
        _versionCompare = [dictionary[@"versionCompare"] intValue];
    }
    if ([dictionary.allKeys containsObject:@"binVersion"]) {
        _binVersion = [dictionary[@"binVersion"] intValue];
    }
    if ([dictionary.allKeys containsObject:@"pduLength"]) {
        _pduLength = [dictionary[@"pduLength"] intValue];
    }
}
- (NSString *)getDetailString {
    NSString *tem = @"";
    if (_serviceUuidString) {
        tem = [tem stringByAppendingFormat:@"service: %@",_serviceUuidString];
    } else {
        tem = [tem stringByAppendingString:@"service: [use default(1912)]"];
    }
    if (_characteristicUuidString) {
        tem = [tem stringByAppendingFormat:@"\ncharacteristic: %@",_characteristicUuidString];
    } else {
        tem = [tem stringByAppendingString:@"\ncharacteristic: [use default(2B12)]"];
    }
    tem = [tem stringByAppendingFormat:@"\nread interval: %d",_readInterval];
    tem = [tem stringByAppendingFormat:@"\nwrite interval: %d(ms)",_writeInterval];
    if (_filePath) {
        tem = [tem stringByAppendingFormat:@"\nfile path: %@",_filePath];
    } else {
        tem = [tem stringByAppendingString:@"\nfile path: error - file not selected"];
    }
    tem = [tem stringByAppendingFormat:@"\nprotocol: %@",_protocol == TelinkOtaProtocol_legacy ? @"Legacy" : @"Extend"];
    if (_protocol == TelinkOtaProtocol_extend) {
        tem = [tem stringByAppendingFormat:@"\nversion compare: %@",_versionCompare == YES ? @"true" : @"false"];
        tem = [tem stringByAppendingFormat:@"\nbin version: 0x%04X",_binVersion];
        tem = [tem stringByAppendingFormat:@"\npdu length: %d",_pduLength];
    }
    return tem;
}
@end

@interface TelinkOtaFirmWareVersionResponseModel : NSObject
@property (strong,nonatomic) NSData *parameters;
@property (assign,nonatomic) UInt16 versionNumber;
@property (assign,nonatomic) BOOL versionAccept;
@end
@implementation TelinkOtaFirmWareVersionResponseModel
- (instancetype)initWithParameters:(NSData *)parameters {
    if (self = [super init]) {
        _parameters = [NSData dataWithData:parameters];
        UInt16 tem16 = 0;
        Byte *dataByte = (Byte *)parameters.bytes;
        memcpy(&tem16, dataByte, 2);
        _versionNumber = tem16;
        UInt8 tem8 = 0;
        memcpy(&tem8, dataByte+2, 1);
        _versionAccept = tem8 == 0 ? NO : YES;
    }
    return self;
}
@end

@interface TelinkOtaResultModel : NSObject
@property (strong,nonatomic) NSData *parameters;
@property (assign,nonatomic) TelinkOtaResultCode result;
@end
@implementation TelinkOtaResultModel
- (instancetype)initWithParameters:(NSData *)parameters {
    if (self = [super init]) {
        _parameters = [NSData dataWithData:parameters];
        UInt8 tem8 = 0;
        Byte *dataByte = (Byte *)parameters.bytes;
        memcpy(&tem8, dataByte, 1);
        _result = tem8;
    }
    return self;
}
@end

@interface TelinkOtaManager ()
/// OTA流程及进度的回调
@property (nonatomic, copy, nullable) otaProgressCallBack otaProgressBlock;
/// OTA结果的回调
@property (nonatomic, copy, nullable) peripheralResultCallBack otaResultBlock;

/// OTA的bin文件二进制数据
@property (strong, nonatomic) NSData *otaData;
@property (nonatomic,assign) BOOL OTAing;
@property (nonatomic,assign) BOOL stopOTAFlag;
@property (nonatomic,assign) NSInteger offset;
/// 当前OTA数据包的下标Index值
@property (nonatomic,assign) NSInteger otaPackIndex;//index of current ota packet
@property (nonatomic,assign) BOOL sendFinish;
//@property (nonatomic,assign) NSTimeInterval writeOTAInterval;//interval of write ota data, default is 6ms
@property (nonatomic,assign) NSTimeInterval readTimeoutInterval;//timeout of read OTACharacteristic(write 8 packet, read one time), default is 5s.
@property (nonatomic,assign) BOOL isReading;
@end


@implementation TelinkOtaManager

#pragma mark- init
+ (instancetype)share {
    static TelinkOtaManager *_otaManager = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        _otaManager = [[TelinkOtaManager alloc] init];
    });
    return _otaManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _settings = [[OTASettingsModel alloc] init];
        _readTimeoutInterval = 5.0;
        _OTAing = NO;
        _stopOTAFlag = NO;
    }
    return self;
}

/**
 OTA，can not call repeat when app is OTAing
 
 @param otaData data for OTA
 @param per peripheral for OTA
 @param otaProgressAction callback with single model OTA progress
 @param otaResultAction callback when peripheral OTA finish, OTA is successful when error is nil.
 @return  true when call API success;false when call API fail.
 */
- (BOOL)startOTAWithOtaData:(NSData *)otaData peripheral:(CBPeripheral *)per otaProgressAction:(otaProgressCallBack)otaProgressAction otaResultAction:(peripheralResultCallBack)otaResultAction {
    if (_OTAing) {
        TelinkDebugLog(@"OTAing, can't call repeated.");
        return NO;
    }
    if (!otaData || otaData.length == 0) {
        TelinkDebugLog(@"OTA data is invalid.");
        return NO;
    }

    TelinkBluetoothManager.shareCentralManager.bluetoothIsReadyToSendWriteWithoutResponseBlock = nil;
    self.otaData = otaData;
    TelinkBluetoothManager.shareCentralManager.currentPeripheral = per;
    self.otaProgressBlock = otaProgressAction;
    self.otaResultBlock = otaResultAction;
    TelinkBluetoothManager.shareCentralManager.currentCharacteristic = nil;
    NSString *otaServiceUUIDString = @"00010203-0405-0607-0809-0a0b0c0d1912";
    if (self.settings.serviceUuidString && self.settings.serviceUuidString.length > 0) {
        otaServiceUUIDString = self.settings.serviceUuidString;
    }
    NSString *otaCharacteristicUUIDString = @"00010203-0405-0607-0809-0a0b0c0d2b12";
    if (self.settings.characteristicUuidString && self.settings.characteristicUuidString.length > 0) {
        otaCharacteristicUUIDString = self.settings.characteristicUuidString;
    }
    for (CBService *service in per.services) {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:otaServiceUUIDString]]) {
            for (CBCharacteristic *c in service.characteristics) {
                if ([c.UUID isEqual:[CBUUID UUIDWithString:otaCharacteristicUUIDString]]) {
                    TelinkBluetoothManager.shareCentralManager.currentCharacteristic = c;
                    break;
                }
            }
        }
    }
    if (TelinkBluetoothManager.shareCentralManager.currentCharacteristic == nil) {
        return NO;
    }
    if (TelinkBluetoothManager.shareCentralManager.currentCharacteristic.isNotifying) {
        [self startOtaAction];
    } else {
        __weak typeof(self) weakSelf = self;
        [TelinkBluetoothManager.shareCentralManager changeNotifyToState:YES Peripheral:TelinkBluetoothManager.shareCentralManager.currentPeripheral characteristic:TelinkBluetoothManager.shareCentralManager.currentCharacteristic timeout:5.0 resultBlock:^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nullable error) {
            [weakSelf startOtaAction];
        }];
    }
    return YES;
}

- (void)startOtaAction {
    __weak typeof(self) weakSelf = self;
    [TelinkBluetoothManager.shareCentralManager setDidDisconnectPeripheralResultBlock:^(CBPeripheral * _Nonnull peripheral, NSError * _Nullable error) {
        if (weakSelf.stopOTAFlag == NO) {
            if (weakSelf.otaResultBlock) {
                if ([peripheral isEqual:TelinkBluetoothManager.shareCentralManager.currentPeripheral]) {
                    if (!weakSelf.sendFinish) {
                        //OTA fail!
                        [weakSelf otaFailAction];
                    } else {
                        // 成功了。但先别通知，这里有个兼容。
                        if (!TelinkBluetoothManager.shareCentralManager.currentCharacteristic.isNotifying) {
                            TelinkDebugLog(@"Fake notify data = %@", @"success");
                            [weakSelf otaSuccessAction];
                        }
                    }
                }
            }
        }
    }];
    [TelinkBluetoothManager.shareCentralManager setDidUpdateValueForCharacteristicResultBlock:^(CBPeripheral * _Nonnull peripheral, CBCharacteristic * _Nonnull characteristic, NSError * _Nullable error) {
        if (error == nil) {
            NSData *notifyData = characteristic.value;
            TelinkDebugLog(@"notify data = %@",notifyData);
            if (weakSelf.isReading) {
                weakSelf.isReading = NO;
                [weakSelf sendOTAPartData];
                return;
            }
            
            TelinkOtaOpcode code = [weakSelf getTelinkOtaOpcodeWithPduData:notifyData];
            if (code == TelinkOtaOpcode_otaFirmWareVersionResponse) {
                TelinkOtaFirmWareVersionResponseModel *model = [[TelinkOtaFirmWareVersionResponseModel alloc] initWithParameters:[notifyData subdataWithRange:NSMakeRange(2, notifyData.length-2)]];
                TelinkDebugLog(@"TelinkOtaFirmWareVersionResponseModel=%@",model);
                if (model.versionAccept) {
                    [weakSelf sendOTAStartExtendWithOTAPacketLength:weakSelf.settings.pduLength versionCompare:weakSelf.settings.versionCompare];
                    [weakSelf startSendFirmwareData];
                } else {
                    NSError *err = [NSError errorWithDomain:@"FirmWareVersionResponse, versionAccept=NO." code:-1 userInfo:nil];
                    [weakSelf otaFailActionWithError:err];
                }
            } else if (code == TelinkOtaOpcode_otaResult) {
                TelinkOtaResultModel *model = [[TelinkOtaResultModel alloc] initWithParameters:[notifyData subdataWithRange:NSMakeRange(2, notifyData.length-2)]];
                TelinkDebugLog(@"TelinkOtaResultModel=%@,result=%@",model,[weakSelf getResultStringOfResultCode:model.result]);
                if (model.result == TelinkOtaResultCode_success) {
                    [weakSelf otaSuccessAction];
                } else {
                    NSError *err = [NSError errorWithDomain:[weakSelf getResultStringOfResultCode:model.result] code:model.result userInfo:nil];
                    [weakSelf otaFailActionWithError:err];
                }
            }
        }
    }];
    self.OTAing = YES;
    self.otaPackIndex = -1;
    self.sendFinish = NO;
    self.stopOTAFlag = NO;
    self.offset = 0;
    [self sendOTAVersionGet];
    if (self.settings.protocol == TelinkOtaProtocol_legacy) {
        [self sendOTAStart];
        [self startSendFirmwareData];
    } else if (self.settings.protocol == TelinkOtaProtocol_extend) {
        [self sendOTAFirmWareVersionRequestWithFirmWareVersion:self.settings.binVersion versionCompare:self.settings.versionCompare];
//        if (self.settings.versionCompare) {
//        } else {
//            [self sendOTAStartExtendWithOTAPacketLength:self.settings.pduLength versionCompare:NO];
//        }
    }
}

- (void)startSendFirmwareData {
    if (@available(iOS 11.0, *)) {
        //iOS11.0及以上
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(sendOTAPartDataAvailableIOS11) withObject:nil afterDelay:0.3];
        });
    } else {
        //iOS11.0以下
        dispatch_async(dispatch_get_main_queue(), ^{
            [self performSelector:@selector(sendOTAPartData) withObject:nil afterDelay:0.3];
        });
    }
}

/// stop OTA
- (void)stopOTA {
    if (_OTAing) {
        _stopOTAFlag = YES;
        _OTAing = NO;
        self.otaPackIndex = -1;
        self.sendFinish = NO;
        self.offset = 0;
        self.otaProgressBlock = nil;
        self.otaResultBlock = nil;
        TelinkBluetoothManager.shareCentralManager.currentCharacteristic = nil;
        self.otaData = nil;
        TelinkBluetoothManager.shareCentralManager.currentPeripheral = nil;
        TelinkBluetoothManager.shareCentralManager.bluetoothIsReadyToSendWriteWithoutResponseBlock = nil;
    }
}

- (void)otaSuccessAction {
    self.OTAing = NO;
    self.stopOTAFlag = YES;
    self.otaPackIndex = 0;
    TelinkBluetoothManager.shareCentralManager.bluetoothIsReadyToSendWriteWithoutResponseBlock = nil;
    if (self.otaResultBlock) {
        self.otaResultBlock(TelinkBluetoothManager.shareCentralManager.currentPeripheral, nil);
        self.otaResultBlock = nil;
    }
}

- (void)otaFailAction {
    self.OTAing = NO;
    self.stopOTAFlag = YES;
    self.otaPackIndex = 0;
    TelinkBluetoothManager.shareCentralManager.bluetoothIsReadyToSendWriteWithoutResponseBlock = nil;
    if (self.otaResultBlock) {
        NSError *err = [NSError errorWithDomain:@"The Peripheral is disconnected! OTA Fail!" code:-1 userInfo:nil];
        self.otaResultBlock(TelinkBluetoothManager.shareCentralManager.currentPeripheral, err);
        self.otaResultBlock = nil;
    }
}

- (void)otaFailActionWithError:(NSError *)error {
    self.OTAing = NO;
    self.stopOTAFlag = YES;
    self.otaPackIndex = 0;
    TelinkBluetoothManager.shareCentralManager.bluetoothIsReadyToSendWriteWithoutResponseBlock = nil;
    if (self.otaResultBlock) {
        self.otaResultBlock(TelinkBluetoothManager.shareCentralManager.currentPeripheral, error);
        self.otaResultBlock = nil;
    }
}

- (NSString *)getResultStringOfResultCode:(TelinkOtaResultCode)resultCode {
    NSString *tem = @"";
    switch (resultCode) {
        case TelinkOtaResultCode_success:
            tem = @"success";
            break;
        case TelinkOtaResultCode_dataPacketSequenceError:
            tem = @"OTA data packet sequence number error: repeated OTA PDU or lost some OTA PDU.";
            break;
        case TelinkOtaResultCode_packetInvalid:
            tem = @"invalid OTA packet: 1. invalid OTA command; 2. addr_index out of range; 3.not standard OTA PDU length.";
            break;
        case TelinkOtaResultCode_dataCRCError:
            tem = @"packet PDU CRC err.";
            break;
        case TelinkOtaResultCode_writeFlashError:
            tem = @"write OTA data to flash ERR.";
            break;
        case TelinkOtaResultCode_dataUncomplete:
            tem = @"lost last one or more OTA PDU.";
            break;
        case TelinkOtaResultCode_flowError:
            tem = @"peer device send OTA command or OTA data not in correct flow.";
            break;
        case TelinkOtaResultCode_firmwareCheckError:
            tem = @"firmware CRC check error.";
            break;
        case TelinkOtaResultCode_versionCompareError:
            tem = @"the version number to be update is lower than the current version.";
            break;
        case TelinkOtaResultCode_pduLengthError:
            tem = @"PDU length error: not 16*n, or not equal to the value it declare in \"CMD_OTA_START_EXT\" packet";
            break;
        case TelinkOtaResultCode_firmwareMarkError:
            tem = @"firmware mark error: not generated by telink's BLE SDK.";
            break;
        case TelinkOtaResultCode_firmwareSizeError:
            tem = @"firmware size error: no firmware_size; firmware size too small or too big.";
            break;
        case TelinkOtaResultCode_dataPacketTimeout:
            tem = @"time interval between two consequent packet exceed a value(user can adjust this value).";
            break;
        case TelinkOtaResultCode_timeout:
            tem = @"OTA flow total timeout.";
            break;
        case TelinkOtaResultCode_failDueToConnectionTerminate:
            tem = @"OTA fail due to current connection terminate(maybe connection timeout or local/peer device terminate connection).";
            break;
        default:
            tem = @"undefined result code";
            break;
    }
    return tem;
}

#pragma mark send ota packets
- (void)sendOTAPartData {
    if (self.stopOTAFlag || self.sendFinish) {
        return;
    }
        
    if (TelinkBluetoothManager.shareCentralManager.currentPeripheral && TelinkBluetoothManager.shareCentralManager.currentPeripheral.state == CBPeripheralStateConnected) {
        NSInteger lastLength = self.otaData.length - _offset;
        self.isReading = NO;
        
        //OTA 结束包特殊处理
        if (lastLength == 0) {
            [self sendOTAEndWithLastOtaIndex:self.otaPackIndex];
            self.sendFinish = YES;
            return;
        }
        
        self.otaPackIndex ++;
        
        NSInteger writeLength = (lastLength >= self.settings.pduLength) ? self.settings.pduLength : lastLength;
        NSData *writeData = [self.otaData subdataWithRange:NSMakeRange(self.offset, writeLength)];
        [self sendOTAData:writeData index:(int)self.otaPackIndex];
        self.offset += writeLength;
        
        float progress = ((float)self.offset) / self.otaData.length;
        if (self.otaProgressBlock) {
            self.otaProgressBlock(progress);
        }
        
        __weak typeof(self) weakSelf = self;
        if ((self.otaPackIndex + 1) % self.settings.readInterval == 0 && self.otaData.length != self.offset) {
            self.isReading = YES;
            [TelinkBluetoothManager.shareCentralManager readCharacteristicWithCharacteristic:TelinkBluetoothManager.shareCentralManager.currentCharacteristic ofPeripheral:TelinkBluetoothManager.shareCentralManager.currentPeripheral];
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(readTimeoutAction) object:nil];
                [weakSelf performSelector:@selector(readTimeoutAction) withObject:nil afterDelay:kOTAReadTimeout];
            });
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf performSelector:@selector(sendOTAPartData) withObject:nil afterDelay:weakSelf.settings.writeInterval/1000.0];
        });
    }
}

    - (void)readTimeoutAction {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readTimeoutAction) object:nil];
        });
        NSError *err = [NSError errorWithDomain:@"Read OTA characteristic is timeout! OTA Fail!" code:-1 userInfo:nil];
        [self otaFailActionWithError:err];
    }
    
- (void)sendOTAPartDataAvailableIOS11 {
    if (self.stopOTAFlag || self.sendFinish) {
        return;
    }
        
    if (TelinkBluetoothManager.shareCentralManager.currentPeripheral && TelinkBluetoothManager.shareCentralManager.currentPeripheral.state == CBPeripheralStateConnected) {
        NSInteger lastLength = self.otaData.length - _offset;
        //OTA 结束包特殊处理
        if (lastLength == 0) {
            [self sendOTAEndWithLastOtaIndex:self.otaPackIndex];
            self.sendFinish = YES;
            return;
        }
        
        self.otaPackIndex ++;
        
        NSInteger writeLength = (lastLength >= self.settings.pduLength) ? self.settings.pduLength : lastLength;
        NSData *writeData = [self.otaData subdataWithRange:NSMakeRange(self.offset, writeLength)];
        self.offset += writeLength;
        
        float progress = ((float)self.offset) / self.otaData.length;
        if (self.otaProgressBlock) {
            self.otaProgressBlock(progress);
        }
        
        __weak typeof(self) weakSelf = self;
        NSData *formatData = [self getOTAFormatDataWithData:writeData index:self.otaPackIndex];
        [TelinkBluetoothManager.shareCentralManager writeValueAvailableIOS11:formatData toPeripheral:TelinkBluetoothManager.shareCentralManager.currentPeripheral forCharacteristic:TelinkBluetoothManager.shareCentralManager.currentCharacteristic type:CBCharacteristicWriteWithoutResponse completeHandle:^(CBPeripheral * _Nonnull peripheral) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf performSelector:@selector(sendOTAPartDataAvailableIOS11) withObject:nil afterDelay:weakSelf.settings.writeInterval/1000.0];
            });
        }];
    }
}

/// 发送单个OTA数据包：组成结构：2字节index + 1~16字节的有效OTA数据 + 2字节CRC数据。
/// @param data 单个数据包包含的有效OTA数据，长度为1~16.
/// @param index 数据包下标，从0开始累加，两个字节长度。即0x0000~0xFFFF。
- (void)sendOTAData:(NSData *)data index:(int)index {
    NSData *writeData = [self getOTAFormatDataWithData:data index:index];
    [self sendOtaData:writeData];
}

- (NSData *)getOTAFormatDataWithData:(NSData *)data index:(UInt16)index {
    NSMutableData *mData = [NSMutableData data];
    UInt16 tem16 = index;
    NSData *temData = [NSData dataWithBytes:&tem16 length:2];
    [mData appendData:temData];
    [mData appendData:data];
    UInt8 packet16Count = ceil(data.length / 16.0);
    if (packet16Count * 16 > data.length) {
        Byte temBytes[16];
        memset(temBytes, 0xff, 16);
        temData = [NSData dataWithBytes:temBytes length:packet16Count * 16 - data.length];
        [mData appendData:temData];
    }
    Byte *tempBytes = (Byte *)[mData bytes];
    UInt16 crc = crc16(tempBytes, (int)mData.length);
    temData = [NSData dataWithBytes:&crc length:2];
    [mData appendData:temData];
    TelinkDebugLog(@"---->%@",mData);
    return mData;
}

#pragma mark send ota OpCode

- (void)sendOTAVersionGet {
    UInt16 tem16 = TelinkOtaOpcode_otaVersion;
    NSData *writeData = [NSData dataWithBytes:&tem16 length:2];
    [self sendOtaData:writeData];
    TelinkDebugLog(@"send OTA Version Get - > %@", writeData);
}

- (void)sendOTAStart {
    UInt16 tem16 = TelinkOtaOpcode_otaStart;
    NSData *writeData = [NSData dataWithBytes:&tem16 length:2];
    [self sendOtaData:writeData];
    TelinkDebugLog(@"send OTA Start - > %@", writeData);
}

- (void)sendOTAEndWithLastOtaIndex:(UInt16)lastOtaIndex {
    NSMutableData *writeData = [NSMutableData data];
    UInt16 tem16 = TelinkOtaOpcode_otaEnd;
    NSData *temData = [NSData dataWithBytes:&tem16 length:2];
    [writeData appendData:temData];
    tem16 = lastOtaIndex;
    temData = [NSData dataWithBytes:&tem16 length:2];
    [writeData appendData:temData];
    tem16 = ~lastOtaIndex;
    temData = [NSData dataWithBytes:&tem16 length:2];
    [writeData appendData:temData];
    [self sendOtaData:writeData];
    TelinkDebugLog(@"send OTA End - > %@", writeData);
}

- (void)sendOTAStartExtendWithOTAPacketLength:(UInt8)otaPacketLength versionCompare:(BOOL)versionCompare {
    NSMutableData *writeData = [NSMutableData data];
    UInt16 tem16 = TelinkOtaOpcode_otaStartExtend;
    NSData *temData = [NSData dataWithBytes:&tem16 length:2];
    [writeData appendData:temData];
    UInt8 tem8 = otaPacketLength;
    temData = [NSData dataWithBytes:&tem8 length:1];
    [writeData appendData:temData];
    tem8 = versionCompare ? 1 : 0;
    temData = [NSData dataWithBytes:&tem8 length:1];
    [writeData appendData:temData];
    [self sendOtaData:writeData];
    TelinkDebugLog(@"send OTA Start Extend - > %@", writeData);
}

- (void)sendOTAFirmWareVersionRequestWithFirmWareVersion:(UInt16)firmwareVersion versionCompare:(BOOL)versionCompare {
    NSMutableData *writeData = [NSMutableData data];
    UInt16 tem16 = TelinkOtaOpcode_otaFirmWareVersionRequest;
    NSData *temData = [NSData dataWithBytes:&tem16 length:2];
    [writeData appendData:temData];
    tem16 = firmwareVersion;
    temData = [NSData dataWithBytes:&tem16 length:2];
    [writeData appendData:temData];
    UInt8 tem8 = versionCompare ? 1 : 0;
    temData = [NSData dataWithBytes:&tem8 length:1];
    [writeData appendData:temData];
    [self sendOtaData:writeData];
    TelinkDebugLog(@"send OTA FirmWare Version Request - > %@", writeData);
}

- (void)sendOtaData:(NSData *)data {
    [TelinkBluetoothManager.shareCentralManager writeValue:data toPeripheral:TelinkBluetoothManager.shareCentralManager.currentPeripheral forCharacteristic:TelinkBluetoothManager.shareCentralManager.currentCharacteristic type:CBCharacteristicWriteWithoutResponse];
}
    
- (TelinkOtaOpcode)getTelinkOtaOpcodeWithPduData:(NSData *)pduData {
    TelinkOtaOpcode opcode = 0;
    if (pduData && pduData.length >= 2) {
        UInt16 tem16 = 0;
        Byte *dataByte = (Byte *)pduData.bytes;
        memcpy(&tem16, dataByte, 2);
        opcode = tem16;
    }
    return opcode;
}

extern unsigned short crc16 (unsigned char *pD, int len) {
    static unsigned short poly[2]={0, 0xa001};              //0x8005 <==> 0xa001
    unsigned short crc = 0xffff;
    int i,j;
    for(j=len; j>0; j--) {
        unsigned char ds = *pD++;
        for(i=0; i<8; i++) {
            crc = (crc >> 1) ^ poly[(crc ^ ds ) & 1];
            ds = ds >> 1;
        }
    }
    return crc;
}

@end
