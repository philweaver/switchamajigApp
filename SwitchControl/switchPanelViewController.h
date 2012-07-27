//
//  switchPanelViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 9/9/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwitchControlAppDelegate.h"
@interface SJUIButtonWithActions : UIButton 
@property (nonatomic) NSMutableArray *activateActions;
@property (nonatomic) NSMutableArray *deactivateActions;
@end

@interface switchPanelViewController : UIViewController{
@public
    SwitchControlAppDelegate *appDelegate;
    id backButton;
    id textToShowSwitchName;
    BOOL oneButtonNavigation;
    BOOL isBuiltInPanel;
    UIButton *confirmDeleteButton;
    id currentButton;
    float lastPinchScale;
    
    // Configuration UI
    UITextField *panelNameTextField;
    UITextField *switchNameTextField;
    UIPopoverController *actionPopover;
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
- (void)onButtonSelect:(id)sender;
- (void)onSetColor:(id)sender;
- (void)onSwitchTextChange:(id)sender;
- (void)deleteSwitch:(id)sender;
- (void)newSwitch:(id)sender;
- (void)defineAction:(id)sender;

@property (nonatomic, strong) NSURL *urlToLoad;
@property (nonatomic, strong) NSString *switchPanelName;
@property BOOL editingActive;

@end
