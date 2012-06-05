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
@synthesize switchDataLock = _switchDataLock;
@synthesize switchStateLock = _switchStateLock;
@synthesize switchNameDictionary = _switchNameDictionary;
@synthesize switchNameArray = _switchNameArray;
@synthesize active_switch_index = _active_switch_index;
@synthesize switch_socket = _switch_socket;
@synthesize settings_switch_connection_protocol = _settings_switch_connection_protocol;
@synthesize current_switch_connection_protocol = _current_switch_connection_protocol;
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
    [self setSwitchDataLock:[[NSLock alloc] init]];
    [self setSwitchNameDictionary:CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks)];
    [self setSwitchNameArray:CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks)];
    CFDictionaryRemoveAllValues([self switchNameDictionary]);    
    CFArrayRemoveAllValues([self switchNameArray]);
    
    // Read protocol from settings
    int settingsVal = [[NSUserDefaults standardUserDefaults] integerForKey:@"IP_PROTOCOL"];

    [self setSettings_switch_connection_protocol:((settingsVal == SETTINGS_TCP_PROTOCOL)?IPPROTO_TCP:IPPROTO_UDP)];
    // Initialize colors
    [self setBackgroundColor:[UIColor blackColor]];
    [self setForegroundColor:[UIColor whiteColor]];
    // Initialize the root view controller
    [self setNavigationController:[[UINavigationController alloc] initWithRootViewController:[[rootSwitchViewController alloc] initWithNibName:nil bundle:nil]]];
    [[self window] setRootViewController: [self navigationController]];
    [self.window makeKeyAndVisible];    
    // Start the background thread that listens for switches
    //  Initialize switch state
    [self setSwitch_socket:-1];
    switch_state = 0;
    [self performSelectorInBackground:@selector(Background_Thread_To_Detect_Switches) withObject:nil];
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
    CFRelease([self switchNameDictionary]);
    CFRelease([self switchNameArray]);
}

// Detect switches in area
#define EXPECTED_PACKET_SIZE 110
#define DEVICE_STRING_OFFSET 60
#define BATTERY_VOLTAGE_OFFSET 14
#define BATTERY_VOLTAGE_WARN_LIMIT 2000

#define ITACH_MAX_PACKET_SIZE 1024

- (void)Background_Thread_To_Detect_Switches {
    @autoreleasepool {
        bool haveShownBatteryWarning = false; // Flag to show battery warning only once per session
        // Check if we have network access
        NetworkStatus internetStatus;
        int retries = 50;
        do {
            Reachability *r = [Reachability reachabilityForLocalWiFi];
            internetStatus = [r currentReachabilityStatus];
            if(internetStatus == NotReachable)
                NSLog(@"Retrying check for network access.");
            [NSThread sleepForTimeInterval:1.0];
        } while((internetStatus == NotReachable) && retries--);
        if(internetStatus == NotReachable) {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"No WiFi Connection."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
            [message show];  
            return;
        }
#if 0
// This mechanism needs to be implemented for new architecture
        // Try to connect to last switch we were using
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cacheDirectory = [paths objectAtIndex:0];
        NSString *filename = [cacheDirectory stringByAppendingString:@"lastswitchinfo.txt"];
        NSString *twoNames = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:nil];
        NSString *initialSwitchName = 0, *initialIP = 0;
        if(twoNames) {
            NSScanner *myScanner = [NSScanner scannerWithString:twoNames];
            [myScanner scanUpToString:@":" intoString:&initialSwitchName];
            [myScanner scanString:@":" intoString:NULL];
            initialIP = [twoNames substringFromIndex:[myScanner scanLocation]];
            [[self switchDataLock] lock];
            CFArrayAppendValue([self switchNameArray], initialSwitchName);
            CFDictionaryAddValue([self switchNameDictionary], initialSwitchName, initialIP);
            [[self switchDataLock] unlock];
            // Connect via TCP to confirm that we have a connection
            [self connect_to_switch:0 protocol:IPPROTO_TCP retries:0 showMessagesOnError:NO];
            // Assuming TCP succeeded, reconnect again if we don't want TCP
            if(([self active_switch_index] >= 0) && ([self settings_switch_connection_protocol] != IPPROTO_TCP))
                [self connect_to_switch:0 protocol:[self settings_switch_connection_protocol] retries:0 showMessagesOnError:NO];
        }
        if([self active_switch_index] < 0) {
            [[self switchDataLock] lock];
            CFDictionaryRemoveAllValues([self switchNameDictionary]);
            CFArrayRemoveAllValues([self switchNameArray]);
            [[self switchDataLock] unlock];
        } else {
            [self sendSwitchState];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switch_list_was_updated" object:nil];
#endif        
        // Open socket to detect Switchamajig Controllers with Roving Modules
        int detect_socket;
        detect_socket = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
        if(socket < 0) {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Detect error!" message:@"Error opening UDP socket."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
            [message show];  
            return;
        }
        struct sockaddr_in sockin_addr;
        memset(&sockin_addr, 0, sizeof(sockin_addr));
        sockin_addr.sin_family = AF_INET;
        sockin_addr.sin_port = htons(55555);
        sockin_addr.sin_addr.s_addr = INADDR_ANY;
        if(bind(detect_socket, (struct sockaddr *) &sockin_addr, sizeof(sockin_addr)) < 0) {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Detect error!" message:@"Error binding UDP socket."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
            [message show];  
            close(detect_socket);
            return;
        }
        
        // Now loop and listen for switches
        char buffer[2*EXPECTED_PACKET_SIZE+1];
        while(1) {
            struct sockaddr_storage switch_address;
            socklen_t addr_len = sizeof(switch_address);
            //  Use a non-blocking receive to see if anything arrived 
            int numbytes = recvfrom(detect_socket, buffer, 2*EXPECTED_PACKET_SIZE, MSG_PEEK | MSG_DONTWAIT, (struct sockaddr *) &switch_address, &addr_len);
            if((numbytes < 0) && (errno == EWOULDBLOCK))
                numbytes = 0;
            if(numbytes < 0) {
                //printf("Error numbytes=%d\n", numbytes);
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Detect error!" message:@"Error checking for data."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
                [message show];  
                close(detect_socket);
                return;
            }
            // Switch to blocking and receive any data that's available.
            numbytes = (numbytes) ? (recvfrom(detect_socket, buffer, EXPECTED_PACKET_SIZE, 0, (struct sockaddr *) &switch_address, &addr_len)) : 0;
            if(numbytes < 0){
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Detect error!" message:@"Error on recvfrom."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
                [message show];  
                close(detect_socket);
                return;
            }
            //if(numbytes)
            //    printf("numbytes=%d\n", numbytes);
            if(numbytes == EXPECTED_PACKET_SIZE) {
                // Get the IP address in string format
                char ip_addr_string[INET6_ADDRSTRLEN];
                struct sockaddr *sockaddr_ptr = (struct sockaddr *) &switch_address;
                
                inet_ntop(switch_address.ss_family, (sockaddr_ptr->sa_family == AF_INET) ? (void*)&(((struct sockaddr_in *)sockaddr_ptr)->sin_addr) : (void*)&(((struct sockaddr_in6 *)sockaddr_ptr)->sin6_addr), ip_addr_string, sizeof(ip_addr_string));
                //printf("Received: %s from %s\n", buffer+DEVICE_STRING_OFFSET, ip_addr_string);
                NSString *switchName = [NSString stringWithCString:buffer+DEVICE_STRING_OFFSET encoding:NSASCIIStringEncoding];
                int batteryVoltage = ((unsigned char)buffer[BATTERY_VOLTAGE_OFFSET]) * 256 + ((unsigned char)buffer[BATTERY_VOLTAGE_OFFSET + 1]);
                if(!haveShownBatteryWarning && (batteryVoltage < BATTERY_VOLTAGE_WARN_LIMIT)) {
                    NSString *batteryWarningText = [switchName stringByAppendingString:@" needs its batteries replaced"];
                    [self performSelectorInBackground:@selector(display_battery_warning:) withObject:batteryWarningText];
                    haveShownBatteryWarning = true;
                }
#if 0
                // New mechanism needed
                NSString *ipAddrStr = [NSString stringWithCString:ip_addr_string encoding:NSASCIIStringEncoding];
                // Lock the switch info and then update it
                [[self switchDataLock] lock];
                if(CFDictionaryContainsKey((CFDictionaryRef) [self switchNameDictionary], switchName)) {
                    CFDictionaryRemoveValue([self switchNameDictionary], switchName);
                } else {
                    CFArrayAppendValue([self switchNameArray], switchName);
                }
                CFDictionaryAddValue([self switchNameDictionary], switchName, ipAddrStr);
                [[self switchDataLock] unlock];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"switch_list_was_updated" object:nil];
#endif
            }
        }
        // This code is unreachable now, but if we ever allow the above loop to exit, we'll need these lines to do it gracefully
        close(detect_socket);
        return;
    }
}

- (void) display_battery_warning:(NSString *)text {
    @autoreleasepool {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Low Battery" message:text  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
    }
}

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

@end
