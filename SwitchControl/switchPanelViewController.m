//
//  switchPanelViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 9/9/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import "switchPanelViewController.h"
#import "stdio.h"
#import "../../KissXML/KissXML/DDXMLDocument.h"
#import "SJUIStatusMessageLabel.h"

@implementation switchPanelViewController

@synthesize activateButtonDictionary;
@synthesize deactivateButtonDictionary;
@synthesize urlToLoad;
@synthesize switchPanelName;
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
    UIColor *bgColor = [appDelegate backgroundColor];
    
	CGRect cgRct = CGRectMake(0, 20, 1024, 748);
    UIView *myView = [[UIView alloc] initWithFrame:cgRct];
    [myView setBackgroundColor:bgColor];
	myView.autoresizesSubviews = YES;
    [self setActivateButtonDictionary:[NSMutableDictionary dictionaryWithCapacity:10]]; 
    [self setDeactivateButtonDictionary:[NSMutableDictionary dictionaryWithCapacity:10]]; 
    
    NSError *xmlError=nil, *fileError=nil;
    NSString *xmlString = [NSString stringWithContentsOfURL:urlToLoad encoding:NSUTF8StringEncoding error:&fileError];
    
    DDXMLDocument *xmlDoc = [[DDXMLDocument alloc] initWithXMLString:xmlString options:0 error:&xmlError];
    if(xmlDoc == nil) {
        NSLog(@"XML Open Failed.");
    }
    // Set name
    [self setSwitchPanelName:@""];
    NSArray *panelNameNodes = [xmlDoc nodesForXPath:@".//panel/panelname" error:&xmlError];
    if([panelNameNodes count]) {
        DDXMLNode *panelNameNode = [panelNameNodes objectAtIndex:0];
        [self setSwitchPanelName:[panelNameNode stringValue]];
    }
    
    NSArray *elementNodes = [xmlDoc nodesForXPath:@".//panel/panelelement" error:&xmlError];
    // Display all elements of the switch panel
    DDXMLNode *element;
    for(element in elementNodes) {
        NSArray *frameNodes = [element nodesForXPath:@".//frame" error:&xmlError];
        NSArray *colorNodes = [element nodesForXPath:@".//rgbacolor" error:&xmlError];
        NSArray *textNodes = [element nodesForXPath:@".//switchtext" error:&xmlError];
        NSArray *activateNodes = [element nodesForXPath:@".//onswitchactivate/actionsequenceondevice" error:&xmlError];
        NSArray *deactivateNodes = [element nodesForXPath:@".//onswitchdeactivate/actionsequenceondevice" error:&xmlError];

        // Read frame
        if([frameNodes count] <= 0) {
            NSLog(@"No frame found.\n");
            continue;
        }

        DDXMLNode *frameNode = [frameNodes objectAtIndex:0];
        NSString *frameString = [frameNode stringValue];
        NSScanner *frameScan = [[NSScanner alloc] initWithString:frameString];
        int x, y, w, h;
        bool x_ok = [frameScan scanInt:&x];
        bool y_ok = [frameScan scanInt:&y];
        bool w_ok = [frameScan scanInt:&w];
        bool h_ok = [frameScan scanInt:&h];
        if(!x_ok || !y_ok || !w_ok || !h_ok)
            continue;
        CGRect buttonRect = CGRectMake((CGFloat)x, (CGFloat)y, (CGFloat)w, (CGFloat)h);

        // Read color
        if([colorNodes count] <= 0) {
            NSLog(@"No color found.\n");
            continue;
        }
        DDXMLNode *colorNode = [colorNodes objectAtIndex:0];
        NSString *colorString = [colorNode stringValue];
        NSScanner *colorScan = [[NSScanner alloc] initWithString:colorString];
        CGFloat r, g, b, a;
        bool r_ok = [colorScan scanFloat:&r];
        bool g_ok = [colorScan scanFloat:&g];
        bool b_ok = [colorScan scanFloat:&b];
        bool a_ok = [colorScan scanFloat:&a];
        if(!r_ok || !g_ok || !b_ok || !a_ok)
            continue;
        // Create the specified button
        id myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [myButton setFrame:buttonRect];
        [myButton setBackgroundColor:[UIColor colorWithRed:r green:g blue:b alpha:a]];
        [myButton addTarget:self action:@selector(onSwitchActivated:) forControlEvents:(UIControlEventTouchDown | UIControlEventTouchDragEnter)]; 
        [myButton addTarget:self action:@selector(onSwitchDeactivated:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchDragExit)];
        
        // Read text for switch
        if([textNodes count]) {
            [myButton setTitle:[[textNodes objectAtIndex:0] stringValue] forState:UIControlStateNormal];
        } 
        [myButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];

        // Associate the actions for pressing the button
        NSValue *value = [[NSValue alloc] initWithBytes:((void *)myButton) objCType:@encode(id)];
        [[self activateButtonDictionary] setObject:activateNodes forKey:value];
        [[self deactivateButtonDictionary] setObject:deactivateNodes forKey:value];
        
        [myView addSubview:myButton];
    }
    
    oneButtonNavigation = [[NSUserDefaults standardUserDefaults] boolForKey:@"singleTapBackButtonPreference"];
    CGRect backButtonRect;
    backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    if(!oneButtonNavigation) {
        // Create two-button combo to allow navigation
        id allowNavButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        CGRect buttonRect = CGRectMake(412, 704, 200, 44);
        [allowNavButton setFrame:buttonRect];
        [allowNavButton setTitle:[NSString stringWithCString:"Enable Back Button" encoding:NSASCIIStringEncoding]forState:UIControlStateNormal];
        [allowNavButton addTarget:self action:@selector(allowNavigation:) forControlEvents:UIControlEventTouchUpInside]; 
        [myView addSubview:allowNavButton];
        backButtonRect = CGRectMake(490, 0, 44, 44);
        [backButton setEnabled:NO];
    } else {
        float backButtonHeight = [[NSUserDefaults standardUserDefaults] integerForKey:@"switchPanelSizePreference"];
        float backButtonWidth = backButtonHeight * 1.5;
        backButtonRect = CGRectMake(0, 0, backButtonWidth, backButtonHeight);
        [backButton setEnabled:YES];
    }
    [backButton setFrame:backButtonRect];
    [backButton setTitle:[NSString stringWithCString:"Back" encoding:NSASCIIStringEncoding]forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [backButton addTarget:self action:@selector(goBack:) forControlEvents:UIControlEventTouchUpInside];
    [myView addSubview:backButton];
    
    // Show status
    CGRect textRect = CGRectMake(700, 0, 324, 36);
    textToShowSwitchName = [[SJUIStatusMessageLabel alloc] initWithFrame:textRect];
    [textToShowSwitchName setBackgroundColor:bgColor];
    [myView addSubview:textToShowSwitchName];
    
	self.view = myView;
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

// Handlers for switches activated/deactivated. Send XML node information to delegate.
- (IBAction)onSwitchActivated:(id)sender {
    [backButton setEnabled:oneButtonNavigation];
    NSValue *value = [[NSValue alloc] initWithBytes:((void *)sender) objCType:@encode(id)];
    NSArray *actions = [[self activateButtonDictionary] objectForKey:value];
    if(actions == nil) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Switch error!" message:@"Dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        return;
    }
    DDXMLNode *action;
    for(action in actions) {
        [appDelegate performActionSequence:action];
    }
}
- (IBAction)onSwitchDeactivated:(id)sender {
    [backButton setEnabled:oneButtonNavigation];
    NSValue *value = [[NSValue alloc] initWithBytes:((void *)sender) objCType:@encode(id)];
    NSArray *actions = [[self deactivateButtonDictionary] objectForKey:value];
    if(actions == nil) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Switch error!" message:@"Dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        return;
    }
    DDXMLNode *action;
    for(action in actions) {
        [appDelegate performActionSequence:action];
    }
}
// Navigation back to root controller
- (IBAction)allowNavigation:(id)sender {
    [backButton setEnabled:YES];
}
- (IBAction)disallowNavigation:(id)sender{
    [backButton setEnabled:oneButtonNavigation];
}
- (IBAction)goBack:(id)sender{
    [self.navigationController popViewControllerAnimated:YES];
}
@end
