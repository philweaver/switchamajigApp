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

@interface quickStartSettingsViewController : UIViewController
@property (unsafe_unretained, nonatomic) IBOutlet UISwitch *supportSwitchamajigControllerSwitch;
@property (unsafe_unretained, nonatomic) IBOutlet UISwitch *supportSwitchamajigIRSwitch;
@property (unsafe_unretained, nonatomic) IBOutlet UISwitch *allowEditingSwitch;
@property SwitchControlAppDelegate *appDelegate;
- (IBAction)didChangeSupportSwitchamajigController:(id)sender;
- (IBAction)didChangeSupportSwitchamajigIR:(id)sender;
- (IBAction)didChangeAllowEditing:(id)sender;
- (IBAction)didSelectQuickConfigIR:(id)sender;
- (IBAction)didSelectQuickConfigDVD:(id)sender;
- (IBAction)didSelectQuickConfigCable:(id)sender;

@end
