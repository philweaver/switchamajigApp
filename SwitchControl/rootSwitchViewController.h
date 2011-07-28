//
//  rootSwitchViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/27/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface rootSwitchViewController : UIViewController
@property (nonatomic, readwrite) int server_socket;

- (IBAction)launchOneSwitch:(id)sender;
- (IBAction)launchTwoSwitch:(id)sender;

@end
