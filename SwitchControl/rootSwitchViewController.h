//
//  rootSwitchViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/27/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface rootSwitchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    UIButton *chooseOneSwitchButton;
    UIButton *chooseTwoSwitchButton;
    UIButton *chooseFourAcrossButton;
    UIProgressView *detectProgressBar;
    int server_socket;
    float detect_progress;
    CFMutableDictionaryRef switchNameDictionary;
    CFMutableArrayRef switchNameArray;
}
- (void)disable_switch_view_buttons; 
- (void)enable_switch_view_buttons;
- (void)detect_switches;
- (void)update_detect_progress;
- (void)reload_switch_name_table;
- (IBAction)launchOneSwitch:(id)sender;
- (IBAction)launchTwoSwitch:(id)sender;
- (IBAction)launchFourAcrossSwitch:(id)sender;
- (IBAction)detect:(id)sender;
@property (nonatomic, retain) IBOutlet UITextField *hostname_field;
@property (nonatomic, retain) IBOutlet UIButton *chooseOneSwitchButton;
@property (nonatomic, retain) IBOutlet UIButton *chooseTwoSwitchButton;
@property (nonatomic, retain) IBOutlet UIButton *chooseFourAcrossButton;
@property (nonatomic, retain) IBOutlet UIProgressView *detectProgressBar;
@property (nonatomic, retain) IBOutlet UITableView *switchNameTableView;

@end
