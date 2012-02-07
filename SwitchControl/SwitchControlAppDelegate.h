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
#import "socket_switchamajig1_cfg.hpp"

#define switch_control_protocol_normal IPPROTO_UDP


@class singleSwitchView;
@class twoSwitchView;
@class rootSwitchViewController;
#define MAX_AVAIL_NETWORKS 20

@interface SwitchControlAppDelegate : NSObject <UIApplicationDelegate> {
    int switch_state;
    struct sockaddr_in udp_socket_address;
    int num_avail_wifi; 
    struct switchamajig1_network_info availableNetworks[MAX_AVAIL_NETWORKS];
    int switch_connection_protocol;
}
- (void)Background_Thread_To_Detect_Switches;
- (void)activate:(NSObject *)switches;
- (void)deactivate:(NSObject *)switches;
- (void)connect_to_switch:(int)switchIndex protocol:(int)protocol retries:(int)retries showMessagesOnError:(BOOL)showMessagesOnError;
- (void)SequenceThroughSwitches:(id)switchSequence;
- (void)sendSwitchState;
- (void)display_battery_warning:(NSString *)text;
- (void)Background_Thread_To_Detect_Wifi;
@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (retain) NSLock *switchDataLock;
@property (retain) NSLock *switchStateLock;
@property (nonatomic) CFMutableDictionaryRef switchNameDictionary;
@property (nonatomic) CFMutableArrayRef switchNameArray;
@property (nonatomic) int active_switch_index;
@property (nonatomic) int switch_socket;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIColor *foregroundColor;

// Information for WiFi network detection
@property (retain) NSLock *wifiDataLock;
@property (nonatomic) CFMutableDictionaryRef wifiNameDictionary;
@property (nonatomic) CFMutableArrayRef wifiNameArray;


@end
