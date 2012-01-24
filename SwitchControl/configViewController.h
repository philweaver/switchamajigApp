//
//  configViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 1/4/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwitchControlAppDelegate.h"

@interface configViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
@public
    SwitchControlAppDelegate *appDelegate;
    NSString *switchName;
}
- (void)alertView:(UIAlertView *) alertView didDismissWithButtonIndex:(NSInteger) buttonIndex;
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView;
- (IBAction)Cancel:(id)sender;
- (void) wifi_list_updated:(NSNotification *) notification;
- (void) reload_wifi_list_table;
- (void) wifi_list_complete:(NSNotification *) notification;
- (void) wifi_list_complete_main;
@property (retain, nonatomic) IBOutlet UILabel *ConfigTitle;
@property (retain, nonatomic) IBOutlet UILabel *ConfigAppLabel;
@property (retain, nonatomic) IBOutlet UILabel *BackgroundColorLabel;
@property (retain, nonatomic) IBOutlet UILabel *ConfigureNetworkLabel;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *ScanActivityIndicator;
@property (retain, nonatomic) IBOutlet UITableView *wifiNameTable;
@end
