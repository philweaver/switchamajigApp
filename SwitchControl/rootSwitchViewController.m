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
@implementation rootSwitchViewController
@synthesize server_socket;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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

- (IBAction)launchOneSwitch:(id)sender {
    singleSwitchView *newView = [[singleSwitchView alloc] initWithNibName:@"singleSwitchView" bundle:nil];
    [newView setServer_socket:[self server_socket]];
    [self.navigationController pushViewController:newView animated:YES];
    [newView release];
}

- (IBAction)launchTwoSwitch:(id)sender {
    twoSwitchView *newView = [[twoSwitchView alloc] initWithNibName:@"twoSwitchView" bundle:nil];
    [newView setServer_socket:[self server_socket]];
    [self.navigationController pushViewController:newView animated:YES];
    [newView release];
}

- (IBAction)launchFourAcrossSwitch:(id)sender {
    fourSwitchAcrossView *newView = [[fourSwitchAcrossView alloc] initWithNibName:@"fourSwitchAcrossView" bundle:nil];
    [newView setServer_socket:[self server_socket]];
    [self.navigationController pushViewController:newView animated:YES];
    [newView release];
}
@end
