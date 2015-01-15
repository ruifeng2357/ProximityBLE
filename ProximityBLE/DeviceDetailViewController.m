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

@interface DeviceDetailViewController () <BLElibDelegate, ChangeDeviceNameDelegate, UIActionSheetDelegate>
{
    BOOL isArm;
    int armVal;
    int powerVal;
    NSString *deviceName;
    UIActionSheet *sheetMenu;
    
    Equipment *thisEquipment;
}

@property (nonatomic, weak) BLElib *bleLib;

@property (weak, nonatomic) IBOutlet UIImageView *imageArm;
@property (weak, nonatomic) IBOutlet UIButton *buttonArm;
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

-(BOOL) getFavoritesState:(NSString *)uuid
{
    BOOL isAdded = NO;
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    array = [self loadEquipments];
    
    isAdded = NO;
    for (int i = 0; i <array.count; i++) {
        thisEquipment = (Equipment *)[array objectAtIndex:i];
        if (thisEquipment != nil)
        {
            if ([thisEquipment.uuid isEqualToString:uuid])
            {
                isAdded = YES;
                break;
            }
        }
    }
    
    return isAdded;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    isArm = YES;
    armVal = 0;
    powerVal = 0;
    
    self.bleLib = [self appDelegate].bleLib;
    self.bleLib.BLEDelegate = self;
    [self.bleLib discoverServicesForConnectedPeripheral];
    
    if ([self getFavoritesState:[self.bleLib.connectedPeripheral.identifier UUIDString]])
    {
        deviceName = thisEquipment.name;
    }
    else
    {
        if (self.bleLib.connectedPeripheral != nil && self.bleLib.connectedPeripheral.name.length > 0)
            deviceName = self.bleLib.connectedPeripheral.name;
        else
            deviceName = @"No Name";
    }
    
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
    sheetMenu = [[UIActionSheet alloc] initWithTitle:@"Select Operation" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:nil];
    [sheetMenu addButtonWithTitle:@"Chanage the device name"];
    if ([self getFavoritesState:[self.bleLib.connectedPeripheral.identifier UUIDString]])
        [sheetMenu addButtonWithTitle:@"Remove from favorite list"];
    else
        [sheetMenu addButtonWithTitle:@"Add to favorite list"];
    [sheetMenu addButtonWithTitle:@"Select disarm on connect"];
    //[sheetMenu addButtonWithTitle:@"Select Auto Reconnect"];
    [sheetMenu addButtonWithTitle:@"Disable power saving mode"];
    UIView *keyView = [[[[UIApplication sharedApplication] keyWindow] subviews] objectAtIndex:0];
    [sheetMenu showInView:keyView];
    
    return;
}

- (IBAction)onArmOrDisarm:(id)sender {
    if (isArm)
    {
        char val[] = {0x0};
        NSData *data = [[NSData alloc] initWithBytes:val length:1];
        
        BOOL bRet = [self.bleLib sendData:data];
        if (bRet) {
            isArm = NO;
            [self.buttonArm setTitle:@"Disarm" forState:UIControlStateNormal];
            [self.imageArm setImage:[UIImage imageNamed:@"unlock.png"]];
        }
    }
    else
    {
        char val[] = {0x1};
        NSData *data = [[NSData alloc] initWithBytes:val length:1];
        
        BOOL bRet = [self.bleLib sendData:data];
        if (bRet) {
            isArm = YES;
            [self.buttonArm setTitle:@"Arm" forState:UIControlStateNormal];
            [self.imageArm setImage:[UIImage imageNamed:@"lock.png"]];
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
        if ([self getFavoritesState:[self.bleLib.connectedPeripheral.identifier UUIDString]])
        {
            [[self appDelegate].managedObjectContext deleteObject:thisEquipment];
            NSError* error = nil;
            if (![[self appDelegate].managedObjectContext save:&error]) {}
        }
        else
        {
            Equipment* newEquipment = [NSEntityDescription insertNewObjectForEntityForName:@"Equipment" inManagedObjectContext:[self appDelegate].managedObjectContext];
            newEquipment.uuid = [self.bleLib.connectedPeripheral.identifier UUIDString];
            newEquipment.name = deviceName;
            newEquipment.autoconnect = [NSNumber numberWithBool:NO];
            newEquipment.autodisarm = [NSNumber numberWithBool:NO];
            newEquipment.powersave = [NSNumber numberWithBool:NO];
            newEquipment.favorites = [NSNumber numberWithBool:YES];
            NSError* error = nil;
            if (![[self appDelegate].managedObjectContext save:&error]) {}
        }
        
        return;
    }
    else if(buttonIndex == 3) // Select Disarm On Connect
    {
        int nSendData = armVal & 0xFFFFFFFB;
        NSData *data = [[NSData alloc] initWithBytes:&nSendData length:sizeof(nSendData)];
        
        BOOL bRet = [self.bleLib sendData:data];
        if (bRet) {
            armVal = nSendData;
        }
        
        return;
    }
    else if(buttonIndex == 4) // Disable Power Saving Mode
    {
        int nSendData = armVal & 0xFFFFFFF7;
        NSData *data = [[NSData alloc] initWithBytes:&nSendData length:sizeof(nSendData)];
        
        BOOL bRet = [self.bleLib sendData:data];
        if (bRet) {
            armVal = nSendData;
        }
        
        return;
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
    
    if ([self getFavoritesState:[self.bleLib.connectedPeripheral.identifier UUIDString]])
    {
        if (thisEquipment != nil)
        {
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Equipment"];
            NSPredicate *predicate=[NSPredicate predicateWithFormat:@"uuid==%@", thisEquipment.uuid]; // If required to fetch specific vehicle
            fetchRequest.predicate=predicate;
            Equipment *updateEquip = [[[self appDelegate].managedObjectContext executeFetchRequest:fetchRequest error:nil] lastObject];
            
            if (updateEquip != nil)
            {
                [updateEquip setValue:deviceName forKey:@"name"];
                [[self appDelegate].managedObjectContext save:nil];
            }
        }
    }
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

- (void) didRecieveData:(CBCharacteristic *)characteristic data:(NSData *)data
{
    if (self.bleLib.msgArmCharacteristic == characteristic) {
        const char *bytes = [data bytes]; // pointer to the bytes in data
        NSInteger len = [data length];
        
        armVal = 0;
        for (int i = 0; i < len; i++) {
            armVal = armVal * 10 + (bytes[i] - 0x30);
        }
        
        // Device Arm | Disarm
        int value = armVal & 0x1;
        if (value == 0)
        {
            isArm = NO;
            [self.buttonArm setTitle:@"Arm" forState:UIControlStateNormal];
            [self.imageArm setImage:[UIImage imageNamed:@"lock.png"]];
        }
        else
        {
            isArm = YES;
            [self.buttonArm setTitle:@"Disarm" forState:UIControlStateNormal];
            [self.imageArm setImage:[UIImage imageNamed:@"unlock.png"]];
        }
        
        // Auto Disarm
        value = armVal & 0x4;
        if (value == 1)
        {
            thisEquipment.autodisarm = [NSNumber numberWithBool:YES];
        }
        else
        {
            thisEquipment.autodisarm = [NSNumber numberWithBool:NO];
        }
        
        // Power save mode
        value = armVal & 0x8;
        if (value == 1)
        {
            thisEquipment.powersave = [NSNumber numberWithBool:NO];
        }
        else
        {
            thisEquipment.powersave = [NSNumber numberWithBool:YES];
        }
    }
    else if (self.bleLib.msgPowerCharacteristic == characteristic)
    {
        ;
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
