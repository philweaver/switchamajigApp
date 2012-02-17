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
@synthesize ConfigureNetworkLabel;
@synthesize ScanActivityIndicator;
@synthesize wifiNameTable;
@synthesize wifiDataLock = _wifiDataLock;
@synthesize wifiNameArray = _wifiNameArray;
@synthesize CancelButton;
@synthesize datePicker;
@synthesize SwitchamajigNameText;
@synthesize NetworkNameText;
@synthesize ConfigureNetworkButton;
@synthesize wifiNameDictionary = _wifiNameDictionary;

- (void)dealloc {
    [ConfigureNetworkLabel release];
    [ScanActivityIndicator release];
    [wifiNameTable release];
    [CancelButton release];
    [datePicker release];
    [SwitchamajigNameText release];
    [NetworkNameText release];
    [ConfigureNetworkButton release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [self setConfigureNetworkLabel:nil];
    [self setScanActivityIndicator:nil];
    [self setWifiNameTable:nil];
    [_wifiDataLock release];
    CFRelease([self wifiNameDictionary]);
    CFRelease([self wifiNameArray]);

    [self setCancelButton:nil];
    [self setDatePicker:nil];
    [self setSwitchamajigNameText:nil];
    [self setNetworkNameText:nil];
    [self setConfigureNetworkButton:nil];
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
    nowEnteringPassphrase = NO;
    nowConfirmingConfig = NO;
    [self setWifiDataLock:[[NSLock alloc] init]];
    [self setWifiNameDictionary:CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks)];
    [self setWifiNameArray:CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks)];

    [SwitchamajigNameText setText:switchName];
    [ConfigureNetworkButton setEnabled:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wifi_list_updated:) name:@"wifi_list_was_updated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wifi_list_complete:) name:@"wifi_list_complete" object:nil];
    // Open TCP socket
    if(![appDelegate switch_socket] || ([appDelegate switch_connection_protocol] != IPPROTO_TCP)) {
        [appDelegate connect_to_switch:[appDelegate active_switch_index] protocol:IPPROTO_TCP retries:5 showMessagesOnError:NO];
        if(![appDelegate switch_socket]) {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Config Error"  
                                                              message:@"Unable to configure Switchamajig (connect)."  
                                                             delegate:self  
                                                    cancelButtonTitle:@"OK"  
                                                    otherButtonTitles:nil];
            [message show];  
            [message release];
            [self performSelectorOnMainThread:@selector(Cancel:) withObject:nil waitUntilDone:NO];
            return;
        }
    }
//    [self performSelectorInBackground:@selector(Background_Thread_To_Detect_Wifi) withObject:nil];
//    [ScanActivityIndicator startAnimating];
}

- (void)alertView:(UIAlertView *) alertView didDismissWithButtonIndex:(NSInteger) buttonIndex
{
    // Button index 0 is always cancel
    if(buttonIndex == 0) {
        nowEnteringPassphrase = NO;
        nowConfirmingConfig = NO;
        [self performSelectorOnMainThread:@selector(Cancel:) withObject:nil waitUntilDone:NO];
        return;
    }
    if(nowEnteringPassphrase) {
        // Save away passphrase
        strncpy(availableNetworks[networkIndex].passphrase, [[[alertView textFieldAtIndex:0] text] cStringUsingEncoding:NSUTF8StringEncoding], sizeof(availableNetworks[networkIndex].passphrase));
        // Require the user to prove that configuration is intentional
        NSString *passphraseRequest = @"Selecting network ";
        NSString *messageText = [passphraseRequest stringByAppendingString:networkName];
        nowEnteringPassphrase = NO;
        nowConfirmingConfig = YES;
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:messageText  
                                                          message:@"Controller will now attempt to move from its current network to the new one. If it fails, it will set up a \'Switchamajig\' network. The iPad must be on the same network in order to communicate with the Controller. Please type \'yes\' below to continue."  
                                                         delegate:self  
                                                cancelButtonTitle:@"Cancel"  
                                                otherButtonTitles:@"Continue",nil];
        [message setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [message show];  
        [message release];
        return;
    }
    if(nowConfirmingConfig) {
        bool status = switchamajig1_set_netinfo([appDelegate switch_socket], &availableNetworks[networkIndex]);
        if(status)
            status = switchamajig1_save([appDelegate switch_socket]);
        if(status)
            status = switchamajig1_exit_command_mode([appDelegate switch_socket]);
        if(status)
            status = switchamajig1_write_eeprom([appDelegate switch_socket], 0, 0);
        if(status)
            status = switchamajig1_reset([appDelegate switch_socket]);

        if(!status) {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Config error!"  
                                                              message:@"Failed to set new network name."  
                                                             delegate:self  
                                                    cancelButtonTitle:@"OK"  
                                                    otherButtonTitles:nil];
            [message show];  
            [message release];
        }
        nowConfirmingConfig = NO;
    }
}

// Only disable continue button when confirming that configuration is intentional
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView {
    if(nowConfirmingConfig) {
        NSString *configEnableText = [[alertView textFieldAtIndex:0] text];
        if([configEnableText length] && [configEnableText caseInsensitiveCompare:@"yes"] == NSOrderedSame) {
            return YES;
        }
        return NO;
    }
    return YES;
}

- (IBAction)Cancel:(id)sender {
    // We may have changed the name or network settings of this device, so close our connection to it and
    // clear our information about switches from our dictionary
    [[appDelegate switchDataLock] lock];
    CFDictionaryRemoveAllValues([appDelegate switchNameDictionary]);
    CFArrayRemoveAllValues([appDelegate switchNameArray]);
    [appDelegate setActive_switch_index:-1];
    if([appDelegate switch_socket]) {
        close([appDelegate switch_socket]);
        [appDelegate setSwitch_socket:0];
    }
    [[appDelegate switchDataLock] unlock];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"switch_list_was_updated" object:nil];
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
    [[self wifiDataLock] lock];
    [wifiNameTable reloadData];
    if(CFArrayGetCount([self wifiNameArray])) {
        [ConfigureNetworkLabel setText:@"Choose A Network"];
        [ScanActivityIndicator stopAnimating];
    } else {
        [ConfigureNetworkLabel setText:@"Searching For WiFi Networks"];
        [ScanActivityIndicator startAnimating];
    }
    [[self wifiDataLock] unlock];
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
    return CFArrayGetCount([self wifiNameArray]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"] autorelease];
    }
    cell.textLabel.text = [NSString stringWithString:(NSString*)CFArrayGetValueAtIndex([self wifiNameArray], indexPath.row)];
    return cell;
}

// Support for connecting to a switch when its name is selected from the table
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[self wifiDataLock] lock];
    networkName = (NSString*)CFArrayGetValueAtIndex([self wifiNameArray], indexPath.row);
    NSNumber *wifiIndex;
    if(!CFDictionaryGetValueIfPresent([self wifiNameDictionary], networkName, (const void **) &wifiIndex)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Select error!" message:@"Dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        [message release];
        [[self wifiDataLock] unlock];
        return;
    }
    [[self wifiDataLock] unlock];
    // Range-check networkIndex
    networkIndex = [wifiIndex intValue];
    if((networkIndex < 0) || (networkIndex >= num_avail_wifi)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"App error!"  
                                                          message:@"NetworkIndex out of range (code bug)."  
                                                         delegate:[[self navigationController] visibleViewController]  
                                                cancelButtonTitle:@"OK"  
                                                otherButtonTitles:nil];
        [message show];  
        [message release];
        return;
    }
    // Handle standard selection
    NSString *passphraseRequest = @"Please enter the network passphrase (if any) for network ";
    NSString *messageText = [passphraseRequest stringByAppendingString:networkName];

    if(networkIndex >= 0) {
        nowEnteringPassphrase = YES;
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Network Passphrase"  
                                                          message:messageText  
                                                         delegate:self  
                                                cancelButtonTitle:@"Cancel"  
                                                otherButtonTitles:@"Continue",nil];
        [message setAlertViewStyle:UIAlertViewStyleSecureTextInput];
        [message show];  
        [message release];
    }
}

// Provide options for walking in 
- (void)Background_Thread_To_Detect_Wifi {
    NSAutoreleasePool *mempool = [[NSAutoreleasePool alloc] init];
    [[self CancelButton] setEnabled:NO];
    [[self wifiDataLock] lock];
    CFDictionaryRemoveAllValues([self wifiNameDictionary]);    
    CFArrayRemoveAllValues([self wifiNameArray]);
    [[self wifiDataLock] unlock];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"wifi_list_was_updated" object:nil];
    
    if(!switchamajig1_enter_command_mode([appDelegate switch_socket])) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Config Error"  
                                                          message:@"Unable to configure Switchamajig (cmd)"  
                                                         delegate:self  
                                                cancelButtonTitle:@"OK"  
                                                otherButtonTitles:nil];
        [message show];  
        [message release];
        [[self CancelButton] setEnabled:YES];  
        [mempool release];
        return;
    }
    sleep(2);
    if(!switchamajig1_scan_wifi([appDelegate switch_socket], &num_avail_wifi, availableNetworks, MAX_AVAIL_NETWORKS)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Config error!"  
                                                          message:@"Find any wifi networks (scan)."  
                                                         delegate:self  
                                                cancelButtonTitle:@"OK"  
                                                otherButtonTitles:nil];
        [message show];  
        [message release];
        [[self CancelButton] setEnabled:YES];  
        [mempool release];
        return;
    }
    [[self wifiDataLock] lock];
    // Not supporting manually entering networks
    //CFArrayAppendValue([self wifiNameArray], @"Manually Enter Network");
    //NSNumber *ManualEntryIndex = [NSNumber numberWithInt:-1];
    //CFDictionaryAddValue([self wifiNameDictionary], (NSString *) CFArrayGetValueAtIndex([self wifiNameArray], 0), ManualEntryIndex);
    for(int i=0; i < num_avail_wifi; ++i) {
        NSString *networkName1 = [NSString stringWithCString:availableNetworks[i].ssid encoding:NSUTF8StringEncoding];
        CFArrayAppendValue([self wifiNameArray], networkName1);
        NSNumber *wifiNetIndex = [NSNumber numberWithInt:i];
        CFDictionaryAddValue([self wifiNameDictionary], networkName1, wifiNetIndex);
    }
    [[self wifiDataLock] unlock];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"wifi_list_was_updated" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"wifi_list_complete" object:nil];
    [[self CancelButton] setEnabled:YES];  
    [mempool release];
    return;
}

// Picker support
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 1;
}
#define NUM_WIFI_CHANNELS 13
- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component {
    return NUM_WIFI_CHANNELS;
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    NSString *myString = [NSString stringWithFormat:@"%ld",(long)row+1];
    return myString;
}


// Select a new switch name
- (IBAction)ChangeName:(id)sender {
    // Replace spaces with dollar signs
    NSString *nameWithDollars = [[SwitchamajigNameText text] stringByReplacingOccurrencesOfString:@" " withString:@"$"];
    const char *newName = [nameWithDollars UTF8String];
    
    bool status = switchamajig1_enter_command_mode([appDelegate switch_socket]);
    if(status)
        status = switchamajig1_set_name([appDelegate switch_socket], newName);
    if(status)
        status = switchamajig1_save([appDelegate switch_socket]);
    if(!status) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Name Change Failed"  
                                                          message:@"Failed to change name."  
                                                         delegate:self  
                                                cancelButtonTitle:@"OK"  
                                                otherButtonTitles:nil];
        [message show];  
        [message release];
    }
    // Clear the last switch info file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDirectory = [paths objectAtIndex:0];
    NSString *filename = [cacheDirectory stringByAppendingString:@"lastswitchinfo.txt"];
    [[NSFileManager defaultManager] removeItemAtPath:filename error:nil];
    [self Cancel:nil];
}

- (IBAction)ChangeNetwork:(id)sender {
}

- (IBAction)NetworkNameChanged:(id)sender {
}

@end
