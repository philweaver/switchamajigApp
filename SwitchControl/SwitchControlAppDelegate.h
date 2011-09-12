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
@class rootSwitchViewController;

@interface SwitchControlAppDelegate : NSObject <UIApplicationDelegate> {
    int switch_state;
}
- (void)Background_Thread_To_Detect_Switches;
- (void)activate:(int)switchMask;
- (void)deactivate:(int)switchMask;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (retain) NSLock *switchDataLock;
@property (nonatomic) CFMutableDictionaryRef switchNameDictionary;
@property (nonatomic) CFMutableArrayRef switchNameArray;
@property (nonatomic) int switch_socket;
@end
