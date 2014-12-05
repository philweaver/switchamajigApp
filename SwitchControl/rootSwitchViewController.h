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
#import "SJUIStatusMessageLabel.h"
#import "SJUIExternalSwitchScanner.h"
@interface rootSwitchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, SJUIExternalSwitchScannerDelegate> {
    SwitchControlAppDelegate *appDelegate;
    BOOL isConfigAvailable;
    int panelButtonWidth;
    int panelButtonHeight;
    int numberOfPanelsInScrollView;
    SJUIExternalSwitchScanner *switchScanner;
}
- (void) ResetScrollPanel;
- (void) initializeScrollPanelWithTextSize:(CGSize)textSize;
- (void) launchSwitchPanel:(id)sender;
- (void) display_help:(id)sender;
- (void) config_pressed:(id)sender;
- (void) viewDidAppear:(BOOL)animated;
@property (nonatomic, strong) UIButton *helpButton;
@property (nonatomic, strong) UIButton *showQuickstartWizardButton;
@property (nonatomic, strong) UIScrollView *panelSelectionScrollView;
@property (nonatomic, strong) SJUIStatusMessageLabel *statusText;
@property (strong, nonatomic) UIButton *configButton;
@property (strong, nonatomic) UIButton *scanButton;
@property (strong, nonatomic) UIButton *selectButton;
@property (strong, nonatomic) NSMutableDictionary *switchPanelURLDictionary;
@end
