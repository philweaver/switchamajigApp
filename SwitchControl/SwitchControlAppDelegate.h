//
//  SwitchControlAppDelegate.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/23/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
@class singleSwitchView;
@class twoSwitchView;

@interface SwitchControlAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) singleSwitchView *singleSwitchViewController;
@property (nonatomic, retain) twoSwitchView *twoSwitchViewController;

@end
