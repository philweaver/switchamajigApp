//
//  configViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 1/4/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwitchControlAppDelegate.h"
#import "socket_switchamajig1_cfg.hpp"

#define MAX_AVAIL_NETWORKS 20

@interface configViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
@public
    SwitchControlAppDelegate *appDelegate;
    NSString *switchName;
    int num_avail_wifi; 
    struct switchamajig1_network_info availableNetworks[MAX_AVAIL_NETWORKS];
    BOOL nowEnteringPassphrase;
    BOOL nowConfirmingConfig;
    int networkIndex;
    NSString *networkName; // Network to be joined
}
- (void)alertView:(UIAlertView *) alertView didDismissWithButtonIndex:(NSInteger) buttonIndex;
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView;
- (IBAction)Cancel:(id)sender;
- (void) wifi_list_updated:(NSNotification *) notification;
- (void) reload_wifi_list_table;
- (void) wifi_list_complete:(NSNotification *) notification;
- (void) wifi_list_complete_main;
- (void)Background_Thread_To_Detect_Wifi;
- (IBAction)ChangeName:(id)sender;

@property (retain, nonatomic) IBOutlet UILabel *ConfigTitle;
@property (retain, nonatomic) IBOutlet UILabel *ConfigAppLabel;
@property (retain, nonatomic) IBOutlet UILabel *BackgroundColorLabel;
@property (retain, nonatomic) IBOutlet UILabel *ConfigureNetworkLabel;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *ScanActivityIndicator;
@property (retain, nonatomic) IBOutlet UITableView *wifiNameTable;
// Information for WiFi network detection
@property (retain) NSLock *wifiDataLock;
@property (nonatomic) CFMutableDictionaryRef wifiNameDictionary;
@property (nonatomic) CFMutableArrayRef wifiNameArray;
@property (retain, nonatomic) IBOutlet UIButton *CancelButton;

@end
