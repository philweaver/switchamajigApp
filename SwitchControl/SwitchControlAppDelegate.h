//
//  SwitchControlAppDelegate.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/23/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "sys/socket.h"
#import "netinet/in.h"
#import "netdb.h"
#import "sys/unistd.h"
#import "sys/fcntl.h"
#import "sys/poll.h"
#import "arpa/inet.h"
#import "errno.h"

@class singleSwitchView;
@class twoSwitchView;
@class rootSwitchViewController;

@interface SwitchControlAppDelegate : NSObject <UIApplicationDelegate> {
    int switch_state;
    struct sockaddr_in udp_socket_address;
}
- (void)Background_Thread_To_Detect_Switches;
- (void)activate:(NSObject *)switches;
- (void)deactivate:(NSObject *)switches;
- (void)connect_to_switch:(int)switchIndex protocol:(int)protocol retries:(int)retries showMessagesOnError:(BOOL)showMessagesOnError;
- (void)SequenceThroughSwitches:(id)switchSequence;
- (void)sendSwitchState;
- (void)display_battery_warning:(NSString *)text;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (retain) NSLock *switchDataLock;
@property (retain) NSLock *switchStateLock;
@property (nonatomic) CFMutableDictionaryRef switchNameDictionary;
@property (nonatomic) CFMutableArrayRef switchNameArray;
@property (nonatomic) int active_switch_index;
@property (nonatomic) int switch_socket;
@property (nonatomic) int settings_switch_connection_protocol;
@property (nonatomic) int current_switch_connection_protocol;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIColor *foregroundColor;



@end
