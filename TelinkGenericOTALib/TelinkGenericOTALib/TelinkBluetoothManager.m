/********************************************************************************************************
 * @file     TelinkBluetoothManager.m
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

#import "TelinkBluetoothManager.h"

@interface TelinkBluetoothManager () <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) NSTimer *connectTimer;
/// 扫描到蓝牙设备的回调
@property (nonatomic, copy, nullable) discoverTelinkDeviceModelCallBack discoverPeripheralBlock;
/// 连接结果的回调
@property (nonatomic, copy, nullable) peripheralResultCallBack connectResultBlock;
/// 断开连接结果的回调
@property (nonatomic, copy, nullable) peripheralResultCallBack disconnectResultBlock;
/// 扫描蓝牙设备的蓝牙服务结果的回调
@property (nonatomic, copy, nullable) peripheralResultCallBack discoverServicesResultBlock;
/// 打开notify的回调
@property (nonatomic, copy, nullable) characteristicResultCallback changeNotifyResultBlock;

@end

@implementation TelinkBluetoothManager

#pragma mark- init
+ (instancetype)shareCentralManager {
    static TelinkBluetoothManager *_centralManager = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        _centralManager = [[TelinkBluetoothManager alloc] init];
    });
    return _centralManager;
}

- (instancetype)init {
    if (self = [super init]) {
        dispatch_queue_t queue = dispatch_queue_create("com.telink.TelinkGenericBluetoothLib", 0);
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:queue];
    }
    return self;
}

- (void)connectPeripheralTimeout {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectPeripheralTimeout) object:nil];
    });
    if (self.currentPeripheral.state == CBPeripheralStateConnected) {
        return;
    }
    if (self.currentPeripheral) {
        [self.centralManager cancelPeripheralConnection:self.currentPeripheral];
    }
    if (self.connectResultBlock) {
        TelinkDebugLog(@"peripheral connect timeout.");
        NSError *error = [NSError errorWithDomain:@"peripheral connect timeout." code:-1 userInfo:nil];
        self.connectResultBlock(self.currentPeripheral,error);
    }
    self.connectResultBlock = nil;
}

- (void)connectPeripheralFail {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectPeripheralTimeout) object:nil];
    });
    if (self.connectResultBlock) {
        TelinkDebugLog(@"The Peripheral is fail to connect!");
        NSError *error = [NSError errorWithDomain:@"The Peripheral is fail to connect!" code:-1 userInfo:nil];
        self.connectResultBlock(self.currentPeripheral,error);
    }
    self.connectResultBlock = nil;
}

- (void)connectPeripheralFinish {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(connectPeripheralTimeout) object:nil];
    });
    [self stopScan];
    if (self.connectResultBlock) {
        self.connectResultBlock(self.currentPeripheral,nil);
    }
    self.connectResultBlock = nil;
}

- (void)cancelConnectPeripheralTimeout {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelConnectPeripheralTimeout) object:nil];
    });
    if (self.disconnectResultBlock && self.currentPeripheral) {
        TelinkDebugLog(@"cancelConnect peripheral fail.");
        NSError *error = [NSError errorWithDomain:@"cancelConnect peripheral fail." code:-1 userInfo:nil];
        self.disconnectResultBlock(self.currentPeripheral,error);
    }
    self.disconnectResultBlock = nil;
}

- (void)cancelConnectPeripheralFinish {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(cancelConnectPeripheralTimeout) object:nil];
    });
    if (self.disconnectResultBlock && self.currentPeripheral) {
        self.disconnectResultBlock(self.currentPeripheral, nil);
    }
    self.disconnectResultBlock = nil;
}

- (void)discoverServicesOfPeripheralTimeout {
    TelinkDebugLog(@"peripheral discoverServices timeout.");
    if (self.discoverServicesResultBlock) {
        NSError *error = [NSError errorWithDomain:@"peripheral discoverServices timeout." code:-1 userInfo:nil];
        self.discoverServicesResultBlock(self.currentPeripheral,error);
    }
    self.discoverServicesResultBlock = nil;
}

- (void)discoverServicesFinish {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(discoverServicesOfPeripheralTimeout) object:nil];
    });
    if (self.discoverServicesResultBlock) {
        self.discoverServicesResultBlock(self.currentPeripheral, nil);
    }
    self.discoverServicesResultBlock = nil;
}

- (void)openNotifyOfPeripheralTimeout {
    TelinkDebugLog(@"peripheral open notify timeout.");
    if (self.changeNotifyResultBlock) {
        NSError *error = [NSError errorWithDomain:@"peripheral open notify timeout." code:-1 userInfo:nil];
        self.changeNotifyResultBlock(self.currentPeripheral,self.currentCharacteristic,error);
    }
    //    self.bluetoothOpenNotifyCallback = nil;
}

- (void)openNotifyOfPeripheralFinish {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(openNotifyOfPeripheralTimeout) object:nil];
    });
    if (self.changeNotifyResultBlock) {
        self.changeNotifyResultBlock(self.currentPeripheral,self.currentCharacteristic,nil);
    }
    //    self.bluetoothOpenNotifyCallback = nil;
}

#pragma mark- CBCentralManagerDelegate  Method

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    TelinkDebugLog(@"[%@->%@]",NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    if (self.updateCentralStateBlock) self.updateCentralStateBlock(central.state);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI {
    TelinkDeviceModel *device = [[TelinkDeviceModel alloc] initWithPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
    if (self.discoverPeripheralBlock) {
        self.discoverPeripheralBlock(device);
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    TelinkDebugLog(@"[%@->%@]",NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    self.currentPeripheral = peripheral;
    peripheral.delegate = self;
    [self connectPeripheralFinish];
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    TelinkDebugLog(@"[%@->%@]",NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    [self cancelConnectPeripheralFinish];
    if (self.didDisconnectPeripheralResultBlock) {
        self.didDisconnectPeripheralResultBlock(peripheral, error);
    }
}
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    TelinkDebugLog(@"[%@->%@]",NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    [self connectPeripheralFail];
}
#pragma mark- CBPeripheralDelegate  Method
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    TelinkDebugLog(@"[%@->%@]",NSStringFromClass([self class]), NSStringFromSelector(_cmd));

    [peripheral discoverCharacteristics:nil forService:peripheral.services.firstObject];
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    TelinkDebugLog(@"[%@->%@]",NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    CBService *nextS = nil;
    BOOL getLastS = NO;
    for (CBService *se in peripheral.services) {
        if (getLastS) {
            nextS = se;
            break;
        }
        if ([service isEqual:se]) {
            getLastS = YES;
        }
    }
    if (nextS) {
        [peripheral discoverCharacteristics:nil forService:nextS];
    } else {
        CBCharacteristic *nextC = nil;
        for (CBService *ser in peripheral.services) {
            for (CBCharacteristic *c in ser.characteristics) {
                nextC = c;
                break;
            }
            if (nextC) {
                break;
            }
        }
        if (nextC) {
            [peripheral discoverDescriptorsForCharacteristic:nextC];
        } else {
            [self discoverServicesFinish];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    TelinkDebugLog(@"[%@->%@]",NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    CBCharacteristic *nextC = nil;
    BOOL getLastC = NO;
    for (CBService *service in peripheral.services) {
        for (CBCharacteristic *c in service.characteristics) {
            if (getLastC) {
                nextC = c;
                break;
            }
            if ([c isEqual:characteristic]) {
                getLastC = YES;
            }
        }
        if (nextC) {
            break;
        }
    }
    if (nextC) {
        [peripheral discoverDescriptorsForCharacteristic:nextC];
    } else {
        CBDescriptor *nextD = nil;
        for (CBService *se in peripheral.services) {
            for (CBCharacteristic *c in se.characteristics) {
                for (CBDescriptor *d in c.descriptors) {
                    nextD = d;
                    break;
                }
                if (nextD) {
                    break;
                }
            }
            if (nextD) {
                break;
            }
        }
        [peripheral readValueForDescriptor:nextD];
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(NSError *)error {
    TelinkDebugLog(@"[%@->%@]",NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    CBDescriptor *nextD = nil;
    BOOL getLastD = NO;
    for (CBService *se in peripheral.services) {
        for (CBCharacteristic *c in se.characteristics) {
            for (CBDescriptor *d in c.descriptors) {
                if (getLastD) {
                    nextD = d;
                    break;
                }
                if ([descriptor isEqual:d]) {
                    getLastD = YES;
                }
            }
            if (nextD) {
                break;
            }
        }
        if (nextD) {
            break;
        }
    }
    if (nextD) {
        [peripheral readValueForDescriptor:nextD];
    } else {
        [self discoverServicesFinish];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error {
    TelinkDebugLog(@"[%@->%@]",NSStringFromClass([self class]), NSStringFromSelector(_cmd));

    [self openNotifyOfPeripheralFinish];
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
//    TelinkDebugLog(@"[%@->%@]",NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    if (self.didUpdateValueForCharacteristicResultBlock) {
        self.didUpdateValueForCharacteristicResultBlock(peripheral, characteristic, error);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    TelinkDebugLog(@"[%@->%@]",NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    if (error) {
        TelinkDebugLog(@"error.localizedDescription = %@",error.localizedDescription);
    }
    if (self.didWriteValueForCharacteristicResultBlock) {
        self.didWriteValueForCharacteristicResultBlock(peripheral, characteristic, error);
    }
}

//since iOS 11.0
- (void)peripheralIsReadyToSendWriteWithoutResponse:(CBPeripheral *)peripheral {
//    TelinkDebugLog(@"[%@->%@]",NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    
    if (self.bluetoothIsReadyToSendWriteWithoutResponseBlock) {
        self.bluetoothIsReadyToSendWriteWithoutResponseBlock(peripheral);
    }
}

#pragma mark- Public

/// 开始扫描蓝牙设备接口
/// @param discoverPeripheralBlock 发现设备的回调
- (void)startScanWithDiscoverPeripheralBlock:(discoverTelinkDeviceModelCallBack)discoverPeripheralBlock {
    self.discoverPeripheralBlock = discoverPeripheralBlock;
    if (self.centralManager.state == CBCentralManagerStatePoweredOn) {
        [self.centralManager scanForPeripheralsWithServices:nil options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@(YES)}];
    }
}

/// 停止扫描接口
- (void)stopScan {
    [self.centralManager stopScan];
}

/// 连接，连接成功会内部自动调用stopScan接口。
/// @param peripheral 扫描到的系统蓝牙设备对象
/// @param timeout 连接设备的超时时间
/// @param block 连接结果回调，error为nil则连接成功，error不为nil则连接异常。
- (void)connectPeripheral:(CBPeripheral *)peripheral timeout:(NSTimeInterval)timeout resultBlock:(peripheralResultCallBack)block {
    [self connectPeripheral:peripheral options:nil timeout:timeout resultBlock:block];
}

/*!
 *  @method connectPeripheral:options:
 *
 *  @param peripheral   The <code>CBPeripheral</code> to be connected.
 *  @param options      An optional dictionary specifying connection behavior options.
 *  @param timeout 连接设备的超时时间
 *  @param block 连接结果回调，error为nil则连接成功，error不为nil则连接异常。
 *
 *  @discussion         Initiates a connection to <i>peripheral</i>. Connection attempts never time out and, depending on the outcome, will result
 *                      in a call to either {@link centralManager:didConnectPeripheral:} or {@link centralManager:didFailToConnectPeripheral:error:}.
 *                      Pending attempts are cancelled automatically upon deallocation of <i>peripheral</i>, and explicitly via {@link cancelPeripheralConnection}.
 *
 *  @see                centralManager:didConnectPeripheral:
 *  @see                centralManager:didFailToConnectPeripheral:error:
 *  @seealso            CBConnectPeripheralOptionNotifyOnConnectionKey
 *  @seealso            CBConnectPeripheralOptionNotifyOnDisconnectionKey
 *  @seealso            CBConnectPeripheralOptionNotifyOnNotificationKey
 *  @seealso            CBConnectPeripheralOptionEnableTransportBridgingKey
 *    @seealso            CBConnectPeripheralOptionRequiresANCS
 *
 */
- (void)connectPeripheral:(CBPeripheral *)peripheral options:(nullable NSDictionary<NSString *, id> *)options timeout:(NSTimeInterval)timeout resultBlock:(peripheralResultCallBack)block {
    if (self.centralManager.state != CBCentralManagerStatePoweredOn) {
        TelinkDebugLog(@"Bluetooth is not power on.");
        if (block) {
            NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"Bluetooth is not power on. centralManager.state=%ld",(long)self.centralManager.state] code:-1 userInfo:nil];
            block(peripheral,error);
        }
        return;
    }
    if (peripheral.state == CBPeripheralStateConnected) {
        if (block) {
            block(peripheral,nil);
        }
        return;
    }
    self.connectResultBlock = block;
    self.currentPeripheral = peripheral;
    TelinkDebugLog(@"call system connectPeripheral: uuid=%@",peripheral.identifier.UUIDString);
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(connectPeripheralTimeout) object:nil];
        [weakSelf performSelector:@selector(connectPeripheralTimeout) withObject:nil afterDelay:timeout];
    });
    [self.centralManager connectPeripheral:peripheral options:options];
}

/// 断开连接
/// @param peripheral 扫描到的系统蓝牙设备对象
/// @param timeout 断开连接设备的超时时间
/// @param block 断开连接结果回调，error为nil则断开连接成功，error不为nil则断开连接异常。
- (void)cancelConnectionPeripheral:(CBPeripheral *)peripheral timeout:(NSTimeInterval)timeout resultBlock:(_Nullable peripheralResultCallBack)block {
    self.disconnectResultBlock = block;
    if (peripheral && peripheral.state != CBPeripheralStateDisconnected) {
        TelinkDebugLog(@"cancel single connection");
        self.currentPeripheral = peripheral;
        self.currentPeripheral.delegate = self;
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(cancelConnectPeripheralTimeout) object:nil];
            [weakSelf performSelector:@selector(cancelConnectPeripheralTimeout) withObject:nil afterDelay:timeout];
        });
        [self.centralManager cancelPeripheralConnection:peripheral];
    }else{
        if (peripheral.state == CBPeripheralStateDisconnected) {
            if (self.disconnectResultBlock) {
                self.disconnectResultBlock(peripheral,nil);
            }
            self.disconnectResultBlock = nil;
        }
    }
    
}

/// 读取peripheral的所有蓝牙服务列表
- (void)discoverServicesOfPeripheral:(CBPeripheral *)peripheral timeout:(NSTimeInterval)timeout resultBlock:(peripheralResultCallBack)block {
    [self discoverServicesOfPeripheral:peripheral services:nil timeout:timeout resultBlock:block];
    
}

/// 读取peripheral的特定serviceUUIDs蓝牙服务列表
- (void)discoverServicesOfPeripheral:(CBPeripheral *)peripheral services:(nullable NSArray<CBUUID *> *)serviceUUIDs timeout:(NSTimeInterval)timeout resultBlock:(peripheralResultCallBack)block {
    if (self.centralManager.state != CBCentralManagerStatePoweredOn) {
        TelinkDebugLog(@"Bluetooth is not power on.");
        if (block) {
            NSError *error = [NSError errorWithDomain:@"Bluetooth is not power on." code:-1 userInfo:nil];
            block(peripheral,error);
        }
        return;
    }
    if (peripheral.state != CBPeripheralStateConnected) {
        TelinkDebugLog(@"peripheral is not connected.");
        if (block) {
            NSError *error = [NSError errorWithDomain:@"peripheral is not connected." code:-1 userInfo:nil];
            block(peripheral,error);
        }
        return;
    }
    self.discoverServicesResultBlock = block;
    self.currentPeripheral = peripheral;
    self.currentPeripheral.delegate = self;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(discoverServicesOfPeripheralTimeout) object:nil];
        [weakSelf performSelector:@selector(discoverServicesOfPeripheralTimeout) withObject:nil afterDelay:timeout];
    });
    [self.currentPeripheral discoverServices:serviceUUIDs];
    
}

/// 设置peripheral的characteristic的notify使能开关。
- (void)changeNotifyToState:(BOOL)state Peripheral:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic timeout:(NSTimeInterval)timeout resultBlock:(characteristicResultCallback)block {
    if (self.centralManager.state != CBCentralManagerStatePoweredOn) {
        TelinkDebugLog(@"Bluetooth is not power on.");
        if (block) {
            NSError *error = [NSError errorWithDomain:@"Bluetooth is not power on." code:-1 userInfo:nil];
            block(peripheral, characteristic, error);
        }
        return;
    }
    if (peripheral.state != CBPeripheralStateConnected) {
        TelinkDebugLog(@"peripheral is not connected.");
        if (block) {
            NSError *error = [NSError errorWithDomain:@"peripheral is not connected." code:-1 userInfo:nil];
            block(peripheral, characteristic, error);
        }
        return;
    }
    self.changeNotifyResultBlock = block;
    self.currentPeripheral = peripheral;
    self.currentCharacteristic = characteristic;
    self.currentPeripheral.delegate = self;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:weakSelf selector:@selector(openNotifyOfPeripheralTimeout) object:nil];
        [weakSelf performSelector:@selector(openNotifyOfPeripheralTimeout) withObject:nil afterDelay:timeout];
    });
    [peripheral setNotifyValue:state forCharacteristic:characteristic];
}

/// 写蓝牙数据
- (BOOL)writeValue:(NSData *)value toPeripheral:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type {
    if (self.centralManager.state != CBCentralManagerStatePoweredOn) {
        TelinkDebugLog(@"Bluetooth is not power on.");
        return NO;
    }
    if (peripheral.state != CBPeripheralStateConnected) {
        TelinkDebugLog(@"peripheral is not CBPeripheralStateConnected, can't write.");
        return NO;
    }
    TelinkDebugLog(@"%@--->%@",characteristic.UUID.UUIDString,value);
    self.currentPeripheral = peripheral;
    self.currentPeripheral.delegate = self;
    [self.currentPeripheral writeValue:value forCharacteristic:characteristic type:type];
    return YES;
}

- (BOOL)writeValueAvailableIOS11:(NSData *)value toPeripheral:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type completeHandle:(bleIsReadyToSendWriteWithoutResponseCallback)completeHandle {
    self.bluetoothIsReadyToSendWriteWithoutResponseBlock = completeHandle;
    return [self writeValue:value toPeripheral:peripheral forCharacteristic:characteristic type:type];
}

/// 读蓝牙数据
- (BOOL)readCharacteristicWithCharacteristic:(CBCharacteristic *)characteristic ofPeripheral:(CBPeripheral *)peripheral {
    if (self.centralManager.state != CBCentralManagerStatePoweredOn) {
        TelinkDebugLog(@"Bluetooth is not power on.");
        return NO;
    }
    if (peripheral.state != CBPeripheralStateConnected) {
        TelinkDebugLog(@"peripheral is not CBPeripheralStateConnected, can't write.");
        return NO;
    }
    
    self.currentPeripheral = peripheral;
    self.currentCharacteristic = characteristic;
    [self.currentPeripheral readValueForCharacteristic:self.currentCharacteristic];
    return YES;
}

/// 复位参数，包括停止所有计时，停止扫描，停止连接。
- (void)resetProperties {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
    });
    [self stopScan];
    [self cancelConnectionPeripheral:self.currentPeripheral timeout:10 resultBlock:nil];
    self.currentPeripheral = nil;
    self.currentCharacteristic = nil;
}

- (NSArray <CBPeripheral *>*)retrieveConnectedPeripherals {
    NSArray *uuids = @[@(GATTServiceGenericAccess),@(GATTServiceGenericAttribute),@(GATTServiceImmediateAlert),@(GATTServiceLinkLoss),@(GATTServiceTxPower),@(GATTServiceCurrentTime),@(GATTServiceReferenceTimeUpdate),@(GATTServiceNextDSTChange),@(GATTServiceGlucose),@(GATTServiceHealthThermometer),@(GATTServiceDeviceInformation),@(GATTServiceHeartRate),@(GATTServicePhoneAlertStatus),@(GATTServiceBattery),@(GATTServiceBloodPressure),@(GATTServiceAlertNotification),@(GATTServiceHumanInterfaceDevice),@(GATTServiceScanParameters),@(GATTServiceRunningSpeedAndCadence),@(GATTServiceAutomationIO),@(GATTServiceCyclingSpeedAndCadence),@(GATTServiceCyclingPower),@(GATTServiceLocationAndNavigation),@(GATTServiceEnvironmentalSensing),@(GATTServiceBodyComposition),@(GATTServiceUserData),@(GATTServiceWeightScale),@(GATTServiceBondManagement),@(GATTServiceContinuousGlucoseMonitoring),@(GATTServiceInternetProtocolSupport),@(GATTServiceIndoorPositioning),@(GATTServicePulseOximeter),@(GATTServiceHTTPProxy),@(GATTServiceTransportDiscovery),@(GATTServiceObjectTransfer),@(GATTServiceFitnessMachine),@(GATTServiceMeshProvisioning),@(GATTServiceMeshProxy),@(GATTServiceReconnectionConfiguration),@(GATTServiceInsulinDelivery),@(GATTServiceBinarySensor),@(GATTServiceEmergencyConfiguration),@(GATTServicePhysicalActivityMonitor),@(GATTServiceAudioInputControl),@(GATTServiceVolumeControl),@(GATTServiceVolumeOffsetControl),@(GATTServiceDeviceTime),@(GATTServiceConstantToneExtension),@(GATTServiceMicrophoneControl)];
    NSMutableArray *cbuuids = [NSMutableArray array];
    for (NSNumber *uuidNumber in uuids) {
        [cbuuids addObject:[CBUUID UUIDWithString:[NSString stringWithFormat:@"%X",uuidNumber.intValue]]];
    }
    NSArray *temArray = [self.centralManager retrieveConnectedPeripheralsWithServices:cbuuids];
    return temArray;
}

@end
