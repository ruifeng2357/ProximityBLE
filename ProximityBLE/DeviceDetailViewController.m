//
//  DeviceDetailViewController.m
//  ProximityBLE
//
//  Created by Admin on 1/13/15.
//  Copyright (c) 2015 RuiFeng. All rights reserved.
//

#import "DeviceDetailViewController.h"
#import "ChangeDeviceNameViewController.h"
#import "BLElib.h"
#import "AppDelegate.h"
#import "Equipment.h"
#import "iToast.h"
#import "DBManager.h"

#define EXTERNAL_MAXIMUMVOLTAGE 12800
#define INTERNAL_MAXIMUMVOLTAGE 4200

@interface DeviceDetailViewController () <BLElibDelegate, ChangeDeviceNameDelegate, UIActionSheetDelegate>
{
    BOOL isArmed;
    char armVal;
    NSString *deviceName;
    UIActionSheet *sheetMenu;
    
    Equipment *thisEquipment;
}

@property (nonatomic, weak) BLElib *bleLib;

@property (weak, nonatomic) IBOutlet UIImageView *imageArm;
@property (weak, nonatomic) IBOutlet UIButton *buttonArm;
@property (weak, nonatomic) IBOutlet UILabel *labelInternalBattery;
@property (weak, nonatomic) IBOutlet UILabel *labelExternalBattery;
- (IBAction)onUpdate:(id)sender;
- (IBAction)onArmOrDisarm:(id)sender;

@end

@implementation DeviceDetailViewController

- (AppDelegate *)appDelegate
{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (NSMutableArray *) loadEquipments
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Equipment" inManagedObjectContext:[self appDelegate].managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[self appDelegate].managedObjectContext executeFetchRequest:request error:&error];
    
    for (int i = 0; i < fetchedObjects.count; i++) {
        Equipment *newEquip = (Equipment *)[fetchedObjects objectAtIndex:i];
        [array addObject:newEquip];
    }
    
    return array;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    isArmed = NO;
    armVal = 0;
    
    self.bleLib = [self appDelegate].bleLib;
    self.bleLib.BLEDelegate = self;
    [self.bleLib discoverServicesForConnectedPeripheral];
    
    deviceName = [[DBManager sharedDBManager] getEquipNameWithUUID:[self.bleLib.connectedPeripheral.identifier UUIDString]];
    
    UIBarButtonItem *buttonBack = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(onBack:)];
    self.navigationItem.leftBarButtonItem = buttonBack;
    self.navigationItem.title = deviceName;
}

- (void)onBack:(UIBarButtonItem *)sender
{
    if ([self.bleLib isConnectedWithPeripheral:self.bleLib.connectedPeripheral])
        [self.bleLib disconnectPeripheral:self.bleLib.connectedPeripheral];

    self.bleLib.BLEDelegate = nil;
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(IBAction)onUpdate:(id)sender
{
    if (self.bleLib.isRightDevice == NO)
    {
        NSString *message = [NSString stringWithFormat:@"This device is not a right one!"];
        [[[[iToast makeText:message] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
        
        return;
    }
    
    sheetMenu = [[UIActionSheet alloc] initWithTitle:@"Select Operation" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:nil];
    [sheetMenu addButtonWithTitle:@"Change the device name"];
    if ([[DBManager sharedDBManager] getEquipFavoriteStatusWithUUID:[self.bleLib.connectedPeripheral.identifier UUIDString]])
        [sheetMenu addButtonWithTitle:@"Remove from favorite list"];
    else
        [sheetMenu addButtonWithTitle:@"Add to favorite list"];
    /*
     * 2015-02-18 Fix me
    if ([thisEquipment.autodisarm boolValue] == YES)
        [sheetMenu addButtonWithTitle:@"Disable disarm on connect"];
    else {
        [sheetMenu addButtonWithTitle:@"Enable disarm on connect"];
    }
     */
    
    //[sheetMenu addButtonWithTitle:@"Select Auto Reconnect"];
    if ([thisEquipment.powersave boolValue] == YES)
        [sheetMenu addButtonWithTitle:@"Disable power saving mode"];
    else
        [sheetMenu addButtonWithTitle:@"Enable power saving mode"];
    
    [sheetMenu addButtonWithTitle:@"Disconnect device"];
    UIView *keyView = [[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0];
    [sheetMenu showInView:keyView];
    
    return;
}

- (IBAction)onArmOrDisarm:(id)sender {
    if (self.bleLib.isRightDevice == NO)
    {
        NSString *message = [NSString stringWithFormat:@"This device is not a right one!"];
        [[[[iToast makeText:message] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
        
        return;
    }
    
    if (isArmed == YES)
    {
        char sendData = armVal & 0xFE;
        NSData *data = [[NSData alloc] initWithBytes:&sendData length:sizeof(sendData)];
        
        BOOL bRet = [self.bleLib sendData:data];
        if (bRet) {
            isArmed = NO;
            armVal = sendData;
            [self.buttonArm setTitle:@"Arm" forState:UIControlStateNormal];
            [self.imageArm setImage:[UIImage imageNamed:@"openlock.png"]];
        }
        else {
            NSString *message = [NSString stringWithFormat:@"send failed!"];
            [[[[iToast makeText:message] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
        }
    }
    else
    {
        char sendData = armVal | 0x01;
        NSData *data = [[NSData alloc] initWithBytes:&sendData length:sizeof(sendData)];
        
        BOOL bRet = [self.bleLib sendData:data];
        if (bRet) {
            isArmed = YES;
            armVal = sendData;
            [self.buttonArm setTitle:@"Disarm" forState:UIControlStateNormal];
            [self.imageArm setImage:[UIImage imageNamed:@"closelock.png"]];
        }
        else
        {
            NSString *message = [NSString stringWithFormat:@"send failed!"];
            [[[[iToast makeText:message] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
        }
    }
    
    return;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) // Cancel
    {
        return;
    }
    else if(buttonIndex == 1) // Change the Device Name
    {
        [self performSegueWithIdentifier:@"toChangeDeviceName" sender:self];
        
        return;
    }
    else if(buttonIndex == 2) // Add Device To Favorite List
    {
        BOOL ret = NO;
        if ([[DBManager sharedDBManager] getEquipFavoriteStatusWithUUID:[self.bleLib.connectedPeripheral.identifier UUIDString]])
        {
            ret = [[DBManager sharedDBManager] updateFavoriteStatus:[self.bleLib.connectedPeripheral.identifier UUIDString] status:NO];
            if (ret == YES) {
                [[[[iToast makeText:@"removed successfully!"] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
            } else {
                [[[[iToast makeText:@"remove failed!"] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
            }
        }
        else
        {
            ret = [[DBManager sharedDBManager] updateFavoriteStatus:[self.bleLib.connectedPeripheral.identifier UUIDString] status:YES];
            if (ret == YES) {
                [[[[iToast makeText:@"added successfully!"] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
            } else {
                [[[[iToast makeText:@"add failed!"] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
            }
        }
        
        return;
    }
    /*
     * 2015-02-18 Fix me
    else if(buttonIndex == 3) // Select Disarm On Connect
    {
        char sendData;
        
        if ([thisEquipment.autodisarm boolValue] == YES)
            sendData = armVal & 0xFB;
        else
            sendData = armVal | 0x40;
        NSData *data = [[NSData alloc] initWithBytes:&sendData length:sizeof(sendData)];
        
        BOOL bRet = [self.bleLib sendData:data];
        if (bRet) {
            armVal = sendData;
            thisEquipment.autodisarm = [NSNumber numberWithBool: ![thisEquipment.autodisarm boolValue]];
            [[[[iToast makeText:@"sent successfully!"] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
        }
        else
        {
            [[[[iToast makeText:@"send failed!"] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
        }
        
        return;
    }
     */
    else if(buttonIndex == 3) // Disable Power Saving Mode
    {
        char sendData;
        
        if ([thisEquipment.powersave boolValue] == YES)
            sendData = armVal & 0xFB;
        else
            sendData = armVal | 0x04;
        NSData *data = [[NSData alloc] initWithBytes:&sendData length:sizeof(sendData)];
        
        BOOL bRet = [self.bleLib sendData:data];
        if (bRet) {
            armVal = sendData;
            thisEquipment.powersave = [NSNumber numberWithBool: ![thisEquipment.powersave boolValue]];
            [[[[iToast makeText:@"sent successfully"] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
        }
        else
            [[[[iToast makeText:@"send failed"] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
        
        return;
    }
    else if (buttonIndex == 4)
    {
        if ([self.bleLib isConnectedWithPeripheral:self.bleLib.connectedPeripheral])
            [self.bleLib disconnectPeripheral:self.bleLib.connectedPeripheral];
    
        self.bleLib.BLEDelegate = nil;
        
       [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"toChangeDeviceName"]) {
        ChangeDeviceNameViewController *controller = [segue destinationViewController];
        controller.delegate = self;
        controller.deviceName = deviceName;
    }
}

- (void) didChangedDeviceName:(NSString *)name
{
    deviceName = name;
    self.navigationItem.title = deviceName;
    
    [[DBManager sharedDBManager] updateEquipmentName:[self.bleLib.connectedPeripheral.identifier UUIDString] name:name];
}

#pragma mark - BLEDelegate
- (void) didFoundPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {}
- (void) didConnectPeripheral:(CBPeripheral *)peripheral {}
- (void) didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {}

- (void) didDisconnectPeripheral:(CBPeripheral *)peripheral
{
    [sheetMenu dismissWithClickedButtonIndex:0 animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) didReceiveData:(CBCharacteristic *)characteristic data:(NSData *)data
{    
    if (self.bleLib.isRightDevice == NO)
    {
        NSString *message = [NSString stringWithFormat:@"This device is not a right one!"];
        [[[[iToast makeText:message] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
        
        return;
    }
    
    if (self.bleLib.msgArmCharacteristic == characteristic) {
        const char *bytes = [data bytes]; // pointer to the bytes in data
        armVal = bytes[0];
        
        // Device Armed(= 1) | Disarmed (= 0)
        int value = armVal & 0x01;
        if (value == 0)
        {
            isArmed = NO;
            [self.buttonArm setTitle:@"Arm" forState:UIControlStateNormal];
            [self.imageArm setImage:[UIImage imageNamed:@"openlock.png"]];
        }
        else
        {
            isArmed = YES;
            [self.buttonArm setTitle:@"Disarm" forState:UIControlStateNormal];
            [self.imageArm setImage:[UIImage imageNamed:@"closelock.png"]];
        }
        
        /*
         * 2015-02-20 Fix me
         */
        /*
        // Auto Disarm Disable (= 0) | Enable (= 1)
        value = armVal & 0x4;
        if (value == 1)
        {
            thisEquipment.autodisarm = [NSNumber numberWithBool:YES];
        }
        else
        {
            thisEquipment.autodisarm = [NSNumber numberWithBool:NO];
        }
         */
        /*
         *
         */
        
        // Power save mode Enabled (= 1) | Disabled (= 0)
        value = armVal & 0x04;
        if (value == 1)
        {
            thisEquipment.powersave = [NSNumber numberWithBool:YES];
        }
        else
        {
            thisEquipment.powersave = [NSNumber numberWithBool:NO];
        }
    }
    else if (self.bleLib.msgPowerCharacteristic == characteristic)
    {
        const char *bytes = [data bytes]; // pointer to the bytes in data
        UInt16 nExternalVoltage = *(UInt16 *)bytes;
        UInt16 nInternalVoltage = *(UInt16 *)(bytes+2);
        
        if (nExternalVoltage >= EXTERNAL_MAXIMUMVOLTAGE)
            self.labelExternalBattery.text = @"100%";
        else
        {
            int nPercent= (nExternalVoltage * 100) / EXTERNAL_MAXIMUMVOLTAGE;
            if (nPercent == 0)
                self.labelExternalBattery.text = @"-";
            else
                self.labelExternalBattery.text = [NSString stringWithFormat:@"%d%%", nPercent];
        }
        
        if (nInternalVoltage >= INTERNAL_MAXIMUMVOLTAGE)
            self.labelInternalBattery.text = @"100%";
        else
        {
            int nPercent = (nInternalVoltage * 100) / INTERNAL_MAXIMUMVOLTAGE;
            if (nPercent == 0)
                self.labelInternalBattery.text = @"-";
            else
                self.labelInternalBattery.text = [NSString stringWithFormat:@"%d%%", nPercent];
        }
    }
}

- (void) didSendData:(NSData *)data {}
- (void) processMessage:(NSArray *)strArray sResponseType:(NSString *)sResponseType {}
- (void) didDiscoverServices {}
- (void) didDiscoverCharacteristics {}

- (BOOL) shouldDiscoverServices:(CBPeripheral *)peripheral
{
    return YES;
}

@end
