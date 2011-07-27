//
//  SwitchControlAppDelegate.m
//  SwitchControl
//
//  Created by Phil Weaver on 7/23/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import "SwitchControlAppDelegate.h"
#import "singleSwitchView.h"
#import "twoSwitchView.h"
#import "sys/socket.h"
#import "netinet/in.h"
#import "netdb.h"

@implementation SwitchControlAppDelegate
char hostname[] = "172.16.1.42";
int portno = 2000;

@synthesize window = _window;
@synthesize singleSwitchViewController = _singleSwitchViewController;
@synthesize twoSwitchViewController = _twoSwitchViewController;

bool verify_socket_reply(int socket, const char *expected_string);
bool verify_socket_reply(int socket, const char *expected_string) {
    int expected_len = strlen(expected_string);
    char *buffer = malloc(expected_len);
    if(!buffer)
        return false;
    int total_bytes_read = 0;
    while(total_bytes_read < expected_len) {
        int bytes_read = read(socket, buffer+total_bytes_read, expected_len - total_bytes_read);
        if(!bytes_read) {
            sleep(1);
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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    singleSwitchView *aViewController = [[singleSwitchView alloc] initWithNibName:@"singleSwitchView" bundle:nil];
    [self setSingleSwitchViewController:aViewController];
    [aViewController release];
    twoSwitchView *a2ViewController = [[twoSwitchView alloc] initWithNibName:@"twoSwitchView" bundle:nil];
    [self setTwoSwitchViewController:a2ViewController];
    [a2ViewController release];
    [[self window] setRootViewController: [self singleSwitchViewController]];
    [self.window makeKeyAndVisible];
    
    // Initialize connection with remote switch
    int server_socket;
    server_socket = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);
    if(server_socket < 0) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Socket error!"  
                                                message:@"Failed to open socket."  
                                                delegate:nil  
                                                cancelButtonTitle:@"OK"  
                                                otherButtonTitles:nil];  
        [message show];  
        [message release];  
    }
    char on = 1;
    setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));
    struct hostent *host = gethostbyname(hostname);
    struct sockaddr_in sin;
    memcpy(&sin.sin_addr.s_addr, host->h_addr, host->h_length);
    sin.sin_family = AF_INET;
    sin.sin_port = htons(portno);
    if(connect(server_socket, (struct sockaddr *) &sin, sizeof(sin)) < 0) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Socket error!"  
                                                          message:@"Failed to connect."  
                                                         delegate:nil  
                                                cancelButtonTitle:@"OK"  
                                                otherButtonTitles:nil];  
        [message show];  
        [message release];
    }
    if(!verify_socket_reply(server_socket, "*HELLO*")) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Socket error!"  
                                                          message:@"Did Not Receive hello."  
                                                         delegate:nil  
                                                cancelButtonTitle:@"OK"  
                                                otherButtonTitles:nil];  
        [message show];  
        [message release];
        
    }
    write(server_socket, "$$$", 3);
    if(!verify_socket_reply(server_socket, "CMD")) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Socket error!"  
                                                          message:@"Did Not Receive cmd."  
                                                         delegate:nil  
                                                cancelButtonTitle:@"OK"  
                                                otherButtonTitles:nil];  
        [message show];  
        [message release];
        
    }
    write(server_socket, "\r", 1);
    sleep(1);
    write(server_socket, "set sys output 0\r", strlen("set sys output 0\r"));
    sleep(1);
    
    [[self singleSwitchViewController] setServer_socket:server_socket];
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
    [_singleSwitchViewController release];
    [_window release];
    [super dealloc];
}

@end
