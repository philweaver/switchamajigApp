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
    BOOL isConfigAvailable;
    int selectButtonHeight;
    int friendlyNameDictionaryIndex;
    int numberOfPanelsInScrollView;
    int indexOfCurrentScanSelection;
}
- (void) switch_names_updated:(NSNotification *) notification;
- (void) reload_switch_name_table;
- (void) ResetScrollPanel;
- (void) initializeScrollPanelWithTextSize:(CGSize)textSize;
- (void) launchSwitchPanel:(id)sender;
- (void) display_help:(id)sender;
- (void) config_pressed:(id)sender;
- (void) statusMessageCallback;
- (void) scanPressed:(id)sender;
- (void) selectPressed:(id)sender;
- (void) highlightCurrentScanSelection:(BOOL)highlight;
@property (nonatomic, strong) UIButton *helpButton;
@property (nonatomic, strong) UIScrollView *panelSelectionScrollView;
@property (nonatomic, strong) UILabel *statusText;
@property (strong, nonatomic) UIButton *configButton;
@property (strong, nonatomic) UIButton *scanButton;
@property (strong, nonatomic) UIButton *selectButton;
@property (strong, nonatomic) UIView *highlighting;
@property (strong, nonatomic) NSMutableDictionary *switchPanelURLDictionary;
@end
