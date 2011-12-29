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
	CGRect cgRct = CGRectMake(0, 20, 1024, 748);
    UIView *myView = [[UIView alloc] initWithFrame:cgRct];
    [myView setBackgroundColor:[UIColor blackColor]];
	myView.autoresizesSubviews = YES;
    [self setButtonToSwitchDictionary:CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks)];
    
    // Create two-button combo to allow navigation
    allowNavButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
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
        NSArray *maskNodes = [element nodesForXPath:@".//switchmask" error:&xmlError];
        NSArray *sequenceNodes = [element nodesForXPath:@".//switchsequence" error:&xmlError];
        NSArray *textNodes = [element nodesForXPath:@".//switchtext" error:&xmlError];

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
        [frameScan release];
        if(!x_ok || !y_ok || !w_ok || !h_ok)
            continue;
        buttonRect = CGRectMake((CGFloat)x, (CGFloat)y, (CGFloat)w, (CGFloat)h);

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
        [colorScan release];
        if(!r_ok || !g_ok || !b_ok || !a_ok)
            continue;
        
        // Read switch or sequence
        if(([maskNodes count] <= 0) && ([sequenceNodes count] <= 0)) {
            NSLog(@"No switch mask or sequence found.\n");
            continue;
        }
        // Create the specified button
        myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [myButton setFrame:buttonRect];
        [myButton setBackgroundColor:[UIColor colorWithRed:r green:g blue:b alpha:a]];
        [myButton addTarget:self action:@selector(onSwitchActivated:) forControlEvents:(UIControlEventTouchDown | UIControlEventTouchDragEnter)]; 
        [myButton addTarget:self action:@selector(onSwitchDeactivated:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchDragExit)];
        if(![sequenceNodes count]) {
            DDXMLNode *maskNode = [maskNodes objectAtIndex:0];
            NSString *maskString = [maskNode stringValue];
            NSScanner *maskScan = [[NSScanner alloc] initWithString:maskString];
            int mask;
            bool mask_ok = [maskScan scanInt:&mask];
            [maskScan release];
            if(!mask_ok)
                continue;
            // Display on button what switches it activates
            NSMutableString *switchesActivatedText =  [NSMutableString stringWithCapacity:64];
            BOOL listedFirstSwitch = NO;
            for(int bit=1; bit <= 16; ++bit) {
                if(!(mask & (1 << (bit-1))))
                    continue;
                if(listedFirstSwitch)
                    [switchesActivatedText appendString:@" and "];
                [switchesActivatedText appendFormat:@"%d", bit];
                listedFirstSwitch = YES;
            }
            [myButton setTitle:switchesActivatedText forState:UIControlStateNormal];
            NSNumber *switchNum = [NSNumber numberWithInt:mask];
            CFDictionaryAddValue([self buttonToSwitchDictionary], myButton, switchNum);
        } else {
            // Create array to hold sequence
            NSMutableArray *switchSequence = [[NSMutableArray alloc] initWithCapacity:5];
            // Element 0: flag to shut down sequencing
            NSNumber *num = [[NSNumber alloc] initWithInt:0];
            [switchSequence insertObject:num atIndex:0];
            [num release];
            NSArray *sequenceElementNodes = [[sequenceNodes objectAtIndex:0] nodesForXPath:@".//sequenceelement" error:&xmlError];
            DDXMLNode *sequenceElement;
            for(sequenceElement in sequenceElementNodes) {
                NSArray *maskNodes = [sequenceElement nodesForXPath:@".//switchmask" error:&xmlError];
                NSArray *timeNodes = [sequenceElement nodesForXPath:@".//time" error:&xmlError];
                if(![maskNodes count] || ![timeNodes count])
                    continue;
                NSString *maskString = [[maskNodes objectAtIndex:0] stringValue];
                NSScanner *maskScan = [[NSScanner alloc] initWithString:maskString];
                int mask;
                bool mask_ok = [maskScan scanInt:&mask];
                [maskScan release];
                if(!mask_ok)
                    continue;
                NSNumber *switchNum = [NSNumber numberWithInt:mask];
                NSString *timeString = [[timeNodes objectAtIndex:0] stringValue];
                NSScanner *timeScan = [[NSScanner alloc] initWithString:timeString];
                float time;
                bool time_ok = [timeScan scanFloat:&time];
                [timeScan release];
                if(!time_ok)
                    continue;
                NSNumber *timeNum = [NSNumber numberWithFloat:time];
                [switchSequence addObject:switchNum];
                [switchSequence addObject:timeNum];
            }
            CFDictionaryAddValue([self buttonToSwitchDictionary], myButton, switchSequence);
            [switchSequence release];
        }
        if([textNodes count]) {
            [myButton setTitle:[[textNodes objectAtIndex:0] stringValue] forState:UIControlStateNormal];
        } 
        [myButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [myView addSubview:myButton];
    }
    
    // Show what switch we're connected to
    CGRect textRect = CGRectMake(700, 0, 324, 36);
    textToShowSwitchName = [[UILabel alloc] initWithFrame:textRect];
    [textToShowSwitchName setBackgroundColor:[UIColor blackColor]];
    [self updateSwitchNameText];
    [myView addSubview:textToShowSwitchName];
    [textToShowSwitchName release];
    
	self.view = myView;
    [myView release];
    [xmlDoc release];
}
- (void)updateSwitchNameText {
    [textToShowSwitchName setTextAlignment:UITextAlignmentLeft];
    if([appDelegate active_switch_index] < 0) {
        [textToShowSwitchName setTextColor:[UIColor redColor]];
        [textToShowSwitchName setText:@"Not connected"];
    } else {
        [textToShowSwitchName setTextColor:[UIColor whiteColor]];
        NSString *switchName = (NSString*)CFArrayGetValueAtIndex([appDelegate switchNameArray], [appDelegate active_switch_index]);
        NSString *switchNameText = [@"Connected to " stringByAppendingString:switchName];
        [textToShowSwitchName setText:switchNameText];
    }
}

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}
*/
- (void) dealloc {
    if([self isViewLoaded]) {
        CFRelease([self buttonToSwitchDictionary]);
        [urlToLoad release];
    }
    [super dealloc];
}

- (void)viewDidUnload
{
    
    // Release any retained subviews of the main view.
    CFRelease([self buttonToSwitchDictionary]);
    [urlToLoad release];
    [switchPanelName release];
    // e.g. self.myOutlet = nil;
    [super viewDidUnload];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

// Handlers for switches activated/deactiveated. They send commands to delegate
- (IBAction)onSwitchActivated:(id)sender {
    [backButton setEnabled:NO];
    NSObject *switches;
    if(!CFDictionaryGetValueIfPresent([self buttonToSwitchDictionary], sender, (const void **) &switches)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Switch error!" message:@"Dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        [message release];
        return;
    }

    [appDelegate activate:switches];
    [self updateSwitchNameText];
}
- (IBAction)onSwitchDeactivated:(id)sender {
    [backButton setEnabled:NO];
    NSObject *switches;
    if(!CFDictionaryGetValueIfPresent([self buttonToSwitchDictionary], sender, (const void **) &switches)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Switch error!" message:@"Dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        [message release];
        return;
    }
    
    [appDelegate deactivate:switches];
    [self updateSwitchNameText];
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
