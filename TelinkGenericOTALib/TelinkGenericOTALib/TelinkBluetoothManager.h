/********************************************************************************************************
 * @file     TelinkBluetoothManager.h
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

#define BLE ([TelinkBluetoothManager shareCentralManager])

typedef void(^discoverTelinkDeviceModelCallBack)(TelinkDeviceModel *deviceModel);
typedef void(^peripheralResultCallBack)(CBPeripheral *peripheral,NSError * _Nullable error);
typedef void(^characteristicResultCallback)(CBPeripheral *peripheral,CBCharacteristic *characteristic,NSError * _Nullable error);
typedef void(^bleIsReadyToSendWriteWithoutResponseCallback)(CBPeripheral *peripheral);

/// GATT Service UUID
/// - seeAlso: 16-bit UUID Numbers Document.pdf  (page.19)
typedef enum : UInt16 {
    GATTServiceGenericAccess = 0x1800,
    GATTServiceGenericAttribute = 0x1801,
    GATTServiceImmediateAlert = 0x1802,
    GATTServiceLinkLoss = 0x1803,
    GATTServiceTxPower = 0x1804,
    GATTServiceCurrentTime = 0x1805,
    GATTServiceReferenceTimeUpdate = 0x1806,
    GATTServiceNextDSTChange = 0x1807,
    GATTServiceGlucose = 0x1808,
    GATTServiceHealthThermometer = 0x1809,
    GATTServiceDeviceInformation = 0x180A,
    GATTServiceHeartRate = 0x180D,
    GATTServicePhoneAlertStatus = 0x180E,
    GATTServiceBattery = 0x180F,
    GATTServiceBloodPressure = 0x1810,
    GATTServiceAlertNotification = 0x1811,
    GATTServiceHumanInterfaceDevice = 0x1812,
    GATTServiceScanParameters = 0x1813,
    GATTServiceRunningSpeedAndCadence = 0x1814,
    GATTServiceAutomationIO = 0x1815,
    GATTServiceCyclingSpeedAndCadence = 0x1816,
    GATTServiceCyclingPower = 0x1818,
    GATTServiceLocationAndNavigation = 0x1819,
    GATTServiceEnvironmentalSensing = 0x181A,
    GATTServiceBodyComposition = 0x181B,
    GATTServiceUserData = 0x181C,
    GATTServiceWeightScale = 0x181D,
    GATTServiceBondManagement = 0x181E,
    GATTServiceContinuousGlucoseMonitoring = 0x181F,
    GATTServiceInternetProtocolSupport = 0x1820,
    GATTServiceIndoorPositioning = 0x1821,
    GATTServicePulseOximeter = 0x1822,
    GATTServiceHTTPProxy = 0x1823,
    GATTServiceTransportDiscovery = 0x1824,
    GATTServiceObjectTransfer = 0x1825,
    GATTServiceFitnessMachine = 0x1826,
    GATTServiceMeshProvisioning = 0x1827,
    GATTServiceMeshProxy = 0x1828,
    GATTServiceReconnectionConfiguration = 0x1829,
    GATTServiceInsulinDelivery = 0x183A,
    GATTServiceBinarySensor = 0x183B,
    GATTServiceEmergencyConfiguration = 0x183C,
    GATTServicePhysicalActivityMonitor = 0x183E,
    GATTServiceAudioInputControl = 0x1843,
    GATTServiceVolumeControl = 0x1844,
    GATTServiceVolumeOffsetControl = 0x1845,
    GATTServiceDeviceTime = 0x1847,
    GATTServiceConstantToneExtension = 0x184A,
    GATTServiceMicrophoneControl = 0x184D,
} GATTService;


@interface TelinkBluetoothManager : NSObject

@property (nonatomic, strong) CBCentralManager *centralManager;

@property (strong, nonatomic, nullable) CBPeripheral *currentPeripheral;

@property (strong, nonatomic, nullable) CBCharacteristic *currentCharacteristic;

/// 手机蓝牙状态改变的回调
@property (copy, nonatomic) void(^ _Nullable updateCentralStateBlock)(CBManagerState state);
/// 设备端上报的notify回调
@property (nonatomic, copy, nullable) characteristicResultCallback didUpdateValueForCharacteristicResultBlock;
/// writeWithResponse特征的回调
@property (nonatomic, copy, nullable) characteristicResultCallback didWriteValueForCharacteristicResultBlock;
/// 连接断开的回调
@property (nonatomic, copy, nullable) peripheralResultCallBack didDisconnectPeripheralResultBlock;
/// iOS 11以上系统支持，回调可以发送下一个WriteWithoutResponse数据包
@property (nonatomic,copy, nullable) bleIsReadyToSendWriteWithoutResponseCallback bluetoothIsReadyToSendWriteWithoutResponseBlock;

+ (instancetype)shareCentralManager;

/// 开始扫描蓝牙设备接口
/// @param discoverPeripheralBlock 发现设备的回调
- (void)startScanWithDiscoverPeripheralBlock:(discoverTelinkDeviceModelCallBack)discoverPeripheralBlock;

/// 停止扫描接口
- (void)stopScan;

/// 连接，连接成功会内部自动调用stopScan接口。
/// @param peripheral 扫描到的系统蓝牙设备对象
/// @param timeout 连接设备的超时时间
/// @param block 连接结果回调，error为nil则连接成功，error不为nil则连接异常。
- (void)connectPeripheral:(CBPeripheral *)peripheral timeout:(NSTimeInterval)timeout resultBlock:(peripheralResultCallBack)block;

/// 断开连接
/// @param peripheral 扫描到的系统蓝牙设备对象
/// @param timeout 断开连接设备的超时时间
/// @param block 断开连接结果回调，error为nil则断开连接成功，error不为nil则断开连接异常。
- (void)cancelConnectionPeripheral:(CBPeripheral *)peripheral timeout:(NSTimeInterval)timeout resultBlock:(_Nullable peripheralResultCallBack)block;

/// 读取peripheral的所有蓝牙服务列表
- (void)discoverServicesOfPeripheral:(CBPeripheral *)peripheral timeout:(NSTimeInterval)timeout resultBlock:(peripheralResultCallBack)block;

/// 设置peripheral的characteristic的notify使能开关。
- (void)changeNotifyToState:(BOOL)state Peripheral:(CBPeripheral *)peripheral characteristic:(CBCharacteristic *)characteristic timeout:(NSTimeInterval)timeout resultBlock:(characteristicResultCallback)block;

/// 写蓝牙数据
- (BOOL)writeValue:(NSData *)value toPeripheral:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type;
- (BOOL)writeValueAvailableIOS11:(NSData *)value toPeripheral:(CBPeripheral *)peripheral forCharacteristic:(CBCharacteristic *)characteristic type:(CBCharacteristicWriteType)type completeHandle:(bleIsReadyToSendWriteWithoutResponseCallback)completeHandle;

/// 读蓝牙数据
- (BOOL)readCharacteristicWithCharacteristic:(CBCharacteristic *)characteristic ofPeripheral:(CBPeripheral *)peripheral;

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
- (void)connectPeripheral:(CBPeripheral *)peripheral options:(nullable NSDictionary<NSString *, id> *)options timeout:(NSTimeInterval)timeout resultBlock:(peripheralResultCallBack)block;

/// 读取peripheral的特定serviceUUIDs蓝牙服务列表
- (void)discoverServicesOfPeripheral:(CBPeripheral *)peripheral services:(nullable NSArray<CBUUID *> *)serviceUUIDs timeout:(NSTimeInterval)timeout resultBlock:(peripheralResultCallBack)block;

/// 复位参数，包括停止所有计时，停止扫描，停止连接。
- (void)resetProperties;

- (NSArray <CBPeripheral *>*)retrieveConnectedPeripherals;

@end

NS_ASSUME_NONNULL_END
