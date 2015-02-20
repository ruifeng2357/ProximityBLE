//
//  BLElib.m
//  BLElib
//
//  Created by RuiFeng on 13-3-27.
//  Copyright (c) 2013 RuiFeng. All rights reserved.
//

#import "BLElib.h"
#define LOG 1

#define CHARACTERISTIC_ARM      @"96378945-3148-11E4-8944-0002A5D5C51B"
#define CHARACTERISTIC_POWER    @"96378946-3148-11E4-8944-0002A5D5C51B"

#define CONNECT_TIMEOUT         20

@implementation BLElib
@synthesize centralManager;
@synthesize connectedPeripheral,connectedService,msgArmCharacteristic, msgPowerCharacteristic;
@synthesize BLEDelegate;
@synthesize txDelayCounter;

#pragma mark -
#pragma mark Init
/****************************************************************************/
/*								Init										*/
/****************************************************************************/
- (id)init
{
    self = [super init];
    if (self) {
        if(LOG)NSLog(@"Init a central!");
        self.connectedPeripheral = nil;
        self.connectedService = nil;
        self.msgArmCharacteristic = nil;
        self.msgPowerCharacteristic = nil;
        self.txDelayCounter = 0;
        centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        
        bConnecting = NO;
        connectingTimeout = 0;
        connectingPeripheral = nil;
	}
    
    return self;
}

#pragma mark -
#pragma mark Discovery
/****************************************************************************/
/*								Discovery                                   */
/****************************************************************************/
- (void) startScanningForUUIDString:(NSString *)uuidString
{
    if (centralManager.state == CBCentralManagerStatePoweredOn)
    {
        NSArray			*uuidArray	= [NSArray arrayWithObjects:[CBUUID UUIDWithString:uuidString], nil];
        NSDictionary	*options	= [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        
        //[centralManager scanForPeripheralsWithServices:uuidArray options:options];
        [centralManager scanForPeripheralsWithServices:nil options:nil];
    }
    else {
        if(LOG) {  NSLog(@"Fail to open the bluetooth\n"); }
    }
}

- (void) stopScanning
{
    if(LOG)
        NSLog(@"Stop Scan");
	[centralManager stopScan];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (peripheral.name == nil) {
        if (LOG)
            NSLog(@"peripheral.name is null");
        return;
    }

    if (LOG)
    {
        NSString *logData = [NSString stringWithFormat:@"peripheral.name is %@", peripheral.name];
        NSLog(@"%@",logData);
    }
    [BLEDelegate didFoundPeripheral:peripheral advertisementData:advertisementData RSSI:RSSI];
}

#pragma mark -
#pragma mark Connection/Disconnection
/****************************************************************************/
/*						Connection/Disconnection                            */
/****************************************************************************/
- (void) connectPeripheral:(CBPeripheral*)peripheral
{
	if (peripheral.state == CBPeripheralStateDisconnected) {
        bConnecting = YES;
        connectingTimeout  = 0;
        connectingPeripheral = peripheral;
        timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countDown:) userInfo:nil repeats:YES];
		[centralManager connectPeripheral:peripheral options:nil];
        if(LOG)NSLog(@"connectPeripheral: %@",peripheral);
	}
}

-(void) countDown:(NSTimer*)localTimer
{
    connectingTimeout++;
    if ( connectingTimeout == CONNECT_TIMEOUT )
    {
        bConnecting = NO;
        [timer invalidate];
        timer = nil;
    }
}

- (void) disconnectPeripheral:(CBPeripheral*)peripheral
{
    if (peripheral.state == CBPeripheralStateDisconnected)
        [self centralManager:centralManager didDisconnectPeripheral:peripheral error:nil];
    
    for (CBService *service in peripheral.services) {
        for (CBCharacteristic *characteristic in service.characteristics) {
            if ((characteristic.properties & CBCharacteristicPropertyNotify) != 0)
                [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        }
    }
    
	[centralManager cancelPeripheralConnection:peripheral];
    if(LOG)NSLog(@"disconnectPeripheral: %@",peripheral);
}

- (void) discoverServicesForConnectedPeripheral {
    if (connectedPeripheral == nil)
        return;
    if ([connectedPeripheral state] != CBPeripheralStateConnected)
        return;
    [connectedPeripheral discoverServices:nil];
}


- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    if(connectedPeripheral != nil) {
        connectedPeripheral = nil;
        connectedService = nil;
        msgArmCharacteristic = nil;
        msgPowerCharacteristic = nil;
    }
    
    self.isRightDevice = NO;
    
    connectedPeripheral = peripheral;
    [connectedPeripheral setDelegate:self];
    
    
    if (BLEDelegate != nil) {
        if ([BLEDelegate shouldDiscoverServices:peripheral])
            [connectedPeripheral discoverServices:nil];
        [BLEDelegate didConnectPeripheral:connectedPeripheral];
    }
    if(LOG)NSLog(@"didConnectPeripheral: %@",peripheral);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSArray *services = [peripheral services];
    NSInteger count = [services count];
    NSInteger i = 0;
    while (i < count) {
        CBUUID *uuid = [(CBService*)[services objectAtIndex:i] UUID];
        if(LOG)
            NSLog(@"didDiscoverServices: found uuid %@", [uuid UUIDString]);
        
        if ([[uuid UUIDString] isEqualToString:SERVICE_UUID] == YES) {
            
            self.isRightDevice = YES;
            
            connectedService = [services objectAtIndex:i];
            if(LOG)NSLog(@"didDiscoverServices");

			[BLEDelegate didDiscoverServices];
        }
        i++;
    }
    
    if(LOG)NSLog(@"didDiscoverServices: %@",services);
    
    if(connectedService != nil){
        [peripheral discoverCharacteristics:nil forService:connectedService];
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSArray *characters = [service characteristics];
    NSInteger count = [characters count];
    NSInteger i = 0;
    
    /*
    char data[] = QIQU_CHARACTERISTIC_TX_UUID;
    CBUUID *targetUUID = [CBUUID UUIDWithData:[NSData dataWithBytes:data length:sizeof(data)]];
     */
    CBCharacteristic *characteristic;
    
    for (characteristic in characters) {
        if(LOG)NSLog(@"didDiscoverCharacteristicsForService: %@",characteristic);
        [peripheral readValueForCharacteristic:characteristic];
        [peripheral setNotifyValue:YES forCharacteristic:characteristic];
    }
    
    msgArmCharacteristic = nil;
    msgPowerCharacteristic = nil;
    while (i < count) {
        CBUUID *uuid = [(CBService*)[characters objectAtIndex:i] UUID];
        if ([[uuid UUIDString] isEqual:CHARACTERISTIC_ARM] == YES) {
            msgArmCharacteristic = [characters objectAtIndex:i];
            if(LOG) NSLog(@"didDiscoverCharacteristicsForService: ARM uuid is %@",uuid);
			[BLEDelegate didDiscoverCharacteristics];
        }
        
        if ([[uuid UUIDString] isEqual:CHARACTERISTIC_POWER] == YES) {
            msgPowerCharacteristic = [characters objectAtIndex:i];
            if(LOG) NSLog(@"didDiscoverCharacteristicsForService: POWER uuid is %@",uuid);
            [BLEDelegate didDiscoverCharacteristics];
        }
        i++;
    }
    
}

- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if(LOG)NSLog(@"Attempted connection to peripheral %@ failed: %@", [peripheral name], [error localizedDescription]);
    if (connectingPeripheral == nil || (bConnecting == NO && connectingTimeout == 0) )
        return;
    [BLEDelegate didFailToConnectPeripheral:peripheral error:error];
}


- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if(connectedPeripheral != nil) {
        connectedPeripheral = nil;
    }
    if(LOG)NSLog(@"Disconnect with peripheral: %@",peripheral);

    [BLEDelegate didDisconnectPeripheral:peripheral];

}

- (void) clearDevices
{
    if(connectedPeripheral != nil)
    {
        connectedPeripheral = nil;
    }
}

- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    
    static CBCentralManagerState previousState = -1;
	switch ([centralManager state]) {
		case CBCentralManagerStatePoweredOff:
		{
            if(LOG)NSLog(@"CBCentralManagerStatePoweredOff");
            [self clearDevices];
			break;
		}
            
		case CBCentralManagerStateUnauthorized:
		{
			/* Tell user the app is not allowed. */
            if(LOG)NSLog(@"CBCentralManagerStateUnauthorized");
			break;
		}
            
		case CBCentralManagerStateUnknown:
		{
			/* Bad news, let's wait for another event. */
            if(LOG)NSLog(@"CBCentralManagerStateUnknown");
			break;
		}
            
		case CBCentralManagerStatePoweredOn:
		{
            if(LOG)NSLog(@"CBCentralManagerStatePoweredOn");
            //[centralManager retrieveConnectedPeripherals];
            //[centralManager scanForPeripheralsWithServices:nil options:nil];
			break;
		}
            
		case CBCentralManagerStateResetting:
		{
            if(LOG)NSLog(@"CBCentralManagerStateResetting");
			[self clearDevices];
			break;
		}
            
        case CBCentralManagerStateUnsupported:
        {
            break;
        }
	}
    
    previousState = [centralManager state];
}

#pragma mark -
#pragma mark Rcv/Snd Data
/****************************************************************************/
/*                               Rcv/Snd                                    */
/****************************************************************************/
- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^() {
        if (characteristic == nil)
            return;
        
        if(LOG)NSLog(@"didUpdateValueForCharacteristic:%@:%@", [characteristic UUID],[characteristic value]);
        
        NSData *rcvData = [characteristic value];
        if (rcvData != nil) {
            [BLEDelegate didReceiveData:characteristic data:rcvData];
        }
    });
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(LOG)NSLog(@"didUpdateNotificationStateForCharacteristic:%@:%@", characteristic,error);
}

- (BOOL)sendData:(NSData*)data
{
    if (data == nil) {
        if(LOG)NSLog(@"Sending Failed! Reason: Data was not available.");
        return NO;
    }
    if(connectedPeripheral == nil){
        if(LOG)NSLog(@"Sending Failed! Reason: Peripheral was not available.");
        return NO;
    }
    if (msgArmCharacteristic == nil) {
        if(LOG)NSLog(@"Sending Failed! Reason: Characteristic was not available.");
        return NO;
    }
    
    NSInteger len = [data length];
    NSRange range;
    range.length = 0;
    range.location = 0;
    
    while (range.location < len) {
        if (len - range.location > 20) {
            range.length = 20;
        }else{
            range.length = len - range.location;
        }
        NSData *sendData = [data subdataWithRange:range];
        [connectedPeripheral writeValue:sendData forCharacteristic:msgArmCharacteristic  type:CBCharacteristicWriteWithoutResponse];
        self.txDelayCounter ++;
        if (self.txDelayCounter >= 3) {
            usleep(20000);
            self.txDelayCounter = 0;
        }
        range.location += range.length;
    }
    
    if(LOG)NSLog(@"SendData:%@", data);
    
    return YES;
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    /* When a write occurs, need to set off a re-read of the local CBCharacteristic to update its value */
    //[peripheral readValueForCharacteristic:characteristic];
    
    dispatch_async(dispatch_get_main_queue(), ^() {
        if(LOG)NSLog(@"didWriteValueForCharacteristic:%@", [characteristic value]);
        [BLEDelegate didSendData:[characteristic value]];
    });
}

#pragma mark -
#pragma mark Utility
/****************************************************************************/
/*                               Utility                                    */
/****************************************************************************/

- (BOOL)isConnected
{
    if (connectedPeripheral == nil) {
        return NO;
    }else{
        return YES;
    }
}

- (BOOL)isConnectedWithPeripheral:(CBPeripheral*)peripheral
{
    if ([self isConnected] == NO) {
        return NO;
    }
    if ([peripheral isEqual:connectedPeripheral] == YES) {
        return YES;
    }else{
        return NO;
    }
}

- (void)enterBackground
{
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}]];
    }
}

- (void)enterForeground
{
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        [[UIApplication sharedApplication] endBackgroundTask:[self backgroundRecordingID]];
    }
    
}

- (void)pushNotificationWithMessage:(NSString *)messageString buttonTitle:(NSString *)buttonTitle inSeconds:(NSInteger)delaySeconds
{
    UILocalNotification *notification=[[UILocalNotification alloc] init];
    if (notification!=nil) {
        NSDate *now = [NSDate new];
        notification.fireDate = [now dateByAddingTimeInterval:delaySeconds];
        notification.repeatInterval = 0;
        notification.timeZone = [NSTimeZone defaultTimeZone];
        notification.applicationIconBadgeNumber = 1;//red
        notification.soundName = UILocalNotificationDefaultSoundName;
        notification.alertBody = messageString;
        notification.alertAction = buttonTitle;
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];
    }
    
}

- (void)cleanApplicationIconBadgeNumber
{
    
    [UIApplication sharedApplication].applicationIconBadgeNumber=0;
    
}
@end
