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
#import "SJUIRecordAudioViewController.h"
#import "defineActionViewController.h"
#import "chooseIconViewController.h"
#import "SJUIExternalSwitchScanner.h"
@interface SJUIButtonWithActions : UIButton 
@property (nonatomic) NSMutableArray *activateActions;
@property (nonatomic) NSMutableArray *deactivateActions;
@property NSString *imageFilePath;
@property NSString *audioFilePath;
@property NSString *iconName;
@end

@interface switchPanelViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, SJUIRecordAudioViewControllerDelegate, SJUIDefineActionViewController, UIPopoverControllerDelegate, SJUIExternalSwitchScannerDelegate>{
@public
    SwitchControlAppDelegate *appDelegate;
    id backButton;
    UIButton *allowNavButton;
    UIButton *editButton;
    UIButton *deleteButton;
    id textToShowSwitchName;
    BOOL oneButtonNavigation;
    BOOL isBuiltInPanel;
    UIButton *confirmDeleteButton;
    SJUIButtonWithActions *currentButton;
    float lastPinchScale;
    BOOL userButtonsHidden;
    SJUIExternalSwitchScanner *switchScanner;
    id currentButtonBeingDragged;
    CGPoint currentButtonBeingDraggedLastPoint;
    
    // Configuration UI
    NSMutableArray *configurationUIElements;
    UITextField *panelNameTextField;
    UITextField *switchNameTextField;
    UIPopoverController *actionPopover;
    UIPopoverController *imagePopover;
    UIPopoverController *audioPopover;
    UIPopoverController *iconPopover;
    UIButton *chooseImageButton;
    UIButton *recordAudioButton;
    UIButton *chooseIconButton;
    BOOL settingScanOrder;
    NSMutableArray *scanOrderIndices;
    AVAudioPlayer *player;
}
- (IBAction)allowNavigation:(id)sender;
- (IBAction)disallowNavigation:(id)sender;
- (IBAction)goBack:(id)sender;
- (IBAction)onSwitchActivated:(id)sender;
- (IBAction)onSwitchDeactivated:(id)sender;
- (void)editPanel:(id)sender;
- (void)deletePanel:(id)sender;
- (void)savePanelToPath:(NSURL *)url;
// Configuration UI
- (void)onPanelNameChange:(id)sender;
- (void)onButtonDrag:(id)sender withEvent:(UIEvent *)event;
- (void)onButtonSelect:(id)sender withEvent:(UIEvent *)event;
- (void)onSetColor:(id)sender;
- (void)onSwitchTextChange:(id)sender;
- (void)deleteSwitch:(id)sender;
- (void)newSwitch:(id)sender;
- (void)defineAction:(id)sender;
- (void)chooseImage:(id)sender;
- (void)recordAudio:(id)sender;
- (void)hideUserButtons;

@property (nonatomic, strong) NSURL *urlToLoad;
@property (nonatomic, strong) NSString *switchPanelName;
@property BOOL editingActive;

@end
