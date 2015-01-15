//
//  DeviceListItemTableViewCell.m
//  ProximityBLE
//
//  Created by Admin on 1/13/15.
//  Copyright (c) 2015 RuiFeng. All rights reserved.
//

#import "DeviceListItemTableViewCell.h"

@interface DeviceListItemTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *lblName;

@end

@implementation DeviceListItemTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
    //[self setBackgroundColor:[UIColor whiteColor]];
}

@end
