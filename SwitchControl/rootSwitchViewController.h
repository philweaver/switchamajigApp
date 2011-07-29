//
//  rootSwitchViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/27/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface rootSwitchViewController : UIViewController {
    UITextField *hostname_field;
    UIButton *chooseOneSwitchButton;
    UIButton *chooseTwoSwitchButton;
    UIButton *chooseFourAcrossButton;
    int server_socket;
}
- (void)disable_switch_view_buttons; 
- (void)enable_switch_view_buttons; 
- (IBAction)launchOneSwitch:(id)sender;
- (IBAction)launchTwoSwitch:(id)sender;
- (IBAction)launchFourAcrossSwitch:(id)sender;
- (IBAction)connect:(id)sender;
@property (nonatomic, retain) IBOutlet UITextField *hostname_field;
@property (nonatomic, retain) IBOutlet UIButton *chooseOneSwitchButton;
@property (nonatomic, retain) IBOutlet UIButton *chooseTwoSwitchButton;
@property (nonatomic, retain) IBOutlet UIButton *chooseFourAcrossButton;

@end
