//
//  BLElib.h
//  BLElib
//
//  Created by fankyo on 13-3-27.
//  Copyright (c) 2013年 fankyo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <UIKit/UIKit.h>

#define SERVICE_UUID @"96378944-3148-11E4-8944-0002A5D5C51B"

@protocol BLElibDelegate <NSObject>
- (void) didFoundPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI;
- (void) didConnectPeripheral:(CBPeripheral *)peripheral;
- (void) didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error;
- (void) didDisconnectPeripheral:(CBPeripheral *)peripheral;
- (void) didRecieveData:(CBCharacteristic *)characteristic data:(NSData *)data;
- (void) didSendData:(NSData *)data;
- (void) didDiscoverServices;
- (void) didDiscoverCharacteristics;
- (BOOL) shouldDiscoverServices:(CBPeripheral *)peripheral;

@end


@interface BLElib: NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>
@property (nonatomic, assign) id<BLElibDelegate> BLEDelegate;

@property (nonatomic, readwrite)        NSInteger                   txDelayCounter;
@property (nonatomic, retain, strong)   CBCentralManager            *centralManager;
@property (nonatomic, retain, strong)   CBPeripheral                *connectedPeripheral;
@property (nonatomic, retain, strong)   CBMutableCharacteristic     *msgArmCharacteristic;
@property (nonatomic, retain, strong)   CBMutableCharacteristic     *msgPowerCharacteristic;
@property (nonatomic, retain, strong)   CBService                   *connectedService;
@property (nonatomic, readwrite)        UIBackgroundTaskIdentifier  backgroundRecordingID;


//fuctions of discovery
- (void) startScanningForUUIDString:(NSString *)uuidString;
- (void) stopScanning;

//fuctions of conn & disconn
- (void) connectPeripheral:(CBPeripheral*)peripheral;
- (void) disconnectPeripheral:(CBPeripheral*)peripheral;

//functions of discover
- (void) discoverServicesForConnectedPeripheral;

//fuction of sending
- (BOOL) sendData:(NSData *)data;

//utility
- (BOOL) isConnected;
- (BOOL) isConnectedWithPeripheral:(CBPeripheral*)peripheral;
- (void) enterBackground;
- (void) enterForeground;
- (void) cleanApplicationIconBadgeNumber;
- (void) pushNotificationWithMessage:(NSString *)messageString
                         buttonTitle:(NSString *)buttonTitle
                           inSeconds:(NSInteger )delaySeconds;
@end
