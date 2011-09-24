//
//  switchPanelViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 9/9/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import "switchPanelViewController.h"
#import "stdio.h"
#import "DDXMLDocument.h"

@implementation switchPanelViewController

@synthesize buttonToSwitchDictionary;
@synthesize urlToLoad;
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

    NSError *xmlError=nil, *fileError=nil;
    NSString *xmlString = [NSString stringWithContentsOfURL:urlToLoad encoding:NSUTF8StringEncoding error:&fileError];
    
    DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithXMLString:xmlString options:0 error:&xmlError];
    if(xmlDoc == nil) {
        NSLog(@"XML Open Failed.");
    }
    NSArray *elementNodes = [xmlDoc nodesForXPath:@".//panel/panelelement" error:&xmlError];
    printf("Found %d elements.\n", [elementNodes count]);
    // Display all elements of the switch panel
    DDXMLNode *element;
    for(element in elementNodes) {
        NSArray *frameNodes = [element nodesForXPath:@".//frame" error:&xmlError];
        NSArray *colorNodes = [element nodesForXPath:@".//rgbacolor" error:&xmlError];
        NSArray *maskNodes = [element nodesForXPath:@".//switchmask" error:&xmlError];
        printf("element with kind %d, %d children, %d frames %d colors %d masks\n", [element kind], [element childCount], [frameNodes count], [colorNodes count], [maskNodes count]);
        // Read frame
        if([frameNodes count] <= 0) {
            NSLog(@"No frame found.\n");
            continue;
        }

        DDXMLNode *frameNode = [frameNodes objectAtIndex:0];
        NSString *frameString = [frameNode stringValue];
        NSLog(@"frame %@", frameString);
        NSScanner *frameScan = [[NSScanner alloc] initWithString:frameString];
        int x, y, w, h;
        bool x_ok = [frameScan scanInt:&x];
        bool y_ok = [frameScan scanInt:&y];
        bool w_ok = [frameScan scanInt:&w];
        bool h_ok = [frameScan scanInt:&h];
        if(!x_ok || !y_ok || !w_ok || !h_ok)
            continue;
        printf("Frame numbers extracted: %d %d %d %d\n", x, y, w, h);
        buttonRect = CGRectMake((CGFloat)x, (CGFloat)y, (CGFloat)w, (CGFloat)h);
        [frameScan release];

        // Read color
        if([colorNodes count] <= 0) {
            NSLog(@"No frame found.\n");
            continue;
        }
        DDXMLNode *colorNode = [colorNodes objectAtIndex:0];
        NSString *colorString = [colorNode stringValue];
        NSLog(@"color %@", colorString);
        NSScanner *colorScan = [[NSScanner alloc] initWithString:colorString];
        CGFloat r, g, b, a;
        bool r_ok = [colorScan scanFloat:&r];
        bool g_ok = [colorScan scanFloat:&g];
        bool b_ok = [colorScan scanFloat:&b];
        bool a_ok = [colorScan scanFloat:&a];
        if(!r_ok || !g_ok || !b_ok || !a_ok)
            continue;
        printf("Color numbers extracted: %f %f %f %f\n", r, g, b, a);
        [colorScan release];
        
        // Read switch mask
        if([colorNodes count] <= 0) {
            NSLog(@"No frame found.\n");
            continue;
        }
        DDXMLNode *maskNode = [maskNodes objectAtIndex:0];
        NSString *maskString = [maskNode stringValue];
        NSLog(@"mask %@", maskString);
        NSScanner *maskScan = [[NSScanner alloc] initWithString:maskString];
        int mask;
        bool mask_ok = [maskScan scanInt:&mask];
        if(!mask_ok)
            continue;
        printf("Switch mask: %d\n", mask);
        [maskScan release];
        // Create the specified button
        id myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [myButton setFrame:buttonRect];
        [myButton setBackgroundColor:[UIColor colorWithRed:r green:g blue:b alpha:a]];
        [myButton addTarget:self action:@selector(onSwitchActivated:) forControlEvents:(UIControlEventTouchDown | UIControlEventTouchDragEnter)]; 
        [myButton addTarget:self action:@selector(onSwitchDeactivated:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchDragExit)]; 
        [myView addSubview:myButton];
        NSNumber *switchNum = [NSNumber numberWithInt:mask];
        CFDictionaryAddValue([self buttonToSwitchDictionary], myButton, switchNum);
    }
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
    [urlToLoad release];
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
