//
//  SwitchControlAppDelegate.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/23/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../../SwitchamajigDriver/SwitchamajigDriver/SwitchamajigDriver.h"

@class rootSwitchViewController;
#define PROTOCOL_SQ (IPPROTO_TCP + IPPROTO_UDP + 1)
#define ROVING_PORTNUM 2000
#define SQ_PORTNUM 80
@interface SwitchControlAppDelegate : NSObject <UIApplicationDelegate, SwitchamajigDeviceListenerDelegate, SwitchamajigIRDeviceDriverDelegate> {
    SwitchamajigControllerDeviceListener *sjigControllerListener;
    SwitchamajigIRDeviceListener *sjigIRListener;
    int friendlyNameDictionaryIndex;
    NSTimer *statusMessageTimer;
    int listenerDevicesToIgnore;
    NSLock *switchamajigIRLock;
    NSString *lastLearnedIRCommand;
    NSError *lastLearnedIRError;
}
- (void)performActionSequence:(DDXMLNode *)actionSequenceOnDevice;
- (void) addStatusAlertMessage:(NSString *)message withColor:(UIColor*)color displayForSeconds:(float)seconds;
- (void) statusMessageCallback;
- (void) executeActionSequence:(NSArray *)threadInfoArray;
- (SwitchamajigControllerDeviceDriver *) firstSwitchamajigControllerDriver;
- (void)removeDriver:(SwitchamajigDriver *)driver;
- (NSString *) getLastLearnedIRCommand;
- (NSError *) getLastLearnedIRError;
- (void) clearLastLearnedIRInfo;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (strong, nonatomic) NSMutableDictionary *friendlyNameSwitchamajigDictionary;
@property (strong, nonatomic) NSMutableDictionary *actionnameActionthreadDictionary;
@property (strong, nonatomic) NSLock *statusInfoLock;
@property (strong, nonatomic) NSMutableArray *statusMessages;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIColor *foregroundColor;

// Settings default handling
- (NSDictionary *)defaultsFromPlistNamed:(NSString *)plistName;

@end
