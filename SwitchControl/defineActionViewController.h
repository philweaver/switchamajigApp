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
@protocol SJUIDefineActionViewController <NSObject>
- (void) SJUIDefineActionViewControllerReadyForDismissal:(id)viewController;
@end
#import "switchPanelViewController.h"
#import "SwitchControlAppDelegate.h"



@interface defineActionViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate> {
@public
    NSMutableArray *friendlyNamesArray;
    UIPickerView *actionPicker;
    NSDictionary *actionNamesToSJActionUIDict;
    NSMutableArray *availableActions;
    UIButton *cancelButton;
    UIButton *doneButton;
}
- (id) initWithActions:(NSMutableArray *)actionsInit appDelegate:(SwitchControlAppDelegate *)appDelegate;
-(SwitchamajigDriver*) getCurrentlySelectedDriver;
@property (nonatomic, strong) NSMutableArray *actions;
@property (nonatomic, strong) SwitchControlAppDelegate *appDelegate;
@property id<SJUIDefineActionViewController>delegate;
@end
