//
//  ChangeDeviceNameViewController.m
//  ProximityBLE
//
//  Created by Admin on 1/15/15.
//  Copyright (c) 2015 RuiFeng. All rights reserved.
//

#import "ChangeDeviceNameViewController.h"

@interface ChangeDeviceNameViewController ()<UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textDeviceName;
@end

@implementation ChangeDeviceNameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIBarButtonItem *buttonBack = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(onBack:)];
    self.navigationItem.leftBarButtonItem = buttonBack;
}

- (void) onBack:(UIBarButtonItem *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.textDeviceName setText:self.deviceName];
    [self.textDeviceName becomeFirstResponder];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)onChangeID:(id)sender {
    
    if (self.delegate) {
        [self.delegate didChangedDeviceName:self.textDeviceName.text];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self onChangeID:nil];
    return YES;
}

@end
