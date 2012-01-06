//
//  configViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 1/4/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "configViewController.h"

@implementation configViewController
@synthesize ConfigTitle;
@synthesize ConfigAppLabel;
@synthesize BackgroundColorLabel;

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
    // Require the user to prove that configuration is intentional
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Confirm Config"  
                                                      message:@"To prevent unintentional configuring, please type \'yes\' below to continue."  
                                                     delegate:self  
                                            cancelButtonTitle:@"Cancel"  
                                            otherButtonTitles:@"Continue",nil];
    [message setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [message show];  
    [message release];
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
- (IBAction)setBackgroundWhite:(id)sender {
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.BackgroundColorLabel setTextColor:[UIColor blackColor]];

}
- (IBAction)setBackgroundBlack:(id)sender {
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.BackgroundColorLabel setTextColor:[UIColor whiteColor]];
    
}

- (void)viewDidUnload
{
    [self setConfigTitle:nil];
    [self setConfigAppLabel:nil];
    [self setBackgroundColorLabel:nil];
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
    [super dealloc];
}
@end
