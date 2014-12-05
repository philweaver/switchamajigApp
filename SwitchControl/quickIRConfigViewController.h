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

@interface quickIRConfigViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate> {
@public
    NSMutableArray *brands;
    NSArray *codeSets;
}
@property (unsafe_unretained, nonatomic) IBOutlet UIPickerView *codeSetPickerView;
@property (unsafe_unretained, nonatomic) IBOutlet UIPickerView *brandPickerView;
@property NSString *deviceGroup; // device types separated with '/'
@property NSURL *urlForControlPanel;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *filterBrandButton;
@property SwitchControlAppDelegate *appDelegate;
- (IBAction)filterBrandToggle:(id)sender;
@end
