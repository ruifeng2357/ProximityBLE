//
//  AppDelegate.h
//  ProximityBLE
//
//  Created by Admin on 1/12/15.
//  Copyright (c) 2015 RuiFeng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLElib.h"
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) BLElib *bleLib;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

//Helpers
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end

