//
//  SwitchControlAppDelegate.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/23/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "../../SwitchamajigDriver/SwitchamajigDriver/SwitchamajigDriver.h"
#import "sys/socket.h"
#import "netinet/in.h"
#import "netdb.h"
#import "sys/unistd.h"
#import "sys/fcntl.h"
#import "sys/poll.h"
#import "arpa/inet.h"
#import "errno.h"

@class rootSwitchViewController;
#define PROTOCOL_SQ (IPPROTO_TCP + IPPROTO_UDP + 1)
#define ROVING_PORTNUM 2000
#define SQ_PORTNUM 80
@interface SwitchControlAppDelegate : NSObject <UIApplicationDelegate, NSNetServiceBrowserDelegate, NSNetServiceDelegate, SwitchamajigDeviceListenerDelegate, SwitchamajigDeviceDriverDelegate> {
    int switch_state;
    NSNetServiceBrowser *netServiceBrowser;
    SwitchamajigControllerDeviceListener *sjigControllerListener;
    SwitchamajigIRDeviceListener *sjigIRListener;
    int friendlyNameDictionaryIndex;
    NSTimer *statusMessageTimer;
    int listenerDevicesToIgnore;
}
- (void)performActionSequence:(DDXMLNode *)actionSequenceOnDevice;
- (void)connect_to_switch:(int)switchIndex protocol:(int)protocol retries:(int)retries showMessagesOnError:(BOOL)showMessagesOnError;
- (void)SequenceThroughSwitches:(id)switchSequence;
- (void)sendSwitchState;
- (void) addStatusAlertMessage:(NSString *)message withColor:(UIColor*)color displayForSeconds:(float)seconds;
- (void) statusMessageCallback;
- (void) executeActionSequence:(NSArray *)threadInfoArray;
- (SwitchamajigControllerDeviceDriver *) firstSwitchamajigControllerDriver;
- (void)removeDriver:(SwitchamajigDriver *)driver;

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) UINavigationController *navigationController;
@property (retain) NSLock *switchStateLock;
@property (strong, nonatomic) NSMutableDictionary *friendlyNameSwitchamajigDictionary;
@property (strong, nonatomic) NSMutableDictionary *actionnameActionthreadDictionary;
@property (strong, nonatomic) NSLock *statusInfoLock;
@property (strong, nonatomic) NSMutableArray *statusMessages;
@property (nonatomic) int active_switch_index;
@property (nonatomic) int switch_socket;
@property (nonatomic, retain) UIColor *backgroundColor;
@property (nonatomic, retain) UIColor *foregroundColor;

// Settings default handling
- (NSDictionary *)defaultsFromPlistNamed:(NSString *)plistName;

// NSNetServiceBrowserDelegate
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)errorInfo;
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing;
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing;
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser;
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser;

// NSNetServiceDelegate
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict;
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict;
- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data;
- (void)netServiceDidPublish:(NSNetService *)sender;
- (void)netServiceDidResolveAddress:(NSNetService *)sender;
- (void)netServiceDidStop:(NSNetService *)sender;
- (void)netServiceWillPublish:(NSNetService *)sender;
- (void)netServiceWillResolve:(NSNetService *)sender;
@end
