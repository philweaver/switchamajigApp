//
//  configViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 1/4/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "configViewController.h"
#import "SwitchControlAppDelegate.h"
@implementation configViewController
@synthesize ConfigTitle;
@synthesize ConfigAppLabel;
@synthesize BackgroundColorLabel;
@synthesize ConfigureNetworkLabel;
@synthesize ScanActivityIndicator;
@synthesize wifiNameTable;

- (void)dealloc {
    [ConfigTitle release];
    [ConfigAppLabel release];
    [BackgroundColorLabel release];
    [ConfigureNetworkLabel release];
    [ScanActivityIndicator release];
    [wifiNameTable release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [self setConfigTitle:nil];
    [self setConfigAppLabel:nil];
    [self setBackgroundColorLabel:nil];
    [self setConfigureNetworkLabel:nil];
    [self setScanActivityIndicator:nil];
    [self setWifiNameTable:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
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
    [ConfigTitle setText:[@"Configure " stringByAppendingString:switchName]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wifi_list_updated:) name:@"wifi_list_was_updated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wifi_list_complete:) name:@"wifi_list_complete" object:nil];
    [appDelegate performSelectorInBackground:@selector(Background_Thread_To_Detect_Wifi) withObject:nil];
    [ScanActivityIndicator startAnimating];
#if 0
    [self setUIColors];
    // Require the user to prove that configuration is intentional
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Confirm Config"  
                                                      message:@"To prevent unintentional configuring, please type \'yes\' below to continue."  
                                                     delegate:self  
                                            cancelButtonTitle:@"Cancel"  
                                            otherButtonTitles:@"Continue",nil];
    [message setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [message show];  
    [message release];
#endif
}
- (void)alertView:(UIAlertView *) alertView didDismissWithButtonIndex:(NSInteger) buttonIndex
{
    if(buttonIndex == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    NSString *configEnableText = [[alertView textFieldAtIndex:0] text];
    if([configEnableText length] && [configEnableText caseInsensitiveCompare:@"yes"] == NSOrderedSame) {
        return YES;
    }
    return NO;
}
- (IBAction)Cancel:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void) wifi_list_updated:(NSNotification *) notification {
    [self performSelectorOnMainThread:@selector(reload_wifi_list_table) withObject:nil waitUntilDone:NO];
}
- (void) reload_wifi_list_table {
    [[appDelegate wifiDataLock] lock];
    [wifiNameTable reloadData];
    if(CFArrayGetCount([appDelegate wifiNameArray])) {
        [ConfigureNetworkLabel setText:@"Choose A Network"];
        [ScanActivityIndicator stopAnimating];
    } else {
        [ConfigureNetworkLabel setText:@"Searching For WiFi Networks"];
        [ScanActivityIndicator startAnimating];
    }
    [[appDelegate wifiDataLock] unlock];
}
- (void) wifi_list_complete:(NSNotification *) notification {
    [self performSelectorOnMainThread:@selector(wifi_list_complete_main) withObject:nil waitUntilDone:NO];
}
- (void) wifi_list_complete_main {
    [ScanActivityIndicator stopAnimating];
    [ScanActivityIndicator setHidesWhenStopped:YES];
    [ConfigureNetworkLabel setText:@"Choose a Network Below to Move Switchamajig to a New Network"];
}

// Code to support table displaying the names of the switches discovered during detect
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return CFArrayGetCount([appDelegate wifiNameArray]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"] autorelease];
    }
    cell.textLabel.text = [NSString stringWithString:(NSString*)CFArrayGetValueAtIndex([appDelegate wifiNameArray], indexPath.row)];
    return cell;
}

// Support for connecting to a switch when its name is selected from the table
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
}

@end
