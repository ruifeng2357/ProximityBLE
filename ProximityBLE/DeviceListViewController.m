//
//  DeviceListViewController.m
//  ProximityBLE
//
//  Created by Admin on 1/12/15.
//  Copyright (c) 2015 RuiFeng. All rights reserved.
//

#import "DeviceListViewController.h"
#import "DeviceListItemTableViewCell.h"
#import "BLElib.h"
#import "AppDelegate.h"
#import "SVProgressHUD+iEst527.h"
#import "Equipment.h"
#import "iToast.h"
#import "DBManager.h"

#define TIME_PERIOD 10

@interface DeviceListViewController () <BLElibDelegate>
{
    int timerCount;
    BOOL isscanning;
    NSTimer *timer;
    
    NSMutableArray *arraySavedEquip;
}

@property (nonatomic, weak) BLElib *bleLib;
@property (nonatomic, retain) NSMutableArray *arrayFavoriteEquip;
@property (nonatomic, retain) NSMutableArray *arrayShowEquip;
@property (nonatomic, retain) NSMutableArray *arrayFoundEquip;

@property (nonatomic, weak) IBOutlet UITableView *table;
@property (nonatomic, weak) IBOutlet UIBarItem *toolBar;

- (IBAction)onScan:(id)sender;

@end

@implementation DeviceListViewController

- (AppDelegate *) appDelegate
{
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    timerCount = 0;
    isscanning = NO;
    self.arrayFavoriteEquip = [[NSMutableArray alloc] init];
    self.arrayShowEquip = [[NSMutableArray alloc] init];
    self.arrayFoundEquip = [[NSMutableArray alloc] init];
    arraySavedEquip = [[NSMutableArray alloc] init];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self refreshPeripheralList];
    
    self.bleLib = [self appDelegate].bleLib;
    self.bleLib.BLEDelegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma TableView

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat heightCell = 44.0f;
    return heightCell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return self.arrayFavoriteEquip.count;
    }
    else if (section == 1)
        return self.arrayShowEquip.count;
    
    return 0;
}

static DeviceListItemTableViewCell *viewItem;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    viewItem = [tableView dequeueReusableCellWithIdentifier:@"DeviceRow"];
    UILabel *labelName = (UILabel *)[viewItem viewWithTag:100];
    
    if (indexPath.section == 0)
    {
        Equipment *equip = (Equipment *)[self.arrayFavoriteEquip objectAtIndex:indexPath.row];
        labelName.text = [[DBManager sharedDBManager] getEquipNameWithUUID:equip.uuid];
        
        if (![self isActiveEquipment:equip.uuid])
        {
            [viewItem setUserInteractionEnabled:NO];
            [viewItem setBackgroundColor:[UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:0.2f]];
        }
        else
        {
            [viewItem setUserInteractionEnabled:YES];
            [viewItem setBackgroundColor:[UIColor whiteColor]];
        }
    }
    else
    {
        Equipment *equip = (Equipment *)[self.arrayShowEquip objectAtIndex:indexPath.row];
        labelName.text = [[DBManager sharedDBManager] getEquipNameWithUUID:equip.uuid];
        
        if (![self isActiveEquipment:equip.uuid])
        {
            [viewItem setUserInteractionEnabled:NO];
            [viewItem setBackgroundColor:[UIColor colorWithRed:0.5f green:0.5f blue:0.5f alpha:0.2f]];
        }
        else
        {
            [viewItem setUserInteractionEnabled:YES];
            [viewItem setBackgroundColor:[UIColor whiteColor]];
        }
    }
    
    viewItem.selectionStyle = UITableViewCellStyleDefault;
    
    return viewItem;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *retView = [tableView dequeueReusableCellWithIdentifier:@"CustomHeader"];
    UILabel *lblSectionTitle = (UILabel *)[retView viewWithTag:100];
    
    switch (section)
    {
        case 0:
            [lblSectionTitle setText:@"Favorites"];
            break;
        case 1:
            [lblSectionTitle setText:@"Scanned Devices"];
            break;
        default:
            retView = nil;
    }
    
    return retView;
}

-(void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.bleLib.centralManager.state == CBCentralManagerStatePoweredOff)
    {
        [[[[iToast makeText:@"Bluetooth is currently powered off."] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
        return;
    }
    
    if (indexPath.section == 0) {
        if (indexPath.row >= self.arrayFavoriteEquip.count)
            return;
    } else {
        if (indexPath.row >= self.arrayShowEquip.count)
            return;
    }
    
    if (indexPath.section == 0)
    {
        Equipment* equip = (Equipment*)[self.arrayFavoriteEquip objectAtIndex:indexPath.row];
        
        SHOW_PROGRESS(@"Connecting...");
    
        if (self.bleLib.connectedPeripheral != nil)
        {
            if ([self.bleLib isConnectedWithPeripheral:self.bleLib.connectedPeripheral])
                [self.bleLib disconnectPeripheral:self.bleLib.connectedPeripheral];
        }
        
        CBPeripheral *peripheral = [self getPeripheral:equip.uuid];
        [self.bleLib connectPeripheral:peripheral];
    }
    else
    {
        Equipment* equip = (Equipment*)[self.arrayShowEquip objectAtIndex:indexPath.row];
        
        SHOW_PROGRESS(@"Connecting...");
        
        if (self.bleLib.connectedPeripheral != nil)
        {
            if ([self.bleLib isConnectedWithPeripheral:self.bleLib.connectedPeripheral])
                [self.bleLib disconnectPeripheral:self.bleLib.connectedPeripheral];
        }
        
        CBPeripheral *peripheral = [self getPeripheral:equip.uuid];
        [self.bleLib connectPeripheral:peripheral];
    }
    
    return;
}

- (IBAction) onScan:(id)sender
{
    if (self.bleLib.centralManager.state == CBCentralManagerStatePoweredOff)
    {
        [[[[iToast makeText:@"Bluetooth is currently powered off."] setGravity:iToastGravityBottom] setDuration:iToastDurationNormal] show];
        return;
    }
    
    if (isscanning == YES)
        return;
    
    [self.arrayFoundEquip removeAllObjects];
    [self.arrayFavoriteEquip removeAllObjects];
    [self.arrayShowEquip removeAllObjects];
    
    [self.toolBar setTitle:@"Scanning..."];
    timerCount = 0;
    isscanning = YES;
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countDown:) userInfo:nil repeats:YES];
    
    [self.bleLib startScanningForUUIDString:SERVICE_UUID];
}

-(void) countDown:(NSTimer*)localTimer
{
    timerCount++;
    if (timerCount == TIME_PERIOD)
    {
        isscanning = NO;
        [self.toolBar setTitle:@"Scan"];
        [timer invalidate];
        timer = nil;
        //[self.bleLib stopScanning];
    }
}

-(BOOL) isActiveEquipment:(NSString *)uuid
{
    BOOL isActive = NO;
    
    if (self.arrayFoundEquip != nil) {
        for (int i = 0; i < self.arrayFoundEquip.count; i++) {
            CBPeripheral *perip = (CBPeripheral *)[self.arrayFoundEquip objectAtIndex:i];
            if (perip != nil)
            {
                if ([[perip.identifier UUIDString] isEqualToString:uuid])
                {
                    isActive = YES;
                    break;
                }
            }
        }
    }
    
    return isActive;
}

- (CBPeripheral *)getPeripheral:(NSString *)uuid
{
    CBPeripheral *periph = nil;
    for (int i = 0; i < self.arrayFoundEquip.count; i++) {
        CBPeripheral* tempperiph = (CBPeripheral *)[self.arrayFoundEquip objectAtIndex:i];
        if (tempperiph != nil)
        {
            if ([[tempperiph.identifier UUIDString] isEqualToString:uuid])
            {
                periph = tempperiph;
                break;
            }
        }
    }
    
    return periph;
}

- (void) didFoundPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    if (isscanning == YES)
    {
        [[DBManager sharedDBManager] saveEquipment:peripheral];
        BOOL bFlag = NO;
        for (int i = 0; i < self.arrayFoundEquip.count; i++) {
            CBPeripheral *periph = (CBPeripheral *)[self.arrayFoundEquip objectAtIndex:i];
            if ([[periph.identifier UUIDString] isEqualToString:[peripheral.identifier UUIDString]]) {
                bFlag = YES;
                break;
            }
        }
        
        if (bFlag == NO)
            [self.arrayFoundEquip addObject:peripheral];
        [self refreshPeripheralList];
    }
}

- (void) refreshPeripheralList
{
    if (self.arrayFoundEquip == nil || self.arrayFoundEquip.count == 0)
        return;
    if (arraySavedEquip == nil)
        return;
    
    self.arrayShowEquip = [[NSMutableArray alloc] init];
    self.arrayFavoriteEquip = [[NSMutableArray alloc] init];
    arraySavedEquip = (NSMutableArray *)[[DBManager sharedDBManager] getAllEquipments];
    
    for (int i = 0; i < arraySavedEquip.count; i++) {
        Equipment* equip = (Equipment *) [arraySavedEquip objectAtIndex:i];
        if ( [[DBManager sharedDBManager] getEquipFavoriteStatusWithUUID:equip.uuid] )
            [self.arrayFavoriteEquip addObject:equip];
        else
        {
            if ([self isActiveEquipment:equip.uuid])
                [self.arrayShowEquip addObject:equip];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^() {
        [self.table reloadData];
    });
}

- (void) didConnectPeripheral:(CBPeripheral *)peripheral {
    HIDE_PROGRESS_WITH_SUCCESS(@"Connected");
    [self.bleLib stopScanning];
    dispatch_async(dispatch_get_main_queue(), ^() {
        [self performSegueWithIdentifier:@"DeviceDetail" sender:self];
    });
}

- (BOOL) shouldDiscoverServices:(CBPeripheral *)peripheral {
    return NO;
}

- (void) didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    HIDE_PROGRESS_WITH_FAILURE(@"Connecting Failed");
}

- (void) didDisconnectPeripheral:(CBPeripheral *)peripheral
{
}

- (void) didRecieveData:(NSData *)data
{
}

- (void) didSendData:(NSData *)data
{
}

- (void) didDiscoverServices
{
    
}

- (void) didDiscoverCharacteristics
{
    
}

@end