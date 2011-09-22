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
#import "switchPanelViewController.h"
#import "sys/socket.h"
#import "netinet/in.h"
#import "netdb.h"
#include "sys/unistd.h"
#include "sys/fcntl.h"
#include "sys/poll.h"
#include "arpa/inet.h"
#include "errno.h"

@implementation rootSwitchViewController
@synthesize chooseOneSwitchButton;
@synthesize chooseTwoSwitchButton;
@synthesize chooseFourAcrossButton;
@synthesize switchNameTableView;

- (void)dealloc {
    [chooseOneSwitchButton release];
    [chooseTwoSwitchButton release];
    [chooseFourAcrossButton release];
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
        appDelegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication]delegate];
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
    [self enable_switch_view_buttons];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switch_names_updated:) name:@"switch_list_was_updated" object:nil];
    active_switch_index = -1;
}
- (void)viewDidUnload
{
    [self setChooseOneSwitchButton:nil];
    [self setChooseTwoSwitchButton:nil];
    [self setChooseFourAcrossButton:nil];
    [self setSwitchNameTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight))
        return YES;
    return NO;
}
-(void) viewWillAppear:(BOOL)animated {
    [[self navigationController] setNavigationBarHidden:YES];
}

- (IBAction)launchOneSwitch:(id)sender {
#if 1
    // Load programatically-created view
    switchPanelViewController *viewController = [switchPanelViewController alloc];
    [viewController setFilename:@"singleSwitchPanel.xml"];
    [self.navigationController pushViewController:viewController animated:YES];
    [viewController release];
#else
    singleSwitchView *newView = [[singleSwitchView alloc] initWithNibName:@"singleSwitchView" bundle:nil];
    [newView setServer_socket:[appDelegate switch_socket]];
    [self.navigationController pushViewController:newView animated:YES];
    [newView release];
#endif
}

- (IBAction)launchTwoSwitch:(id)sender {
    twoSwitchView *newView = [[twoSwitchView alloc] initWithNibName:@"twoSwitchView" bundle:nil];
    [newView setServer_socket:[appDelegate switch_socket]];
    [self.navigationController pushViewController:newView animated:YES];
    [newView release];
}

- (IBAction)launchFourAcrossSwitch:(id)sender {
    fourSwitchAcrossView *newView = [[fourSwitchAcrossView alloc] initWithNibName:@"fourSwitchAcrossView" bundle:nil];
    [newView setServer_socket:[appDelegate switch_socket]];
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
        if(bytes_read < 0) {
            printf("%s\n", strerror(errno));
            return false;
        }
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

- (IBAction)detect:(id)sender {
    return;
}

- (void) switch_names_updated:(NSNotification *) notification {
    [self performSelectorOnMainThread:@selector(reload_switch_name_table) withObject:nil waitUntilDone:NO];
}
- (void) reload_switch_name_table {
    [[appDelegate switchDataLock] lock];
    [switchNameTableView reloadData];
    [[appDelegate switchDataLock] unlock];
}

// Code to support table displaying the names of the switches discovered during detect
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return CFDictionaryGetCount([appDelegate switchNameDictionary]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"] autorelease];
    }
    NSString *switchName = [NSString stringWithString:(NSString*)CFArrayGetValueAtIndex([appDelegate switchNameArray], indexPath.row)];
    cell.textLabel.text = switchName;
    if(indexPath.row == active_switch_index) {
        cell.detailTextLabel.text = [NSString stringWithCString:"Connected" encoding:NSASCIIStringEncoding];
    }
    return cell;
}

// Support for connecting to a swtich when its name is selected from the table
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *switchName = [NSString stringWithString:(NSString*)CFArrayGetValueAtIndex([appDelegate switchNameArray], indexPath.row)];
    char mystring[1024];
    [switchName getCString:mystring maxLength:1024 encoding:[NSString defaultCStringEncoding]];
    NSString *ipAddr;
    //ipAddr = CFDictionaryGetValue(switchNameDictionary, switchName);
    if(!CFDictionaryGetValueIfPresent([appDelegate switchNameDictionary], switchName, (const void **) &ipAddr)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Select error!" message:@"Dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        [message release];
        return;
    }
    char ip_addr_string[2*INET6_ADDRSTRLEN];
    [ipAddr getCString:ip_addr_string maxLength:sizeof(ip_addr_string) encoding:[NSString defaultCStringEncoding]];
    if([appDelegate switch_socket] >= 0)
        close([appDelegate switch_socket]);
    int switch_socket = connect_to_switch(ip_addr_string);
    [appDelegate setSwitch_socket:switch_socket];
    if([appDelegate switch_socket] < 0) {
        [self disable_switch_view_buttons];
        active_switch_index = -1;
    } else {
        [self enable_switch_view_buttons];
        active_switch_index = indexPath.row;
    }
    [self reload_switch_name_table];
}
@end
