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
@synthesize ScanNetworkButton;
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
    [ScanNetworkButton release];
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
    [self setScanNetworkButton:nil];
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
    [ScanActivityIndicator stopAnimating];
    [ScanActivityIndicator setHidesWhenStopped:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wifi_list_updated:) name:@"wifi_list_was_updated" object:nil];
    // Open TCP socket
    if(![appDelegate switch_socket] || ([appDelegate current_switch_connection_protocol] != IPPROTO_TCP)) {
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
        nowEnteringPassphrase = NO;
        // Stuff the new network info
        struct switchamajig1_network_info newInfo;
        newInfo.channel = (int) [datePicker selectedRowInComponent:0] + 1;
        NSString *nameWithDollars = [[NetworkNameText text] stringByReplacingOccurrencesOfString:@" " withString:@"$"];
        strncpy(newInfo.ssid, [nameWithDollars UTF8String], sizeof(newInfo.ssid));
        NSString *phraseWithDollars = [[[alertView textFieldAtIndex:0] text] stringByReplacingOccurrencesOfString:@" " withString:@"$"];
        if(![phraseWithDollars length])
            strncpy(newInfo.passphrase, "none", sizeof(newInfo.passphrase));
        else
            strncpy(newInfo.passphrase, [phraseWithDollars cStringUsingEncoding:NSUTF8StringEncoding], sizeof(newInfo.passphrase));
#if 0
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
        nowConfirmingConfig = NO;
#endif
        bool status = switchamajig1_enter_command_mode([appDelegate switch_socket]);
        if(status)
            status = switchamajig1_set_netinfo([appDelegate switch_socket], &newInfo);
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
        [self performSelectorOnMainThread:@selector(Cancel:) withObject:nil waitUntilDone:NO];
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
    } else {
        [ConfigureNetworkLabel setText:@"Re-scan For Networks"];
    }
    [[self wifiDataLock] unlock];
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
    NSString *networkName = (NSString*)CFArrayGetValueAtIndex([self wifiNameArray], indexPath.row);
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
    int networkIndex = [wifiIndex intValue];
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
    [NetworkNameText setText:networkName];
    [datePicker selectRow:(availableNetworks[networkIndex].channel - 1) inComponent:0 animated:YES];
    [ConfigureNetworkButton setEnabled:YES];
}

// Provide options for walking in 
- (void)Background_Thread_To_Detect_Wifi {
    NSAutoreleasePool *mempool = [[NSAutoreleasePool alloc] init];
    [[self wifiDataLock] lock];
    CFDictionaryRemoveAllValues([self wifiNameDictionary]);    
    CFArrayRemoveAllValues([self wifiNameArray]);
    [[self wifiDataLock] unlock];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"wifi_list_was_updated" object:nil];
    
    if(!switchamajig1_enter_command_mode([appDelegate switch_socket])) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Config Error"  
                                                          message:@"Unable to configure Switchamajig (cmd)"  
                                                         delegate:nil  
                                                cancelButtonTitle:@"OK"  
                                                otherButtonTitles:nil];
        [message show];  
        [message release];
    } else {
        sleep(2);
        if(!switchamajig1_scan_wifi([appDelegate switch_socket], &num_avail_wifi, availableNetworks, MAX_AVAIL_NETWORKS)) {
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Config error!"  
                                                              message:@"Found no wifi networks (scan)."  
                                                             delegate:nil  
                                                    cancelButtonTitle:@"OK"  
                                                    otherButtonTitles:nil];
            [message show];  
            [message release];
        } else if(!strcmp(availableNetworks[0].ssid, "Ch")) {
            // Mysterious failure when reply from controller is garbled
            UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Config error!"  
                                                              message:@"Found no wifi networks (Ch)."  
                                                             delegate:nil  
                                                    cancelButtonTitle:@"OK"  
                                                    otherButtonTitles:nil];
            [message show];  
            [message release];
            num_avail_wifi = 0;
        }
    }
    [[self wifiDataLock] lock];
    for(int i=0; i < num_avail_wifi; ++i) {
        NSString *networkName1 = [NSString stringWithCString:availableNetworks[i].ssid encoding:NSUTF8StringEncoding];
        CFArrayAppendValue([self wifiNameArray], networkName1);
        NSNumber *wifiNetIndex = [NSNumber numberWithInt:i];
        CFDictionaryAddValue([self wifiNameDictionary], networkName1, wifiNetIndex);
    }
    [[self wifiDataLock] unlock];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"wifi_list_was_updated" object:nil];
    [[self ScanNetworkButton] setEnabled:YES];  
    [[self CancelButton] setEnabled:YES];
    [[self ScanNetworkButton] setTitle:@"Re-scan for Networks" forState:UIControlStateNormal];
    [[self ScanActivityIndicator] stopAnimating];
    [SwitchamajigNameText setEnabled:NO];
    [NetworkNameText setEnabled:NO];
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
    [self performSelectorOnMainThread:@selector(Cancel:) withObject:nil waitUntilDone:NO];
}

- (IBAction)ChangeNetwork:(id)sender {
    // Replace spaces with dollar signs
    NSString *newNetworkName = [NetworkNameText text];
    // Ask user for passphrase
    NSString *passphraseRequest = @"Enter the network passphrase (if any) for ";
    NSString *messageText = [passphraseRequest stringByAppendingString:newNetworkName];
    nowEnteringPassphrase = YES;
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Network Passphrase"  
                                                      message:messageText  
                                                     delegate:self  
                                            cancelButtonTitle:@"Cancel"  
                                            otherButtonTitles:@"Choose Network",nil];
    [message setAlertViewStyle:UIAlertViewStyleSecureTextInput];
    [message show];  
    [message release];
}

- (IBAction)NetworkNameChanged:(id)sender {
    if([[NetworkNameText text] length])
        [ConfigureNetworkButton setEnabled:YES];
    else
        [ConfigureNetworkButton setEnabled:NO];
}

- (IBAction)ScanForNetworks:(id)sender {
    [ScanNetworkButton setTitle:@"Scanning" forState:UIControlStateNormal];
    [ScanNetworkButton setEnabled:NO];
    [CancelButton setEnabled:NO];
    [NetworkNameText setText:@""];
    [ConfigureNetworkLabel setEnabled:NO];
    [SwitchamajigNameText setEnabled:NO];
    [NetworkNameText setEnabled:NO];
    [self performSelectorInBackground:@selector(Background_Thread_To_Detect_Wifi) withObject:nil];
    [ScanActivityIndicator startAnimating];
}

@end
