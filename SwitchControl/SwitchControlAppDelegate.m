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

const int switchamajig_protocol = IPPROTO_UDP;

@implementation SwitchControlAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize switchDataLock = _switchDataLock;
@synthesize switchStateLock = _switchStateLock;
@synthesize switchNameDictionary = _switchNameDictionary;
@synthesize switchNameArray = _switchNameArray;
@synthesize active_switch_index = _active_switch_index;
@synthesize switch_socket = _switch_socket;
@synthesize switchMessage = _switchMessage;
@synthesize backgroundColor = _backgroundColor;
@synthesize foregroundColor = _foregroundColor;

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

    // Initialize colors
    [self setBackgroundColor:[UIColor blackColor]];
    [self setForegroundColor:[UIColor whiteColor]];
    // Initialize the root view controller
    rootSwitchViewController *rootController = [[rootSwitchViewController alloc] initWithNibName:@"rootSwitchViewController" bundle:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:rootController];
    [self setNavigationController:navController];
    [navController release];
    [[self window] setRootViewController: [self navigationController]];
    [self.window makeKeyAndVisible];    
    [rootController release];
    // Start the background thread that listens for switches
    //  Initialize switch state
    [self setSwitch_socket:-1];
    switch_state = 0;
    [self performSelectorInBackground:@selector(Background_Thread_To_Detect_Switches) withObject:nil];
    [self setSwitchStateLock:[[NSLock alloc] init]];
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
    [_navigationController release];
    [_window release];
    [_switchDataLock release];
    [_switchStateLock release];
    [_switchMessage release];
    [_backgroundColor release];
    [_foregroundColor release];
    CFRelease([self switchNameDictionary]);
    CFRelease([self switchNameArray]);
    [super dealloc];
}

// Detect switches in area
#define EXPECTED_PACKET_SIZE 110
#define DEVICE_STRING_OFFSET 60
#define BATTERY_VOLTAGE_OFFSET 14
#define BATTERY_VOLTAGE_WARN_LIMIT 2000

- (void)Background_Thread_To_Detect_Switches {
    NSAutoreleasePool *mempool = [[NSAutoreleasePool alloc] init];
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
        [message release];
        [mempool release];
        return;
    }
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
        [self connect_to_switch:0 retries:0 showMessagesOnError:NO];
    }
    if([self active_switch_index] < 0) {
        CFDictionaryRemoveAllValues([self switchNameDictionary]);
        CFArrayRemoveAllValues([self switchNameArray]);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"switch_list_was_updated" object:nil];

    int detect_socket;
    detect_socket = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if(socket < 0) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Detect error!" message:@"Error opening UDP socket."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        [message release];
        [mempool release];
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
        [message release];
        close(detect_socket);
        [mempool release];
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
            [message release];
            close(detect_socket);
            [mempool release];
            return;
        }
        // Switch to blocking and receive any data that's available.
        numbytes = (numbytes) ? (recvfrom(detect_socket, buffer, EXPECTED_PACKET_SIZE, 0, (struct sockaddr *) &switch_address, &addr_len)) : 0;
        if(numbytes < 0){
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Detect error!" message:@"Error on recvfrom."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
            [message show];  
            [message release];
            close(detect_socket);
            [mempool release];
            return;
        }
        //if(numbytes)
        //    printf("numbytes=%d\n", numbytes);
        if(numbytes != EXPECTED_PACKET_SIZE)
            continue;
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
    }
    // This code is unreachable now, but if we ever allow the above loop to exit, we'll need these lines to do it gracefully
    close(detect_socket);
    [mempool release];
    return;
}

- (void) display_battery_warning:(NSString *)text {
    NSAutoreleasePool *mempool = [[NSAutoreleasePool alloc] init];
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Low Battery" message:text  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
    [message show];  
    [message release];
    [mempool release];
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
    if(switchamajig_protocol == IPPROTO_TCP) {
        do {
            retval = send([self switch_socket], packet, sizeof(packet), 0);
            if((retval < 0) && retries) {
                [self connect_to_switch:switchIndex retries:5 showMessagesOnError:NO];
                NSLog(@"Retrying write for sendSwitchState (tcp)");
            }
            verify_socket_reply([self switch_socket], "lots of stuff to make sure we clear the buffer");
        } while((retval <= 0) && (retries--));
    }
    if(switchamajig_protocol == IPPROTO_UDP) {
        do {
            retval = sendto([self switch_socket], packet, sizeof(packet), 0, (struct sockaddr*) &udp_socket_address, sizeof(udp_socket_address));
            if((retval < 0) && retries) {
                [self connect_to_switch:switchIndex retries:5 showMessagesOnError:NO];
                NSLog(@"Retrying write for sendSwitchState (udp)");
            }
        } while((retval <= 0) && (retries--));
    }
}


- (void)activate:(NSObject *)switches {
    int switchIndex = [self active_switch_index];
    if([switches isKindOfClass:[NSNumber class]]) {
        // For a number, just turn on the appropriate switches
        NSNumber *num = (NSNumber *)switches;
        int switchMask = [num integerValue];
        if([self switch_socket] > 0) {
            [[self switchStateLock] lock];
            switch_state |= switchMask;
            [self sendSwitchState];
            [[self switchStateLock] unlock];
        }
    } else {
        // If it's not a number, it must be an array. The first element keeps the background thread active
        NSMutableArray *array = (NSMutableArray *)switches;
        [array replaceObjectAtIndex:0 withObject:[NSNumber numberWithInt:1]];
        [self performSelectorInBackground:@selector(SequenceThroughSwitches:) withObject:(id)switches];
    }
    if(([self active_switch_index] < 0) && (switchIndex >= 0))
    {
        NSString *switchName = (NSString*)CFArrayGetValueAtIndex([self switchNameArray], switchIndex);
        NSString *switchNameText = [@"Lost connection to " stringByAppendingString:switchName];
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Network Error" message:switchNameText  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        [message release];
    }
}

- (void)deactivate:(NSObject *)switches {
    int switchIndex = [self active_switch_index];
    if([switches isKindOfClass:[NSNumber class]]) {
        NSNumber *num = (NSNumber *)switches;
        int switchMask = [num integerValue];
        if([self switch_socket] > 0) {
            [[self switchStateLock] lock];
            switch_state &= ~switchMask;
            [self sendSwitchState];
            [[self switchStateLock] unlock];
        }
    } else {
        // Clear the first element to cause the thread to exit
        NSMutableArray *array = (NSMutableArray *)switches;
        [array replaceObjectAtIndex:0 withObject:[NSNumber numberWithInt:0]];
    }
    if(([self active_switch_index] < 0) && (switchIndex >= 0))
    {
        NSString *switchName = (NSString*)CFArrayGetValueAtIndex([self switchNameArray], switchIndex);
        NSString *switchNameText = [@"Lost connection to " stringByAppendingString:switchName];
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Network Error" message:switchNameText  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [[NSNotificationCenter defaultCenter] postNotificationName:@"switch_list_was_updated" object:nil];
        [message show];  
        [message release];
    }
}

int portno = 2000;
// Initialize connection with remote switch
- (void)connect_to_switch:(int)switchIndex retries:(int)retries showMessagesOnError:(BOOL)showMessagesOnError
{
    // Close any connections to switch that are active
    if([self switch_socket] > 0)
        close([self switch_socket]);
    [self setSwitch_socket:0];
    [self setActive_switch_index:-1];
    // Get name of switch
    [[self switchDataLock] lock];
    NSString *switchName = (NSString*)CFArrayGetValueAtIndex([self switchNameArray], switchIndex);
    char mystring[1024];
    [switchName getCString:mystring maxLength:1024 encoding:[NSString defaultCStringEncoding]];
    NSString *ipAddr;
    if(!CFDictionaryGetValueIfPresent([self switchNameDictionary], switchName, (const void **) &ipAddr)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Select error!" message:@"Dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        [message release];
        [[self switchDataLock] unlock];
        return;
    }
    [[self switchDataLock] unlock];
    // Networking stuff to set up connection
    // Connect first with TCP, regardless of what protocol we'll use in the end
    int server_socket = 0, socket_flags = 0;
    while((!server_socket) && (retries-- >= 0)) {
        server_socket = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
        if(server_socket < 0) {
            if(retries >= 0) {
                NSLog(@"Retrying socket open");
                continue;
            }
            if(showMessagesOnError) {
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Socket error!"  
                                                                  message:@"Failed to open socket."  
                                                                 delegate:nil  
                                                        cancelButtonTitle:@"OK"  
                                                        otherButtonTitles:nil];  
                [message show];  
                [message release];
            }
            return;
        }
        char on = 1;
        setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));
        // Set timeout on all operations to 1 second
        struct timeval tv;
        tv.tv_sec = 1;
        tv.tv_usec = 0;
        setsockopt(server_socket, SOL_SOCKET, SO_SNDTIMEO, (void *)&tv, sizeof(tv));
        setsockopt(server_socket, SOL_SOCKET, SO_RCVTIMEO, (void *)&tv, sizeof(tv));
        char ip_addr_string[2*INET6_ADDRSTRLEN];
        [ipAddr getCString:ip_addr_string maxLength:sizeof(ip_addr_string) encoding:[NSString defaultCStringEncoding]];
        struct hostent *host = gethostbyname(ip_addr_string);
        if(!host) {
            if(retries >= 0) {
                NSLog(@"Retrying hostname not found");
                continue;
            }
            close(server_socket);
            if(showMessagesOnError) {
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Socket error!"  
                                                                  message:@"Hostname not found."  
                                                                 delegate:nil  
                                                        cancelButtonTitle:@"OK"  
                                                        otherButtonTitles:nil];  
                [message show];  
                [message release];
            }
            return;
        }
        struct sockaddr_in sin;
        memcpy(&sin.sin_addr.s_addr, host->h_addr, host->h_length);
        sin.sin_family = AF_INET;
        sin.sin_port = htons(portno);
        // Save udp address in case we use UDP
        memcpy(&udp_socket_address, &sin, sizeof(udp_socket_address));
        socket_flags = fcntl(server_socket, F_GETFL);
        socket_flags |= O_NONBLOCK;
        fcntl(server_socket, F_SETFL, socket_flags);
        if(connect(server_socket, (struct sockaddr *) &sin, sizeof(sin)) < 0) {
            struct pollfd socket_poll;
            socket_poll.fd = server_socket;
            socket_poll.events = POLLOUT;
            int poll_ret = poll(&socket_poll, 1, 1000);
            if(poll_ret <= 0) {
                close(server_socket);
                if(retries >= 0) {
                    NSLog(@"Retrying socket connect");
                    continue;
                }
                if(showMessagesOnError) {
                    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Socket error!"  
                                                                      message:@"Failed to connect."  
                                                                     delegate:nil  
                                                            cancelButtonTitle:@"OK"  
                                                            otherButtonTitles:nil];
                    [message show];  
                    [message release];
                }
                close(server_socket);
                return;
            }
        }
    }
    // We now have a TCP connection. If we want to use UDP, close the socket and reopen it as UDP
    if(IPPROTO_UDP == switchamajig_protocol) {
        close(server_socket);
        server_socket = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
        char on = 1;
        setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));
        // Set timeout on all operations to 1 second
        struct timeval tv;
        tv.tv_sec = 1;
        tv.tv_usec = 0;
        setsockopt(server_socket, SOL_SOCKET, SO_SNDTIMEO, (void *)&tv, sizeof(tv));
    }
    socket_flags &= ~O_NONBLOCK;
    fcntl(server_socket, F_SETFL, socket_flags);
    // Prevent signals; we'll handle error messages instead
    int on;
    setsockopt(server_socket, SOL_SOCKET, SO_NOSIGPIPE, &on, sizeof(on));

    if(switchamajig_protocol == IPPROTO_TCP)
        verify_socket_reply(server_socket, "*HELLO*"); // Accept the response if we get it, but don't require it
    [self setSwitch_socket:server_socket];
    //  Save active switch index
    [self setActive_switch_index:switchIndex];
    // Turn off all switches
    switch_state = 0;
    [self sendSwitchState];

    // Write the switch name and hostname to a temporary file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    NSString *filename = [cacheDirectory stringByAppendingString:@"lastswitchinfo.txt"];
    NSString *twoNames = [switchName stringByAppendingFormat:@":%@", ipAddr];
    [twoNames writeToFile:filename atomically:NO encoding:NSUTF8StringEncoding error:nil];
    return;
}


@end
