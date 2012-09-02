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

// Silly widgit that probably means I should be signaling the action thread to stop in some better way
@interface SwitchamajigMutableBool : NSObject {
}
@property BOOL value;
@end
@implementation SwitchamajigMutableBool
@synthesize value;
@end


@implementation SwitchControlAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize friendlyNameSwitchamajigDictionary;
@synthesize actionnameActionthreadDictionary;
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
    // Initialize default settings values if needed
    [[NSUserDefaults standardUserDefaults] registerDefaults:[self defaultsFromPlistNamed:@"Root"]];
    [self setActive_switch_index:-1];
    // Disable SIGPIPE
    struct sigaction sigpipeaction;
    memset(&sigpipeaction, 0, sizeof(sigpipeaction));
    sigpipeaction.sa_handler = SIG_IGN;
    sigaction(SIGPIPE, &sigpipeaction, NULL);
    // Initialize the list of switches and the lock that keeps it threadsafe
    [self setFriendlyNameSwitchamajigDictionary:[[NSMutableDictionary alloc] initWithCapacity:5]];
    [self setActionnameActionthreadDictionary:[[NSMutableDictionary alloc] initWithCapacity:20]];
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
    sjigIRListener = [[SwitchamajigIRDeviceListener alloc] initWithDelegate:self];
    //  Initialize switch state
    [self setSwitch_socket:-1];
    switch_state = 0;
    [self setSwitchStateLock:[[NSLock alloc] init]];
    // Create browser to listen for Bonjour services
    //netServiceBrowser = [[NSNetServiceBrowser alloc] init];
    //[netServiceBrowser setDelegate:self];
    //[netServiceBrowser searchForServicesOfType:@"_sqp._tcp." inDomain:@""];
    // Prepare to run status timer
    statusMessageTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(statusMessageCallback) userInfo:nil repeats:NO]; 
    //[netServiceBrowser searchForServicesOfType:@"_http._tcp." inDomain:@""];
    friendlyNameDictionaryIndex = 0;
    [self setStatusMessages:[[NSMutableArray alloc] initWithCapacity:5]];
    listenerDevicesToIgnore = 0;
    // Add IR database
    NSString *irDatabasePath = [[NSBundle mainBundle] pathForResource:@"IRDB" ofType:@"sqlite"];
    NSError *error;
    [SwitchamajigIRDeviceDriver loadIRCodeDatabase:irDatabasePath error:&error];
    if(error) {
        NSLog(@"Error loading IR database: %@", error);
    }
    switchamajigIRLock = [[NSLock alloc] init];
    return YES;
}

- (void) statusMessageCallback {
    // If there are any alerts, display them
    float secondsUntilNextCall = 365.0*24.0*60.0*60.0; // If nothing to update, fire once a year, if we need it or not...
    [[self statusInfoLock] lock];
    if([[self statusMessages] count]) {
        NSArray *messageArray = [[self statusMessages] objectAtIndex:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switchamajigMessagesSetText" object:[messageArray objectAtIndex:0]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switchamajigMessagesSetColor" object:[messageArray objectAtIndex:2]];
        secondsUntilNextCall = [[messageArray objectAtIndex:1] floatValue];
        [[self statusMessages] removeObjectAtIndex:0];
    } 
    else if ([[self friendlyNameSwitchamajigDictionary] count] == 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switchamajigMessagesSetText" object:@"No Switchamajigs Found"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switchamajigMessagesSetColor" object:[UIColor redColor]];
    } else {
        // Cycle through all connected switches
        NSArray *friendlyNames = [[self friendlyNameSwitchamajigDictionary] allKeys];
        if(++friendlyNameDictionaryIndex >= [friendlyNames count])
            friendlyNameDictionaryIndex = 0;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switchamajigMessagesSetText" object:[NSString stringWithFormat:@"Connected to %@",[friendlyNames objectAtIndex:friendlyNameDictionaryIndex]]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switchamajigMessagesSetColor" object:[UIColor whiteColor]];
        secondsUntilNextCall = 3.0;
    }
    [[self statusInfoLock] unlock];
    statusMessageTimer = [NSTimer scheduledTimerWithTimeInterval:secondsUntilNextCall target:self selector:@selector(statusMessageCallback) userInfo:nil repeats:NO]; 
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

- (void)performActionSequence:(DDXMLNode *)actionSequenceOnDevice {
    // Get the friendly name for this sequence
    NSError *xmlError;
    NSArray *friendlyNames = [actionSequenceOnDevice nodesForXPath:@".//friendlyname" error:&xmlError];
    if([friendlyNames count] < 1) {
        NSLog(@"Can't find friendly name. Count = %d. Node string = %@", [friendlyNames count], [actionSequenceOnDevice XMLString]);
        return;
    }
    DDXMLNode *friendlyNameNode = [friendlyNames objectAtIndex:0];
    NSString *friendlyName = [friendlyNameNode stringValue];
    if(friendlyName == nil) {
        NSLog(@"performActionSequence: friendlyname is nil. Node string = %@", [actionSequenceOnDevice XMLString]);
        return;
    }
    // Look up the driver for friendly name
    [statusInfoLock lock];
    if([friendlyName isEqualToString:@"Default"]) {
        if(![[self friendlyNameSwitchamajigDictionary]count]) {
            [statusInfoLock unlock];
            NSLog(@"Received default request, but no drivers available");
            return;
        }
        friendlyName = [[[self friendlyNameSwitchamajigDictionary] allKeys] objectAtIndex:0];
    }
    SwitchamajigDriver *driver = [[self friendlyNameSwitchamajigDictionary] objectForKey:friendlyName];
    [statusInfoLock unlock];
    if(driver == nil) {
        NSLog(@"performActionSequence: driver is nil for friendlyname %@", friendlyName);
        return;
    }
    NSArray *actionSequences = [actionSequenceOnDevice nodesForXPath:@".//actionsequence" error:&xmlError];
    if([actionSequences count] < 1){
        NSLog(@"performActionSequence: no action sequences for string %@", [actionSequenceOnDevice XMLString]);
        return;
    }
    DDXMLNode *actionSequence = [actionSequences objectAtIndex:0];

    NSArray *actionNames = [actionSequenceOnDevice nodesForXPath:@".//actionname" error:&xmlError];
    NSString *actionName;
    if([actionNames count]) {
        DDXMLNode *actionNameNode = [actionNames objectAtIndex:0];
        actionName = [actionNameNode stringValue];
    } else
        actionName = friendlyName;
    // Stop any existing thread with this name
    SwitchamajigMutableBool *killCurrentThread = [actionnameActionthreadDictionary valueForKey:actionName];
    if(killCurrentThread != nil) {
        [killCurrentThread setValue:YES];
    }
    // Create an array to pass to the background thread with the synchronization object
    SwitchamajigMutableBool *threadExitBool = [SwitchamajigMutableBool alloc];
    [threadExitBool setValue:NO];
    // Add a dictionary entry for this thread
    [actionnameActionthreadDictionary setValue:threadExitBool forKey:actionName];
    NSArray *threadInfoArray = [NSArray arrayWithObjects:driver, actionSequence, threadExitBool, nil];
    // Start a thread to perform the action
    [self performSelectorInBackground:@selector(executeActionSequence:) withObject:threadInfoArray];
}


- (void) executeActionSequence:(NSArray *)threadInfoArray {
    @autoreleasepool {
        // Unpack the thread info
        SwitchamajigDriver *driver = [threadInfoArray objectAtIndex:0];
        DDXMLNode *actionSequence = [threadInfoArray objectAtIndex:1];
        SwitchamajigMutableBool *threadExitBool = [threadInfoArray objectAtIndex:2];
        if((driver == nil) || (actionSequence == nil) || (threadExitBool == nil)) {
            NSLog(@"executeActionSequence: values are nil. Aborting action.");
            return;
        }
        NSArray *actions = [actionSequence children];
        DDXMLNode *action;
        for(action in actions) {
            // Exit if requested to do so
            if([threadExitBool value])
                break;
            if([[action name] isEqualToString:@"loop"]) {
                // Recursively call this function to perform the actions in the loop
                NSArray *loopInfoArray = [NSArray arrayWithObjects:driver, action, threadExitBool, nil];
                while(![threadExitBool value]) {
                    [self executeActionSequence:loopInfoArray];
                }
                continue;
            }
            if([[action name] isEqualToString:@"delay"]) {
                NSScanner *delayScan = [[NSScanner alloc] initWithString:[action stringValue]];
                double delay;
                bool delay_ok = [delayScan scanDouble:&delay];
                if(!delay_ok) {
                    NSLog(@"Problem reading delay amount");
                    continue;
                }
                [NSThread sleepForTimeInterval:delay];
                continue;
            }
            if([[action name] isEqualToString:@"stopactionwithname"]) {
                // Stop any existing thread with this name
                SwitchamajigMutableBool *killCurrentThread = [actionnameActionthreadDictionary valueForKey:[action stringValue]];
                if(killCurrentThread != nil) {
                    [killCurrentThread setValue:YES];
                }
                continue;
            }
            
            // Send command to driver
            NSLog(@"Issuing command %@", [action XMLString]);
            NSError *error;
            [driver issueCommandFromXMLNode:action error:&error];
        }
    }
}

- (void) addStatusAlertMessage:(NSString *)message withColor:(UIColor*)color displayForSeconds:(float)seconds {
    NSArray *messageArray = [NSArray arrayWithObjects:message, [NSNumber numberWithFloat:seconds], color, nil];
    [[self statusInfoLock] lock];
    [[self statusMessages] addObject:messageArray];
    [[self statusInfoLock] unlock];
    if([statusMessageTimer isValid])
        [statusMessageTimer fire];
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

// SwitchamajigDeviceDriverDelegate
- (void) SwitchamajigDeviceDriverConnected:(id)deviceDriver {
}

- (void) SwitchamajigDeviceDriverDisconnected:(id)deviceDriver withError:(NSError*)error {
    // Show status message
    [statusInfoLock lock];
    NSArray *friendlyNames = [[self friendlyNameSwitchamajigDictionary] allKeysForObject:deviceDriver];
    [statusInfoLock unlock];
    if([friendlyNames count] != 1) {
        // Hopefully this won't happen. Each driver should have exactly one name
        NSLog(@"SwitchamajigDeviceDriverConnected: %d names for driver on disconnect.", [friendlyNames count]);
    }
    NSString *friendlyName;
    for (friendlyName in friendlyNames) {
        [self addStatusAlertMessage:[NSString stringWithFormat:@"Disconnected from %@",friendlyName]  withColor:[UIColor redColor] displayForSeconds:5.0];
    }
    [statusInfoLock lock];
    [[self friendlyNameSwitchamajigDictionary] removeObjectsForKeys:friendlyNames];
    [statusInfoLock unlock];
}

// IR Delegate
-(void) SwitchamajigIRDeviceDriverDelegateDidReceiveLearnedIRCommand:(id)deviceDriver irCommand:(NSString *)irCommand {
    [switchamajigIRLock lock];
    lastLearnedIRCommand = irCommand;
    [switchamajigIRLock unlock];
}
-(void) SwitchamajigIRDeviceDriverDelegateErrorOnLearnIR:(id)deviceDriver error:(NSError *)error {
    [switchamajigIRLock lock];
    lastLearnedIRError = error;
    [switchamajigIRLock unlock];    
}

// Access to IR learning stuff
- (NSString *) getLastLearnedIRCommand {
    [switchamajigIRLock lock];
    NSString * retVal = lastLearnedIRCommand;
    [switchamajigIRLock unlock];
    return retVal;
}
- (NSError *) getLastLearnedIRError {
    [switchamajigIRLock lock];
    NSError * retVal = lastLearnedIRError;
    [switchamajigIRLock unlock];
    return retVal;
}
- (void) clearLastLearnedIRInfo {
    [switchamajigIRLock lock];
    lastLearnedIRError = nil;
    lastLearnedIRCommand = nil;
    [switchamajigIRLock unlock];
}


- (SwitchamajigControllerDeviceDriver *) firstSwitchamajigControllerDriver {
    SwitchamajigControllerDeviceDriver *firstDriver = nil;
    [statusInfoLock lock];
    NSArray *friendlyNames = [[self friendlyNameSwitchamajigDictionary] allKeys];
    NSString *name;
    for(name in friendlyNames) {
        SwitchamajigDriver *driver = [[self friendlyNameSwitchamajigDictionary] objectForKey:name];
        if([driver isKindOfClass:[SwitchamajigControllerDeviceDriver class]]) {
            firstDriver = (SwitchamajigControllerDeviceDriver *)driver;
            break;
        }
    }
    [statusInfoLock unlock];
    return firstDriver;
}

- (void)removeDriver:(SwitchamajigDriver *)driver {
    [statusInfoLock lock];
    NSArray *friendlyNames = [[self friendlyNameSwitchamajigDictionary] allKeysForObject:driver];
    [[self friendlyNameSwitchamajigDictionary] removeObjectsForKeys:friendlyNames];
    [statusInfoLock unlock];
    listenerDevicesToIgnore = 1; // Total hack to avoid race condition
}

// SwitchamajigDeviceListenerDelegate
- (void) SwitchamajigDeviceListenerFoundDevice:(id)listener hostname:(NSString*)hostname friendlyname:(NSString*)friendlyname {
    if(listenerDevicesToIgnore) {
        --listenerDevicesToIgnore;
        return;
    }
    [statusInfoLock lock];
    SwitchamajigDriver *driver = [[self friendlyNameSwitchamajigDictionary] objectForKey:friendlyname];
    // Don't constantly reinitialize drivers
    if(driver != nil) {
        [statusInfoLock unlock];
        return;
    }
    if([listener isKindOfClass:[SwitchamajigControllerDeviceListener class]]) {
        SwitchamajigControllerDeviceDriver *sjcdriver = [SwitchamajigControllerDeviceDriver alloc];
        [sjcdriver setUseUDP:[[NSUserDefaults standardUserDefaults] boolForKey:@"useUDPWithSwitchamajigControllerPreference"]];
        driver = sjcdriver;
    }
    else if([listener isKindOfClass:[SwitchamajigIRDeviceListener class]]) {
        SwitchamajigIRDeviceDriver *sjirdriver = [SwitchamajigIRDeviceDriver alloc];
        driver = sjirdriver;
    } else {
        // Unrecognized
        NSLog(@"SwitchamajigDeviceListenerFoundDevice: Unrecognized listener");
        [statusInfoLock unlock];
        return;
    }
    driver = [driver initWithHostname:hostname];
    [driver setDelegate:self];
    [[self friendlyNameSwitchamajigDictionary] setObject:driver forKey:friendlyname];
    [statusInfoLock unlock];
    // Show status message
    NSString *statusString = [NSString stringWithFormat:@"Connected to %@",friendlyname];
    NSLog(@"%@", statusString);
    [self addStatusAlertMessage:statusString withColor:[UIColor whiteColor] displayForSeconds:5.0];
    
}
- (void) SwitchamajigDeviceListenerHandleError:(id)listener theError:(NSError*)error {
    NSLog(@"SwitchamajigDeviceListenerHandleError: %@", error); 
}
- (void) SwitchamajigDeviceListenerHandleBatteryWarning:(id)listener hostname:(NSString*)hostname friendlyname:(NSString*)friendlyname {
    [self addStatusAlertMessage:[NSString stringWithFormat:@"%@ needs its batteries replaced",friendlyname]  withColor:[UIColor redColor] displayForSeconds:5.0];
}

// Handle settings initialization
- (NSDictionary *)defaultsFromPlistNamed:(NSString *)plistName {
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    NSAssert(settingsBundle, @"Could not find Settings.bundle while loading defaults.");
    
    NSString *plistFullName = [NSString stringWithFormat:@"%@.plist", plistName];
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:plistFullName]];
    NSAssert1(settings, @"Could not load plist '%@' while loading defaults.", plistFullName);
    
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    NSAssert1(preferences, @"Could not find preferences entry in plist '%@' while loading defaults.", plistFullName);
    
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    for(NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        id value = [prefSpecification objectForKey:@"DefaultValue"];
        if(key && value) {
            [defaults setObject:value forKey:key];
        } 
        
        NSString *type = [prefSpecification objectForKey:@"Type"];
        if ([type isEqualToString:@"PSChildPaneSpecifier"]) {
            NSString *file = [prefSpecification objectForKey:@"File"];
            NSAssert1(file, @"Unable to get child plist name from plist '%@'", plistFullName);
            [defaults addEntriesFromDictionary:[self defaultsFromPlistNamed:file]];
        }        
    }
    
    return defaults;
}

@end
