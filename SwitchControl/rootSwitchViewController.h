//
//  rootSwitchViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/27/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwitchControlAppDelegate.h"

@interface rootSwitchViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    SwitchControlAppDelegate *appDelegate;
    CFMutableDictionaryRef switchPanelURLDictionary;
    BOOL isConfigAvailable;
    int selectButtonHeight;
    int friendlyNameDictionaryIndex;
}
- (void) switch_names_updated:(NSNotification *) notification;
- (void) reload_switch_name_table;
- (void) ResetScrollPanel;
- (void) initializeScrollPanelWithTextSize:(CGSize)textSize;
- (void) launchSwitchPanel:(id)sender;
- (void) display_help:(id)sender;
- (void) config_pressed:(id)sender;
- (void) statusMessageCallback;
@property (nonatomic, strong) UIButton *helpButton;
@property (nonatomic, strong) UIScrollView *panelSelectionScrollView;
@property (nonatomic, strong) UILabel *statusText;
@property (strong, nonatomic) UIButton *configButton;
@end
