//
//  rootSwitchViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 7/27/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import "rootSwitchViewController.h"
#import "singleSwitchView.h"
#import "twoSwitchView.h"
#import "fourSwitchAcrossView.h"
#import "sys/socket.h"
#import "netinet/in.h"
#import "netdb.h"
#include "sys/unistd.h"
#include "sys/fcntl.h"
#include "sys/poll.h"
#include "arpa/inet.h"

@implementation rootSwitchViewController
@synthesize chooseOneSwitchButton;
@synthesize chooseTwoSwitchButton;
@synthesize chooseFourAcrossButton;
@synthesize detectProgressBar;
@synthesize switchNameTableView;

- (void)dealloc {
    [chooseOneSwitchButton release];
    [chooseTwoSwitchButton release];
    [chooseFourAcrossButton release];
    [detectProgressBar release];
    [switchNameTableView release];
    switchNameTableView = nil;
    [switchNameTableView release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        server_socket = -1;
        switchNameDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        switchNameArray = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    // Make nav bar disappear
    [[self navigationController] setNavigationBarHidden:YES];
    [self disable_switch_view_buttons];
}

- (void)viewDidUnload
{
    [self setChooseOneSwitchButton:nil];
    [self setChooseTwoSwitchButton:nil];
    [self setChooseFourAcrossButton:nil];
    [self setDetectProgressBar:nil];
    [self setSwitchNameTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if(interfaceOrientation == UIInterfaceOrientationPortrait)
        return YES;
    return NO;
}
-(void) viewWillAppear:(BOOL)animated {
    [[UIDevice currentDevice] setOrientation : UIInterfaceOrientationPortrait];
}

- (IBAction)launchOneSwitch:(id)sender {
    singleSwitchView *newView = [[singleSwitchView alloc] initWithNibName:@"singleSwitchView" bundle:nil];
    [newView setServer_socket:server_socket];
    [self.navigationController pushViewController:newView animated:YES];
    [newView release];
}

- (IBAction)launchTwoSwitch:(id)sender {
    twoSwitchView *newView = [[twoSwitchView alloc] initWithNibName:@"twoSwitchView" bundle:nil];
    [newView setServer_socket:server_socket];
    [self.navigationController pushViewController:newView animated:YES];
    [newView release];
}

- (IBAction)launchFourAcrossSwitch:(id)sender {
    fourSwitchAcrossView *newView = [[fourSwitchAcrossView alloc] initWithNibName:@"fourSwitchAcrossView" bundle:nil];
    [newView setServer_socket:server_socket];
    [self.navigationController pushViewController:newView animated:YES];
    [newView release];
}
int portno = 2000;
bool verify_socket_reply(int socket, const char *expected_string);
bool verify_socket_reply(int socket, const char *expected_string) {
    int expected_len = strlen(expected_string);
    char *buffer = malloc(expected_len);
    if(!buffer)
        return false;
    int total_bytes_read = 0;
    while(total_bytes_read < expected_len) {
        int bytes_read = read(socket, buffer+total_bytes_read, expected_len - total_bytes_read);
        if(bytes_read < 0)
            return false;
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

// Initialize connection with remote switch
int connect_to_switch(char hostname[]);
int connect_to_switch(char hostname[])
{
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
        return server_socket;
    }
    char on = 1;
    setsockopt(server_socket, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));
    struct hostent *host = gethostbyname(hostname);
    if(!host) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Socket error!"  
                                                          message:@"Hostname not found."  
                                                         delegate:nil  
                                                cancelButtonTitle:@"OK"  
                                                otherButtonTitles:nil];  
        [message show];  
        [message release];
        close(server_socket);
        return -1;
    }
    struct sockaddr_in sin;
    memcpy(&sin.sin_addr.s_addr, host->h_addr, host->h_length);
    sin.sin_family = AF_INET;
    sin.sin_port = htons(portno);
    int socket_flags = fcntl(server_socket, F_GETFL);
    socket_flags |= O_NONBLOCK;
    fcntl(server_socket, F_SETFL, socket_flags);
    if(connect(server_socket, (struct sockaddr *) &sin, sizeof(sin)) < 0) {
        struct pollfd socket_poll;
        socket_poll.fd = server_socket;
        socket_poll.events = POLLOUT;
        int poll_ret = poll(&socket_poll, 1, 1000);
        if(poll_ret <= 0) {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Socket error!"  
                                                              message:@"Failed to connect."  
                                                             delegate:nil  
                                                    cancelButtonTitle:@"OK"  
                                                    otherButtonTitles:nil];  
            [message show];  
            [message release];
            close(server_socket);
            return -1;
        }
    }
    socket_flags &= ~O_NONBLOCK;
    fcntl(server_socket, F_SETFL, socket_flags);
    if(!verify_socket_reply(server_socket, "*HELLO*")) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Socket error!"  
                                                          message:@"Did Not Receive hello."  
                                                         delegate:nil  
                                                cancelButtonTitle:@"OK"  
                                                otherButtonTitles:nil];  
        [message show];  
        [message release];
        close(server_socket);
        return -1;
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
        close(server_socket);
        return -1;
    }
    write(server_socket, "\r", 1);
    sleep(1);
    write(server_socket, "set sys output 0\r", strlen("set sys output 0\r"));
    sleep(1);
    
    return server_socket;
}

-(void) disable_switch_view_buttons {
    [self.chooseOneSwitchButton setEnabled:NO];
    [self.chooseTwoSwitchButton setEnabled:NO];
    [self.chooseFourAcrossButton setEnabled:NO];
    return;
}

-(void) enable_switch_view_buttons {
    [self.chooseOneSwitchButton setEnabled:YES];
    [self.chooseTwoSwitchButton setEnabled:YES];
    [self.chooseFourAcrossButton setEnabled:YES];
    return;
}

// Detect switches in area
#define EXPECTED_PACKET_SIZE 110
#define DEVICE_STRING_OFFSET 60
#define SCAN_TIME_SECONDS 10.0
- (IBAction)detect:(id)sender {
    [self performSelectorInBackground:@selector(detect_switches) withObject:nil];
    return;
}

- (void)update_detect_progress {
    [detectProgressBar setProgress:detect_progress];
}

- (void) reload_switch_name_table {
    [switchNameTableView reloadData];
}
- (void)detect_switches {
    NSAutoreleasePool *mempool = [[NSAutoreleasePool alloc] init];
    CFDictionaryRemoveAllValues(switchNameDictionary);
    CFArrayRemoveAllValues(switchNameArray);
    detect_progress = 0.0;
    [self performSelectorOnMainThread:@selector(update_detect_progress) withObject:nil waitUntilDone:NO];
    int detect_socket;
    detect_socket = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if(socket < 0) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Detect error!" message:@"Error opening socked."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
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
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Detect error!" message:@"Error binding socked."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        [message release];
        close(detect_socket);
        [mempool release];
        return;
    }
    // Now loop and listen for switches
    id start = [NSDate date];
    char buffer[2*EXPECTED_PACKET_SIZE+1];
    printf("Starting loop.\n");
    struct timeval tv;
    fd_set readfds;
    tv.tv_sec = 10;
    tv.tv_usec = 250000;
    FD_ZERO(&readfds);
    FD_SET(detect_socket, &readfds);
    while([start timeIntervalSinceNow] > -SCAN_TIME_SECONDS) {
        struct sockaddr_storage switch_address;
        socklen_t addr_len = sizeof(switch_address);
        //  Use a non-blocking receive to see if anything arrived 
        int socket_flags = fcntl(server_socket, F_GETFL);
        socket_flags |= O_NONBLOCK;
        fcntl(server_socket, F_SETFL, socket_flags);
        int numbytes = recvfrom(detect_socket, buffer, 2*EXPECTED_PACKET_SIZE, MSG_PEEK | MSG_DONTWAIT, (struct sockaddr *) &switch_address, &addr_len);
        if((numbytes < 0) && (errno == EWOULDBLOCK))
            numbytes = 0;
        if(numbytes < 0) {
            printf("Error numbytes=%d\n", numbytes);
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Detect error!" message:@"Error checking for data."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
            [message show];  
            [message release];
            FD_ZERO(&readfds);
            close(detect_socket);
            [mempool release];
            return;
            
        }
        // Switch to blocking and receive any data that's available.
        socket_flags &= ~O_NONBLOCK;
        fcntl(server_socket, F_SETFL, socket_flags);
        numbytes = (numbytes) ? (recvfrom(detect_socket, buffer, EXPECTED_PACKET_SIZE, 0, (struct sockaddr *) &switch_address, &addr_len)) : 0;
        id currentTime = [NSDate date];
        detect_progress = [currentTime timeIntervalSinceDate:start] / SCAN_TIME_SECONDS;
        [self performSelectorOnMainThread:@selector(update_detect_progress) withObject:nil waitUntilDone:NO];

        if(numbytes < 0){
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Detect error!" message:@"Error on recvfrom."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
            [message show];  
            [message release];
            FD_ZERO(&readfds);
            close(detect_socket);
            [mempool release];
            return;
        }
        if(numbytes)
            printf("numbytes=%d\n", numbytes);
        if(numbytes != EXPECTED_PACKET_SIZE)
            continue;
        // Get the IP address in string format
        char ip_addr_string[INET6_ADDRSTRLEN];
        struct sockaddr *sockaddr_ptr = (struct sockaddr *) &switch_address;
        
        inet_ntop(switch_address.ss_family, (sockaddr_ptr->sa_family == AF_INET) ? (void*)&(((struct sockaddr_in *)sockaddr_ptr)->sin_addr) : (void*)&(((struct sockaddr_in6 *)sockaddr_ptr)->sin6_addr), ip_addr_string, sizeof(ip_addr_string));
        printf("Received: %s from %s\n", buffer+DEVICE_STRING_OFFSET, ip_addr_string);
        NSString *switchName = [NSString stringWithCString:buffer+DEVICE_STRING_OFFSET encoding:NSASCIIStringEncoding];
        NSString *ipAddrStr = [NSString stringWithCString:ip_addr_string encoding:NSASCIIStringEncoding];
        if(!CFDictionaryContainsKey((CFDictionaryRef) switchNameDictionary, switchName)) {
            CFArrayAppendValue(switchNameArray, switchName);
            CFDictionaryAddValue(switchNameDictionary, switchName, ipAddrStr);
        }
        
    }
    FD_ZERO(&readfds);
    printf("Loop complete.\n");
    close(detect_socket);
    [self performSelectorOnMainThread:@selector(reload_switch_name_table) withObject:nil waitUntilDone:NO];

    [mempool release];
    return;
}

// Code to support table displaying the names of the switches discovered during detect
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return CFDictionaryGetCount(switchNameDictionary);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"] autorelease];
    }
    NSString *switchName = [NSString stringWithString:(NSString*)CFArrayGetValueAtIndex(switchNameArray, indexPath.row)];
    cell.textLabel.text = switchName;
    return cell;
}

// Support for connecting to a swtich when its name is selected from the table
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *switchName = [NSString stringWithString:(NSString*)CFArrayGetValueAtIndex(switchNameArray, indexPath.row)];
    char mystring[1024];
    [switchName getCString:mystring maxLength:1024 encoding:[NSString defaultCStringEncoding]];
    printf("Selected %s\n", mystring);
    NSString *ipAddr;
    //ipAddr = CFDictionaryGetValue(switchNameDictionary, switchName);
    if(!CFDictionaryGetValueIfPresent(switchNameDictionary, switchName, (const void **) &ipAddr)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Select error!" message:@"Dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        [message release];
        return;
    }
    char ip_addr_string[2*INET6_ADDRSTRLEN];
    [ipAddr getCString:ip_addr_string maxLength:sizeof(ip_addr_string) encoding:[NSString defaultCStringEncoding]];
    printf("IP addr %s\n", ip_addr_string);
    server_socket = connect_to_switch(ip_addr_string);
    if(server_socket < 0) {
        [self disable_switch_view_buttons];
    } else {
        [self enable_switch_view_buttons];
    }

}
@end
