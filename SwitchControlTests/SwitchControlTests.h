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
#import "../../SwitchamajigDriver/SwitchamajigDriver/SwitchamajigDriver.h"
#import "../../SwitchamajigDriver/SwitchamajigDriver/SwitchamajigControllerDeviceDriver.h"
#import "SJUIRecordAudioViewController.h"

@interface SwitchControlTests : SenTestCase <SJUIRecordAudioViewControllerDelegate> {
    SwitchControlAppDelegate *app_delegate;
    UINavigationController *nav_controller;
    rootSwitchViewController *rootViewController;
    NSDictionary *savedDefaults;
    bool didCallSJUIRecordAudioViewControllerReadyForDismissal;
}
@end

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)
