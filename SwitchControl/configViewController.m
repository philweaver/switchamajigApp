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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
#if 0    
    if (self) {
        // Custom initialization
        [self setUIColors];
    }
#endif
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

- (void)viewDidUnload
{
    [self setConfigTitle:nil];
    [self setConfigAppLabel:nil];
    [self setBackgroundColorLabel:nil];
    [self setConfigureNetworkLabel:nil];
    [self setScanActivityIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc {
    [ConfigTitle release];
    [ConfigAppLabel release];
    [BackgroundColorLabel release];
    [ConfigureNetworkLabel release];
    [ScanActivityIndicator release];
    [super dealloc];
}
@end
