//
//  DBManager.h
//  ProximityBLE
//
//  Created by Admin on 2/10/15.
//  Copyright (c) 2015 RuiFeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLElib.h"
#import "Equipment.h"

@interface DBManager : NSObject {
}

+ (DBManager*) sharedDBManager;
- (BOOL) isSavedEquipment:(NSString *) uuid;
- (BOOL) saveEquipment:(CBPeripheral *) peripheral;
- (BOOL) updateEquipmentName:(NSString *) uuid name:(NSString *) name;
- (BOOL) updateFavoriteStatus:(NSString *) uuid status:(BOOL) status;
- (NSMutableArray *) getAllEquipments;
- (Equipment *) getEquipmentWithUUID:(NSString *) uuid;
- (NSString *) getEquipNameWithUUID:(NSString *) uuid;
- (BOOL) getEquipFavoriteStatusWithUUID:(NSString *) uuid;

@end
