//
//  switchPanelViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 9/9/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwitchControlAppDelegate.h"
@interface switchPanelViewController : UIViewController {
    SwitchControlAppDelegate *appDelegate;

}
@property (nonatomic) CFMutableDictionaryRef buttonToSwitchDictionary;

- (IBAction)onSwitchActivated:(id)sender;
- (IBAction)onSwitchDeactivated:(id)sender;
@end
