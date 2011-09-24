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
    int active_switch_index;
    CFMutableDictionaryRef switchPanelURLDictionary;
}
- (void) switch_names_updated:(NSNotification *) notification;
- (void) reload_switch_name_table;
- (void)disable_switch_view_buttons; 
- (void)enable_switch_view_buttons;
- (IBAction)launchSwitchPanel:(id)sender;
@property (nonatomic, retain) IBOutlet UIScrollView *panelSelectionScrollView;
@property (nonatomic, retain) IBOutlet UITableView *switchNameTableView;

@end
