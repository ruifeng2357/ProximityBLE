//
//  Equipment.h
//  ProximityBLE
//
//  Created by Admin on 1/14/15.
//  Copyright (c) 2015 RuiFeng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Equipment : NSManagedObject

@property (nonatomic, retain) NSString * uuid;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * autoconnect;
@property (nonatomic, retain) NSNumber * autodisarm;
@property (nonatomic, retain) NSNumber * powersave;
@property (nonatomic, retain) NSNumber * favorites;

@end
