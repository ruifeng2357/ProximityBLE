//
//  ChangeDeviceNameViewController.h
//  ProximityBLE
//
//  Created by Admin on 1/15/15.
//  Copyright (c) 2015 RuiFeng. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChangeDeviceNameDelegate <NSObject>
@required

- (void) didChangedDeviceName:(NSString *)deviceName;

@end

@interface ChangeDeviceNameViewController : UIViewController

@property (nonatomic, retain) NSString *deviceName;
@property (nonatomic, retain) id<ChangeDeviceNameDelegate> delegate;

@end
