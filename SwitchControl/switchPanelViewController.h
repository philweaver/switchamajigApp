//
//  switchPanelViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 9/9/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwitchControlAppDelegate.h"
@interface switchPanelViewController : UIViewController{
@public
    SwitchControlAppDelegate *appDelegate;
    id backButton;
    id allowNavButton;
    id myButton; // last button initialized
    id textToShowSwitchName;
}
- (IBAction)allowNavigation:(id)sender;
- (IBAction)disallowNavigation:(id)sender;
- (IBAction)goBack:(id)sender;
- (IBAction)onSwitchActivated:(id)sender;
- (IBAction)onSwitchDeactivated:(id)sender;
- (void)updateSwitchNameText;
@property (nonatomic, strong) NSURL *urlToLoad;
@property (nonatomic, strong) NSString *switchPanelName;
@property (nonatomic, strong) NSMutableDictionary *buttonToSwitchDictionary;

@end
