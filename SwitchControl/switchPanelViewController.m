//
//  switchPanelViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 9/9/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import "switchPanelViewController.h"
#import "stdio.h"
@implementation switchPanelViewController

@synthesize buttonToSwitchDictionary;

/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
    appDelegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication]delegate];
	CGRect cgRct = CGRectMake(0, 20, 1024, 748);
    UIView *myView = [[UIView alloc] initWithFrame:cgRct];
    [myView setBackgroundColor:[UIColor blackColor]];
	myView.autoresizesSubviews = YES;
    [self setButtonToSwitchDictionary:CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks)];
    
    // Create two-button combo to allow navigation
    id allowNavButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    CGRect buttonRect = CGRectMake(412, 704, 200, 44);
    [allowNavButton setFrame:buttonRect];
    [allowNavButton setTitle:[NSString stringWithCString:"Enable Back Button" encoding:NSASCIIStringEncoding]forState:UIControlStateNormal];
    [allowNavButton addTarget:self action:@selector(allowNavigation:) forControlEvents:UIControlEventTouchUpInside]; 
    [myView addSubview:allowNavButton];

    backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    buttonRect = CGRectMake(490, 0, 44, 44);
    [backButton setFrame:buttonRect];
    [backButton setTitle:[NSString stringWithCString:"Back" encoding:NSASCIIStringEncoding]forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [backButton addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    [backButton setEnabled:NO];
    [myView addSubview:backButton];

    // Create single button
    id myButton = [UIButton buttonWithType:UIButtonTypeCustom];
    buttonRect = CGRectMake(50, 50, 924, 638);
    [myButton setFrame:buttonRect];
    [myButton setBackgroundColor:[UIColor yellowColor]];
    [myButton addTarget:self action:@selector(onSwitchActivated:) forControlEvents:(UIControlEventTouchDown | UIControlEventTouchDragEnter)]; 
    [myButton addTarget:self action:@selector(onSwitchDeactivated:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchDragExit)]; 
    [myView addSubview:myButton];
    NSNumber *switchNum = [NSNumber numberWithInt:1];
    CFDictionaryAddValue([self buttonToSwitchDictionary], myButton, switchNum);
    
	self.view = myView;
    [myView release];
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    CFRelease([self buttonToSwitchDictionary]);
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

// Handlers for switches activated/deactiveated. They send commands to delegate
- (IBAction)onSwitchActivated:(id)sender {
    NSNumber *switchNum;
    if(!CFDictionaryGetValueIfPresent([self buttonToSwitchDictionary], sender, (const void **) &switchNum)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Switch error!" message:@"Dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        [message release];
        return;
    }

    [appDelegate activate:[switchNum intValue]];
}
- (IBAction)onSwitchDeactivated:(id)sender {
    NSNumber *switchNum;
    if(!CFDictionaryGetValueIfPresent([self buttonToSwitchDictionary], sender, (const void **) &switchNum)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Switch error!" message:@"Dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        [message release];
        return;
    }
    
    [appDelegate deactivate:[switchNum intValue]];
}
// Navigation back to root controller
- (IBAction)allowNavigation:(id)sender {
    [backButton setEnabled:YES];
}
- (IBAction)disallowNavigation:(id)sender{
    [backButton setEnabled:NO];
}
- (IBAction)goBack:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
