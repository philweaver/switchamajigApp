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
#import "configViewController.h"
@interface SwitchControlTests : SenTestCase {
    SwitchControlAppDelegate *app_delegate;
    UINavigationController *nav_controller;
    rootSwitchViewController *rootViewController;
}
@end

@interface MockNavigationController : UINavigationController {
    @public
    UIViewController *lastViewController;
    BOOL didReceivePushViewController;
    BOOL didReceivePopViewController;
}
@end

@interface MockSwitchControlDelegate : SwitchControlAppDelegate {
@public
    NSMutableArray *commandsReceived;
}

@end
