/*
Copyright 2014 PAW Solutions LLC

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

#import <UIKit/UIKit.h>
#import "SwitchControlAppDelegate.h"

#define MAX_AVAIL_NETWORKS 20

@interface configViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,UIPickerViewDataSource, UIPickerViewDelegate> {
@public
    SwitchControlAppDelegate *appDelegate;
    NSString *switchName;
    int num_avail_wifi; 
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
@property SwitchamajigControllerDeviceDriver *driver;
@end
