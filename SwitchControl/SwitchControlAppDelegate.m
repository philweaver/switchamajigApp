//
//  SwitchControlAppDelegate.m
//  SwitchControl
//
//  Created by Phil Weaver on 7/23/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import "SwitchControlAppDelegate.h"
#import "rootSwitchViewController.h"
#import "sys/socket.h"
#import "netinet/in.h"
#import "netdb.h"
#include "sys/unistd.h"
#include "sys/fcntl.h"
#include "sys/poll.h"
#include "arpa/inet.h"
#include "errno.h"
#include "Reachability.h"

@implementation SwitchControlAppDelegate

@synthesize window = _window;
@synthesize navigationController = _navigationController;
@synthesize switchDataLock = _switchDataLock;
@synthesize switchNameDictionary = _switchNameDictionary;
@synthesize switchNameArray = _switchNameArray;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    // Check if we have network access
    Reachability *r = [Reachability reachabilityForLocalWiFi];
    NetworkStatus internetStatus = [r currentReachabilityStatus];
    if(internetStatus == NotReachable) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"No WiFi Connection."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        [message release];
        
    }
    
    // Initialize the root view controller
    rootSwitchViewController *rootController = [[rootSwitchViewController alloc] initWithNibName:@"rootSwitchViewController" bundle:nil];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:rootController];
    [self setNavigationController:navController];
    [navController release];
    [[self window] setRootViewController: [self navigationController]];
    [self.window makeKeyAndVisible];    
    [rootController release];
    // Initialize the list of switches and the lock that keeps it threadsafe
    [self setSwitchDataLock:[[NSLock alloc] init]];
    [self setSwitchNameDictionary:CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks)];
    [self setSwitchNameArray:CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks)];
    // Start the background thread that listens for switches
    [self performSelectorInBackground:@selector(Background_Thread_To_Detect_Switches) withObject:nil];

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
    [_navigationController release];
    [_window release];
    [_switchDataLock release];
    CFRelease([self switchNameDictionary]);
    CFRelease([self switchNameDictionary]);
    [super dealloc];
}

// Detect switches in area
#define EXPECTED_PACKET_SIZE 110
#define DEVICE_STRING_OFFSET 60

- (void)Background_Thread_To_Detect_Switches {
    NSAutoreleasePool *mempool = [[NSAutoreleasePool alloc] init];
    CFDictionaryRemoveAllValues([self switchNameDictionary]);
    CFArrayRemoveAllValues([self switchNameArray]);
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

@end
