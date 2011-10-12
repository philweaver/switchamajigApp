//
//  SwitchControlTests.h
//  SwitchControlTests
//
//  Created by Phil Weaver on 7/23/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "SwitchControlAppDelegate.h"
#import "rootSwitchViewController.h"
#import "switchPanelViewController.h"
@interface SwitchControlTests : SenTestCase {
    SwitchControlAppDelegate *app_delegate;
    UINavigationController *nav_controller;
    rootSwitchViewController *rootViewController;
}

@end
