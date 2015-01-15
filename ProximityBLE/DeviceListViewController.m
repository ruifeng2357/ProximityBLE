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

#define TIME_PERIOD 3

@interface DeviceListViewController () <BLElibDelegate>
{
    int timerCount;
    BOOL isscanning;
    NSTimer *timer;
    
    NSMutableArray *arraySavedEquip;
}

@property (nonatomic, weak) BLElib *bleLib;
@property (nonatomic, retain) NSMutableArray *arrayFoundedEquip;
@property (nonatomic, retain) NSMutableArray *arrayShowEquip;

@property (nonatomic, weak) IBOutlet UITableView *table;
@property (nonatomic, weak) IBOutlet UIBarItem *toolBar;

- (IBAction)onScan:(id)sender;

@end

@implementation DeviceListViewController

- (AppDelegate *) appDelegate
{
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (void) loadEquipments
{
    if (arraySavedEquip)
        arraySavedEquip = nil;
    
    arraySavedEquip = [[NSMutableArray alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Equipment" inManagedObjectContext:[self appDelegate].managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [[self appDelegate].managedObjectContext executeFetchRequest:request error:&error];
    
    for (int i = 0; i < fetchedObjects.count; i++) {
        Equipment *newEquip = (Equipment *)[fetchedObjects objectAtIndex:i];
        [arraySavedEquip addObject:newEquip];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.bleLib = [self appDelegate].bleLib;
    self.bleLib.BLEDelegate = self;
    
    [self loadEquipments];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    timerCount = 0;
    isscanning = NO;
    [self loadEquipments];
    self.arrayFoundedEquip = [[NSMutableArray alloc] init];
    self.arrayShowEquip = [[NSMutableArray alloc] init];
    self.bleLib.BLEDelegate = self;
    
    [self.table reloadData];
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
        return arraySavedEquip.count;
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
        Equipment *equip = (Equipment *)[arraySavedEquip objectAtIndex:indexPath.row];
        if (equip != nil && equip.name.length > 0)
            labelName.text = equip.name;
        else
            labelName.text = @"No Name";
        
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
        CBPeripheral *peripheral = [self.arrayShowEquip objectAtIndex:indexPath.row];
        if (peripheral != nil && peripheral.name.length > 0)
            labelName.text = peripheral.name;
        else
            labelName.text = @"No Name";
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
    if (indexPath.row >= self.arrayShowEquip.count)
        return;
    
    if (indexPath.section == 0)
    {
        Equipment* equip = (Equipment*)[arraySavedEquip objectAtIndex:indexPath.row];
        
        SHOW_PROGRESS(@"Connecting...");
        
        CBPeripheral *peripheral = [self getPeripheral:equip.uuid];
        [self.bleLib connectPeripheral:peripheral];
    }
    else
    {
        SHOW_PROGRESS(@"Connecting...");
        
        CBPeripheral *peripheral = [self.arrayShowEquip objectAtIndex:indexPath.row];
        [self.bleLib connectPeripheral:peripheral];
    }
    
    return;
}

- (IBAction) onScan:(id)sender
{
    if (isscanning == YES)
        return;
    
    [self.arrayFoundedEquip removeAllObjects];
    [self.arrayShowEquip removeAllObjects];
    
    [self.toolBar setTitle:@"Scanning..."];
    timerCount = 0;
    isscanning = YES;
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(countDown:) userInfo:nil repeats:YES];
    
    [self.bleLib startScanningForUUIDString:@""];
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
    
    if (self.arrayFoundedEquip != nil) {
        for (int i = 0; i < self.arrayFoundedEquip.count; i++) {
            CBPeripheral *perip = (CBPeripheral *)[self.arrayFoundedEquip objectAtIndex:i];
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
    for (int i = 0; i < self.arrayFoundedEquip.count; i++) {
        CBPeripheral* tempperiph = (CBPeripheral *)[self.arrayFoundedEquip objectAtIndex:i];
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
        if (![self.arrayFoundedEquip containsObject:peripheral]) {
            BOOL isExist = NO;
            if (arraySavedEquip != nil)
            {
                for (int i = 0; i < arraySavedEquip.count; i++) {
                    Equipment* equip = (Equipment *) [arraySavedEquip objectAtIndex:i];
                    if ( equip != nil )
                    {
                        if ([equip.uuid isEqualToString:[peripheral.identifier UUIDString]])
                        {
                            isExist = YES;
                            break;
                        }
                    }
                }
            }
            
            if (isExist == NO)
                [self.arrayShowEquip addObject:peripheral];
            
            [self.arrayFoundedEquip addObject:peripheral];
            
            dispatch_async(dispatch_get_main_queue(), ^() {
                [self.table reloadData];
            });
        }
    }
}

- (void) didConnectPeripheral:(CBPeripheral *)peripheral {
    HIDE_PROGRESS_WITH_SUCCESS(@"Connected");
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