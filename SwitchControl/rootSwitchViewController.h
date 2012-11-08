//
//  rootSwitchViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/27/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

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
