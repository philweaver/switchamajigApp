//
//  rootSwitchViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/27/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwitchControlAppDelegate.h"

@interface rootSwitchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    UIButton *chooseOneSwitchButton;
    UIButton *chooseTwoSwitchButton;
    UIButton *chooseFourAcrossButton;
    SwitchControlAppDelegate *appDelegate;
    int active_switch_index;
}
- (void) switch_names_updated:(NSNotification *) notification;
- (void) reload_switch_name_table;
- (void)disable_switch_view_buttons; 
- (void)enable_switch_view_buttons;
- (IBAction)launchOneSwitch:(id)sender;
- (IBAction)launchTwoSwitch:(id)sender;
- (IBAction)launchFourAcrossSwitch:(id)sender;
@property (nonatomic, retain) IBOutlet UIButton *chooseOneSwitchButton;
@property (nonatomic, retain) IBOutlet UIButton *chooseTwoSwitchButton;
@property (nonatomic, retain) IBOutlet UIButton *chooseFourAcrossButton;
@property (nonatomic, retain) IBOutlet UITableView *switchNameTableView;
@end
