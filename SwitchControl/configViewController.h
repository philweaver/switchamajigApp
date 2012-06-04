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

@interface configViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,UIPickerViewDataSource, UIPickerViewDelegate> {
@public
    SwitchControlAppDelegate *appDelegate;
    NSString *switchName;
    int num_avail_wifi; 
    struct switchamajig1_network_info availableNetworks[MAX_AVAIL_NETWORKS];
    BOOL nowEnteringPassphrase;
    BOOL nowConfirmingConfig;
}
- (void)alertView:(UIAlertView *) alertView didDismissWithButtonIndex:(NSInteger) buttonIndex;
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView;
- (IBAction)Cancel:(id)sender;
- (void) wifi_list_updated:(NSNotification *) notification;
- (void) reload_wifi_list_table;
- (void)Background_Thread_To_Detect_Wifi;
- (IBAction)ChangeName:(id)sender;
- (IBAction)ChangeNetwork:(id)sender;
- (IBAction)NetworkNameChanged:(id)sender;
- (IBAction)ScanForNetworks:(id)sender;
- (void)EnableUIAfterScan;
- (void)ShowScanAlert:(id)alertMessage;
// Picker support
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView;
- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component;
- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;

@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *ScanActivityIndicator;
@property (retain, nonatomic) IBOutlet UITableView *wifiNameTable;
// Information for WiFi network detection
@property (retain) NSLock *wifiDataLock;
@property (nonatomic) NSMutableDictionary *wifiNameDictionary;
@property (nonatomic) NSMutableArray *wifiNameArray;
@property (retain, nonatomic) IBOutlet UIButton *CancelButton;
@property (retain, nonatomic) IBOutlet UIPickerView *datePicker;
@property (retain, nonatomic) IBOutlet UITextField *SwitchamajigNameText;
@property (retain, nonatomic) IBOutlet UITextField *NetworkNameText;
@property (retain, nonatomic) IBOutlet UIButton *ConfigureNetworkButton;
@property (retain, nonatomic) IBOutlet UIButton *ScanNetworkButton;

@end
