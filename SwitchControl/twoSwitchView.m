//
//  twoSwitchView.m
//  SwitchControl
//
//  Created by Phil Weaver on 7/25/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import "twoSwitchView.h"

@implementation twoSwitchView

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        switch_state = 0;
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
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#define MAX_STRING 1024
- (IBAction)activate1:(id)sender {
    switch_state |= 0x20;
    char string[MAX_STRING];
    sprintf(string, "set sys output 0x%04x\r", switch_state);
    write([self server_socket], string, strlen(string));
}

- (IBAction)deactivate1:(id)sender {
    switch_state &= ~0x20;
    char string[MAX_STRING];
    sprintf(string, "set sys output 0x%04x\r", switch_state);
    write([self server_socket], string, strlen(string));
}

- (IBAction)activate2:(id)sender {
    switch_state |= 0x40;
    char string[MAX_STRING];
    sprintf(string, "set sys output 0x%04x\r", switch_state);
    write([self server_socket], string, strlen(string));
}

- (IBAction)deactivate2:(id)sender {
    switch_state &= ~0x40;
    char string[MAX_STRING];
    sprintf(string, "set sys output 0x%04x\r", switch_state);
    write([self server_socket], string, strlen(string));
}
@synthesize server_socket;

@end
