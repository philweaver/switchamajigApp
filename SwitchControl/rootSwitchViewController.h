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
    UIScrollView *panelSelectionScrollView;
    SwitchControlAppDelegate *appDelegate;
    CFMutableDictionaryRef switchPanelURLDictionary;
    UILabel *SwitchStatusText;
    UIActivityIndicatorView *SwitchStatusActivity;
    UIButton *helpButton;
    BOOL isConfigAvailable;
}
- (void) switch_names_updated:(NSNotification *) notification;
- (void) reload_switch_name_table;
- (void) ResetScrollPanel;
- (void)initializeScrollPanelWithSwitchPanels;
- (IBAction)launchSwitchPanel:(id)sender;
@property (nonatomic, retain) IBOutlet UIButton *helpButton;
- (IBAction)display_help:(id)sender;
- (IBAction)config_pressed:(id)sender;
@property (nonatomic, retain) IBOutlet UIScrollView *panelSelectionScrollView;
@property (nonatomic, retain) IBOutlet UITableView *switchNameTableView;
@property (nonatomic, retain) IBOutlet UILabel *SwitchStatusText;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *SwitchStatusActivity;
- (IBAction)bgColorSegControlIndexChanged:(id) sender;
@property (retain, nonatomic) IBOutlet UILabel *bgColorLabel;
@property (retain, nonatomic) IBOutlet UISegmentedControl *bgColorSegControl;
@property (retain, nonatomic) IBOutlet UIButton *ConfigButton;

@end
