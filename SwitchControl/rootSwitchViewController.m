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

@implementation rootSwitchViewController
@synthesize hostname_field;
@synthesize chooseOneSwitchButton;
@synthesize chooseTwoSwitchButton;
@synthesize chooseFourAcrossButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        server_socket = -1;
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
    [[self hostname_field] setText:[NSString stringWithCString:"172.16.1.42" encoding:NSASCIIStringEncoding]];
}

- (void)viewDidUnload
{
    [self setHostname_field:nil];
    [self setChooseOneSwitchButton:nil];
    [self setChooseTwoSwitchButton:nil];
    [self setChooseFourAcrossButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
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
    if(connect(server_socket, (struct sockaddr *) &sin, sizeof(sin)) < 0) {
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


- (IBAction)connect:(id)sender {
    char hname[1024];
    if(server_socket >= 0) {
        close(server_socket);
        server_socket = -1;
    }
    NSString *hname_content = self.hostname_field.text;
    if(![hname_content getCString:hname maxLength:sizeof(hname)-1 encoding:NSASCIIStringEncoding])
        return;
    server_socket = connect_to_switch(hname);
    if(server_socket < 0) {
        [self disable_switch_view_buttons];
    } else {
        [self enable_switch_view_buttons];
    }
    return;
}

- (void)dealloc {
    [hostname_field release];
    [chooseOneSwitchButton release];
    [chooseTwoSwitchButton release];
    [chooseFourAcrossButton release];
    [super dealloc];
}
@end
