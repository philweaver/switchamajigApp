//
//  quickStartSettingsViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 9/14/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface quickStartSettingsViewController : UIViewController
@property (unsafe_unretained, nonatomic) IBOutlet UISwitch *supportSwitchamajigControllerSwitch;
@property (unsafe_unretained, nonatomic) IBOutlet UISwitch *supportSwitchamajigIRSwitch;
@property (unsafe_unretained, nonatomic) IBOutlet UISwitch *allowEditingSwitch;
- (IBAction)didChangeSupportSwitchamajigController:(id)sender;
- (IBAction)didChangeSupportSwitchamajigIR:(id)sender;
- (IBAction)didChangeAllowEditing:(id)sender;
- (IBAction)didSelectQuickConfigIR:(id)sender;

@end
