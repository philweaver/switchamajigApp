//
//  SwitchControlAppDelegate.m
//  SwitchControl
//
//  Created by Phil Weaver on 7/23/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import "SwitchControlAppDelegate.h"
#import "rootSwitchViewController.h"
#import "Reachability.h"
#import "signal.h"

@implementation SwitchControlAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize friendlyNameHostNameDictionary;
@synthesize statusMessages;
@synthesize statusInfoLock;
@synthesize switchStateLock = _switchStateLock;
@synthesize active_switch_index = _active_switch_index;
@synthesize switch_socket = _switch_socket;
@synthesize backgroundColor = _backgroundColor;
@synthesize foregroundColor = _foregroundColor;

#define SETTINGS_UDP_PROTOCOL 0
#define SETTINGS_TCP_PROTOCOL 1
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self setActive_switch_index:-1];
    // Disable SIGPIPE
    struct sigaction sigpipeaction;
    memset(&sigpipeaction, 0, sizeof(sigpipeaction));
    sigpipeaction.sa_handler = SIG_IGN;
    sigaction(SIGPIPE, &sigpipeaction, NULL);
    // Initialize the list of switches and the lock that keeps it threadsafe
    [self setFriendlyNameHostNameDictionary:[[NSMutableDictionary alloc] initWithCapacity:5]];
    [self setStatusInfoLock:[[NSLock alloc] init]];
    
    // Initialize colors
    [self setBackgroundColor:[UIColor blackColor]];
    [self setForegroundColor:[UIColor whiteColor]];
    // Initialize the root view controller
    [self setNavigationController:[[UINavigationController alloc] initWithRootViewController:[[rootSwitchViewController alloc] initWithNibName:nil bundle:nil]]];
    [[self window] setRootViewController: [self navigationController]];
    [self.window makeKeyAndVisible];  
    // Listen for Switchamajigs
    sjigControllerListener = [[SwitchamajigControllerDeviceListener alloc] initWithDelegate:self];
    //  Initialize switch state
    [self setSwitch_socket:-1];
    switch_state = 0;
    [self setSwitchStateLock:[[NSLock alloc] init]];
    // Create browser to listen for Bonjour services
    netServiceBrowser = [[NSNetServiceBrowser alloc] init];
    [netServiceBrowser setDelegate:self];
    [netServiceBrowser searchForServicesOfType:@"_sqp._tcp." inDomain:@""];
    //[netServiceBrowser searchForServicesOfType:@"_http._tcp." inDomain:@""];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
    if([self switch_socket] >= 0)
        close([self switch_socket]);
}

#define ITACH_MAX_PACKET_SIZE 1024


#define MAX_STRING 1024
static int convertFromLogicalToPhysicalSwitchMask(int logicalSwitchMask) {
    int physicalSwitchMask = 0;
    if(logicalSwitchMask & 0x01)
        physicalSwitchMask |= 0x20;
    if(logicalSwitchMask & 0x02)
        physicalSwitchMask |= 0x40;
    if(logicalSwitchMask & 0x04)
        physicalSwitchMask |= 0x80;
    if(logicalSwitchMask & 0x08)
        physicalSwitchMask |= 0x100;
    return physicalSwitchMask;
}

// Utility function for verifying that we get the expected response from a socket
bool verify_socket_reply(int socket, const char *expected_string);
bool verify_socket_reply(int socket, const char *expected_string) {
    int expected_len = strlen(expected_string);
    char *buffer = malloc(expected_len);
    if(!buffer)
        return false;
    int total_bytes_read = 0;
    while(total_bytes_read < expected_len) {
        struct timeval tv;
        int bytes_read;
        fd_set readfds;
        tv.tv_sec = 0;
        tv.tv_usec = 500000; // 0.5s
        FD_ZERO(&readfds);
        FD_SET(socket, &readfds);
        select(socket+1, &readfds, NULL, NULL, &tv);
        if(!FD_ISSET(socket, &readfds)) {
            free(buffer);
            return false;
        }
        bytes_read = recv(socket, buffer+total_bytes_read, expected_len - total_bytes_read, 0);
        if(bytes_read <= 0) {
            NSLog(@"%s\n", strerror(errno));
            free(buffer);
            return false;
        }
        for(int i=total_bytes_read; i < total_bytes_read + bytes_read; ++i) {
            if(expected_string[i] != buffer[i]) {
                free(buffer);
                return false;
            }
        }
        total_bytes_read += bytes_read;
    }
    free(buffer);
    return true;
}
- (void)SequenceThroughSwitches:(id)switchSequence {
#if 0
// Redesign needed
    NSAutoreleasePool *mempool = [[NSAutoreleasePool alloc] init];
    [switchSequence retain];
    NSArray *sequence = (NSArray *)switchSequence;
    int index = 1;
    while(1) {
        NSNumber *dontQuit = [sequence objectAtIndex:0];
        if(![dontQuit integerValue])
            break;
        if([sequence count] < index+1) {
            index = 1;
            continue;
        }
        NSNumber *mask = [sequence objectAtIndex:index++];
        NSNumber *time = [sequence objectAtIndex:index++];
        [self activate:mask];
        [NSThread sleepForTimeInterval:[time floatValue]];
        [self deactivate:mask];
    }
    [switchSequence release];
    [mempool release];
#endif
}
#define SWITCHAMAJIG_PACKET_LENGTH 8
#define SWITCHAMAJIG_PACKET_BYTE_0 255
#define SWITCHAMAJIG_CMD_SET_RELAY 0
- (void)sendSwitchState {
#if 0
    // REDESIGN
    int switchIndex = [self active_switch_index];
    unsigned char packet[SWITCHAMAJIG_PACKET_LENGTH];
    memset(packet, 0, sizeof(packet));
    packet[0] = SWITCHAMAJIG_PACKET_BYTE_0;
    packet[1] = SWITCHAMAJIG_CMD_SET_RELAY;
    packet[2] = switch_state & 0x0f;
    packet[3] = (switch_state >> 4) & 0x0f;
    int retries = 1;
    int retval;
    if([self current_switch_connection_protocol] == IPPROTO_TCP) {
        do {
            retval = send([self switch_socket], packet, sizeof(packet), 0);
            if((retval < 0) && retries) {
                [self connect_to_switch:switchIndex protocol:[self current_switch_connection_protocol] retries:5 showMessagesOnError:NO];
                NSLog(@"Retrying write for sendSwitchState (tcp)");
            }
            verify_socket_reply([self switch_socket], "lots of stuff to make sure we clear the buffer");
        } while((retval <= 0) && (retries--));
    }
    if([self current_switch_connection_protocol] == IPPROTO_UDP) {
        do {
            retval = sendto([self switch_socket], packet, sizeof(packet), 0, (struct sockaddr*) &udp_socket_address, sizeof(udp_socket_address));
            if((retval < 0) && retries) {
                [self connect_to_switch:switchIndex protocol:[self current_switch_connection_protocol] retries:5 showMessagesOnError:NO];
                NSLog(@"Retrying write for sendSwitchState (udp)");
            }
        } while((retval <= 0) && (retries--));
    }
#endif
}

#define COMMAND_OFFSET 65536
char *commands[] = {
    "POST /docmnd.xml HTTP/1.1\r\nContent-Type: text/xml\r\nContent-Length: 179\r\n\r\n<docommand key=\"dev\" repeat=\"n\" seq=\"n\" command=\"onoff\" irdata=\"L30 12d00 d40400d4 8f3906e2 37d00d4 29800d4 e2b213 23333333 33332333 33333323 33333332 32222332 32222320\" ch=\"0\" />", // Power
    
    "POST /docmnd.xml HTTP/1.1\r\nContent-Type: text/xml\r\nContent-Length: 179\r\n\r\n<docommand key=\"dev\" repeat=\"n\" seq=\"n\" command=\"voldn\" irdata=\"L30 12d00 d40400d4 8f3c06e2 37d00d4 29800d4 e2b213 23333333 33332333 33333323 33333332 33332332 33332320\" ch=\"0\" />", // Vol down
    
    "POST /docmnd.xml HTTP/1.1\r\nContent-Type: text/xml\r\nContent-Length: 179\r\n\r\n<docommand key=\"dev\" repeat=\"n\" seq=\"n\" command=\"volup\" irdata=\"L30 12d00 d40400d4 8f3d06e2 37d00d4 29800d4 e2b213 23333333 33332333 33333323 33333333 33332333 33332320\" ch=\"0\" />", // Vol up
    
    "POST /docmnd.xml HTTP/1.1\r\nContent-Type: text/xml\r\nContent-Length: 138\r\n\r\n<docommand key=\"dev\" repeat=\"n\" seq=\"n\" command=\"chndn\" irdata=\"L1b 11800 d4842424 54555545 55544554 44445555 55554441 30823021\" ch=\"0\" />", // Chan down
    
    "POST /docmnd.xml HTTP/1.1\r\nContent-Type: text/xml\r\nContent-Length: 138\r\n\r\n<docommand key=\"dev\" repeat=\"n\" seq=\"n\" command=\"chnup\" irdata=\"L1b 11800 d4842424 54555545 55544555 44445555 55554441 30823000\" ch=\"0\" />" // Chan up
};

- (void)activate:(NSObject *)switches {
}

- (void)deactivate:(NSObject *)switches {
}

- (void) addStatusAlertMessage:(NSString *)message withColor:(UIColor*)color displayForSeconds:(float)seconds {
    NSArray *messageArray = [NSArray arrayWithObjects:message, seconds, color, nil];
    [[self statusInfoLock] lock];
    [[self statusMessages] addObject:messageArray];
    [[self statusInfoLock] unlock];
}

// Initialize connection with remote switch
- (void)connect_to_switch:(int)switchIndex protocol:(int)protocol retries:(int)retries showMessagesOnError:(BOOL)showMessagesOnError
{
}

// NSNetServiceBrowserDelegate
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing {
    NSLog(@"didFindDomain: %@\n", domainName);
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
    NSLog(@"didFindService %@\n", [netService hostName]);
    [netService setDelegate:self];
    [netService resolveWithTimeout:0];
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didNotSearch:(NSDictionary *)errorInfo {
    NSLog(@"didNotSearch: %@ %@\n", [errorInfo objectForKey:NSNetServicesErrorCode], [errorInfo objectForKey:NSNetServicesErrorDomain]);
    
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveDomain:(NSString *)domainName moreComing:(BOOL)moreDomainsComing {
    printf("didRemoveDomain\n");
    
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)netService moreComing:(BOOL)moreServicesComing {
    printf("didRemoveService\n");
    
}
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)netServiceBrowser {
    printf("netServiceBrowserDidStopSearch\n");
    
}
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)netServiceBrowser {
    printf("netServiceBrowserWillSearch\n");
    
}
// NSNetServiceDelegate
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict {
    NSLog(@"didNotPublish\n");
}
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict{
    NSLog(@"didNotResolve\n");
}

- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data{
    NSLog(@"didUpdateTXTRecordData\n");
}

- (void)netServiceDidPublish:(NSNetService *)sender{
    NSLog(@"netServiceDidPublish\n");
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender{
    int numaddresses = [[sender addresses] count];
    NSData *address = [[sender addresses] objectAtIndex:0];
    struct sockaddr_in *socketAddress = (struct sockaddr_in *) [address bytes];
    NSString *ipString = [NSString stringWithFormat: @"%s", inet_ntoa(socketAddress->sin_addr)];
    NSLog(@"netServiceDidResolveAddress. %d addresses. Hostname %@. IP %@\n", numaddresses, [sender hostName], ipString);
    // Add this to list of switches
    // Lock the switch info and then update it
#if 0
// Redesign
    [[self switchDataLock] lock];
    NSString *switchName = @"sq";
    if(CFDictionaryContainsKey((CFDictionaryRef) [self switchNameDictionary], switchName)) {
        CFDictionaryRemoveValue([self switchNameDictionary], switchName);
    } else {
        CFArrayAppendValue([self switchNameArray], switchName);
    }
    CFDictionaryAddValue([self switchNameDictionary], switchName, ipString);
    [[self switchDataLock] unlock];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"switch_list_was_updated" object:nil];
#endif
}

- (void)netServiceDidStop:(NSNetService *)sender{
    NSLog(@"netServiceDidStop\n");
}

- (void)netServiceWillPublish:(NSNetService *)sender{
    NSLog(@"netServiceWillPublish\n");
}

- (void)netServiceWillResolve:(NSNetService *)sender{
    NSLog(@"netServiceWillResolve\n");
}

// SwitchamajigDeviceListenerDelegate
- (void) SwitchamajigDeviceListenerFoundDevice:(id)listener hostname:(NSString*)hostname friendlyname:(NSString*)friendlyname {
    [statusInfoLock lock];
    [friendlyNameHostNameDictionary setObject:hostname forKey:friendlyname];
    [statusInfoLock unlock];
}
- (void) SwitchamajigDeviceListenerHandleError:(id)listener theError:(NSError*)error {
    NSLog(@"SwitchamajigDeviceListenerHandleError: %@", error); 
}
- (void) SwitchamajigDeviceListenerHandleBatteryWarning:(id)listener hostname:(NSString*)hostname friendlyname:(NSString*)friendlyname {
    [statusInfoLock lock];
    [self addStatusAlertMessage:[NSString stringWithFormat:@"%@ needs its batteries replaced",friendlyname]  withColor:[UIColor redColor] displayForSeconds:5.0];
    [statusInfoLock unlock];
}


@end
