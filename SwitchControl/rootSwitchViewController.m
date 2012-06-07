//
//  rootSwitchViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 7/27/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import "rootSwitchViewController.h"
#import "switchPanelViewController.h"
#import "helpDisplayViewController.h"
#import "configViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation rootSwitchViewController
@synthesize configButton;
@synthesize helpButton;
@synthesize panelSelectionScrollView;
@synthesize statusText;

- (void)dealloc {
    CFRelease(switchPanelURLDictionary);
}

#pragma mark - View lifecycle
#define border 20
#define button_spacing 50
#define FRAME_WIDTH 1024
#define FRAME_HEIGHT 768
- (void) loadView {
    appDelegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication]delegate];
    [self setView:[[UIView alloc] initWithFrame:CGRectMake(0, border, FRAME_WIDTH, FRAME_HEIGHT-border)]];
    [[self view] setBackgroundColor:[UIColor blackColor]];

    int textFontSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"textSizePreference"];
    NSString *sampleText = @"Steering Plus";
    CGSize textSize = [sampleText sizeWithFont:[UIFont systemFontOfSize:textFontSize]];
    int textHeight = textSize.height;
    int scrollPanelHeight = FRAME_HEIGHT-border-(textHeight+button_spacing);
    selectButtonHeight = [[NSUserDefaults standardUserDefaults] integerForKey:@"switchPanelSizePreference"];
    int spaceOnButtomForExtraButtons = 0;
    BOOL displayHelpButton = [[NSUserDefaults standardUserDefaults] integerForKey:@"showHelpButtonPreference"];
    BOOL displayNetworkConfigButton = [[NSUserDefaults standardUserDefaults] integerForKey:@"showNetworkConfigButtonPreference"];
    if(displayHelpButton || displayNetworkConfigButton) {
        spaceOnButtomForExtraButtons = selectButtonHeight;
        scrollPanelHeight -= spaceOnButtomForExtraButtons;
        if(scrollPanelHeight < (selectButtonHeight + textHeight)) {
            // Reduce button size to make room for one row of buttons and text
            selectButtonHeight = (FRAME_HEIGHT-border-button_spacing - 2*textHeight);
            scrollPanelHeight = selectButtonHeight + textHeight;
            spaceOnButtomForExtraButtons = selectButtonHeight;
        }
    }
    
    // Set width of help and config buttons
    int helpConfigButtonWidth = (selectButtonHeight > 200) ? selectButtonHeight : 200;
    if(displayNetworkConfigButton) {
        [self setConfigButton:[UIButton buttonWithType:UIButtonTypeRoundedRect]];
        [[self configButton] setFrame:CGRectMake(0, [self view].bounds.size.height-spaceOnButtomForExtraButtons, helpConfigButtonWidth, spaceOnButtomForExtraButtons)];
        [[self configButton] setTitle:@"Configure Network Settings" forState:UIControlStateNormal];
        [[self configButton] addTarget:self action:@selector(config_pressed:) forControlEvents:UIControlEventTouchUpInside]; 
        [[self view] addSubview:[self configButton]];
    }
    if(displayHelpButton) {
        [self setHelpButton:[UIButton buttonWithType:UIButtonTypeRoundedRect]];
        [[self helpButton] setFrame:CGRectMake(FRAME_WIDTH-helpConfigButtonWidth, [self view].bounds.size.height-spaceOnButtomForExtraButtons, helpConfigButtonWidth, spaceOnButtomForExtraButtons)];
        [[self helpButton] setTitle:@"Help" forState:UIControlStateNormal];
        [[self helpButton] addTarget:self action:@selector(display_help:) forControlEvents:UIControlEventTouchUpInside]; 
        [[self view] addSubview:[self helpButton]];
    }
    
    [self setStatusText:[[UILabel alloc] initWithFrame:CGRectMake(border, 0, FRAME_WIDTH-2*border, textHeight)]];
    [[self statusText] setText:@"Welcome to Switchamajig"];
    [[self statusText] setBackgroundColor:[UIColor blackColor]];
    [[self statusText] setTextColor:[UIColor whiteColor]];
    [[self statusText] setFont:[UIFont systemFontOfSize:textFontSize]];
    [[self view] addSubview:[self statusText]];
    [self setPanelSelectionScrollView:[[UIScrollView alloc] initWithFrame:CGRectMake(border, textHeight+button_spacing, FRAME_WIDTH-2*border, scrollPanelHeight)]];
    [[self panelSelectionScrollView] setScrollEnabled:YES];
    [[self view] addSubview:[self panelSelectionScrollView]];
    [self initializeScrollPanelWithTextSize:textSize];
    // Prepare to run status timer
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(statusMessageCallback) userInfo:nil repeats:NO]; 
}

- (void) statusMessageCallback {
    // If there are any alerts, display them
    float secondsUntilNextCall = 0.5;
    [[appDelegate statusInfoLock] lock];
    if([[appDelegate statusMessages] count]) {
        NSArray *messageArray = [[appDelegate statusMessages] objectAtIndex:0];
        NSString *messageText = [messageArray objectAtIndex:0];
        NSNumber *messageTime = [messageArray objectAtIndex:1];
        UIColor *messageColor = [messageArray objectAtIndex:2];
        [[self statusText] setText:messageText];
        [[self statusText] setTextColor:messageColor];
        secondsUntilNextCall = [messageTime floatValue];
        [[appDelegate statusMessages] removeObjectAtIndex:0];
        
        
    } 
    else if ([[appDelegate friendlyNameHostNameDictionary] count] == 0) {
        // If there are no names in the dictionary, state that
        [[self statusText] setText:@"No Switchamajigs Connected"];
        [[self statusText] setTextColor:[UIColor redColor]];        
    } else {
        // Cycle through all connected switches
        NSArray *friendlyNames = [[appDelegate friendlyNameHostNameDictionary] allKeys];
        if(friendlyNameDictionaryIndex >= [friendlyNames count])
            friendlyNameDictionaryIndex = 0;
        [[self statusText] setText:[friendlyNames objectAtIndex:friendlyNameDictionaryIndex]];
        [[self statusText] setTextColor:[UIColor whiteColor]];
        secondsUntilNextCall = 3.0;
    }
    [[appDelegate statusInfoLock] unlock];
    [NSTimer scheduledTimerWithTimeInterval:secondsUntilNextCall target:self selector:@selector(statusMessageCallback) userInfo:nil repeats:NO]; 
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    // Initially the config button is not visible
    //[ConfigButton setHidden:YES];
    // Determine if we will enable config - need flexible alert views
    isConfigAvailable = [UIAlertView instancesRespondToSelector:@selector(setAlertViewStyle:)];
    // Make nav bar disappear
    [[self navigationController] setNavigationBarHidden:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(switch_names_updated:) name:@"switch_list_was_updated" object:nil];
}

- (void)initializeScrollPanelWithTextSize:(CGSize)textSize {
    UIColor *bgColor = [UIColor blackColor];
    UIColor *fgColor = [UIColor whiteColor];
    int selectButtonWidth = selectButtonHeight + (selectButtonHeight/2);
    if(textSize.width > selectButtonWidth) {
        selectButtonWidth = textSize.width;
        selectButtonHeight = (selectButtonWidth*2)/3;
    }

    if(switchPanelURLDictionary) {
        CFDictionaryRemoveAllValues(switchPanelURLDictionary);
        CFRelease(switchPanelURLDictionary);
    }
    switchPanelURLDictionary = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    // Find all switch panel files
    NSArray *xmlUrls = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"xml" subdirectory:nil];
    NSURL *url;
    
    int current_button_x = button_spacing;
    int current_button_y = button_spacing;
    
    for(url in xmlUrls) {
        // Render view controller into image
        switchPanelViewController *viewController = [switchPanelViewController alloc];
        [viewController setUrlToLoad:url];
        CGSize size = [[viewController view] bounds].size;
        UIGraphicsBeginImageContext(size);
        [[[viewController view] layer] renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        // Create button with image
        // Create the specified button
        id myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [myButton setFrame:CGRectMake((CGFloat)current_button_x, (CGFloat)current_button_y, selectButtonWidth, selectButtonHeight)];
        // Also set rectangle for label
        CGRect panelNameLabelRect = CGRectMake((CGFloat)current_button_x, (CGFloat)current_button_y + selectButtonHeight, selectButtonWidth, textSize.height);
        [myButton addTarget:self action:@selector(launchSwitchPanel:) forControlEvents:(UIControlEventTouchUpInside)]; 
        [panelSelectionScrollView addSubview:myButton];
        current_button_y += selectButtonHeight + textSize.height + button_spacing;
        if(current_button_y + selectButtonHeight >= [panelSelectionScrollView bounds].size.height) {
            current_button_y = button_spacing;
            current_button_x += selectButtonWidth + button_spacing;
        }
        size = [myButton bounds].size;
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [myButton setImage:scaledImage forState:UIControlStateNormal];
        // Add text label
        UILabel *panelNameLabel = [[UILabel alloc] initWithFrame:panelNameLabelRect];
        [panelNameLabel setBackgroundColor:bgColor];
        [panelNameLabel setTextColor:fgColor];
        [panelNameLabel setText:[viewController switchPanelName]];
        [panelNameLabel setTextAlignment:UITextAlignmentCenter];
        [panelNameLabel setFont:[UIFont systemFontOfSize:[[NSUserDefaults standardUserDefaults] integerForKey:@"textSizePreference"]]];
        [panelSelectionScrollView addSubview:panelNameLabel];
        // Redesign CFDictionaryAddValue(switchPanelURLDictionary, myButton, url);
    }
    if(current_button_y != button_spacing)
        current_button_x += selectButtonWidth + button_spacing;
    [panelSelectionScrollView setContentSize:CGSizeMake(current_button_x, 100)];
    [panelSelectionScrollView setScrollEnabled:YES];
}

- (void)viewDidUnload
{
    [self setPanelSelectionScrollView:nil];
    [self setStatusText:nil];
    [self setHelpButton:nil];
    [super viewDidUnload];
    CFRelease(switchPanelURLDictionary);

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if((interfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (interfaceOrientation == UIInterfaceOrientationLandscapeRight))
        return YES;
    return NO;
}

-(void)ResetScrollPanel {
    // Deconstruct the scroll panel
    NSArray *subviewArray = [panelSelectionScrollView subviews];
    UIView *thisView;
    for(thisView in subviewArray) {
        NSArray *subviewArray2 = [thisView subviews];
        UIView *thisView2;
        for(thisView2 in subviewArray2) {
            [thisView2 removeFromSuperview];
        }
        [thisView removeFromSuperview];
    }
    // Reinitialize the scroll panel
    NSString *sampleText = @"Steering Plus";
    CGSize textSize = [sampleText sizeWithFont:[UIFont systemFontOfSize:[[NSUserDefaults standardUserDefaults] integerForKey:@"textSizePreference"]]];

    [self initializeScrollPanelWithTextSize:textSize];
}


-(void) viewWillAppear:(BOOL)animated {
    [[self navigationController] setNavigationBarHidden:YES];
    [self reload_switch_name_table];
}

- (void)launchSwitchPanel:(id)sender {
    // Load programatically-created view
    switchPanelViewController *viewController = [switchPanelViewController alloc];
    NSURL *url;
#if 0
// REDESIGN
    if(!CFDictionaryGetValueIfPresent(switchPanelURLDictionary, sender, (const void **) &url)) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Select error!" message:@"Panel dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        return;
    }
#endif
    [viewController setUrlToLoad:url];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)display_help:(id)sender {
    [[self navigationController] setNavigationBarHidden:NO];
    helpDisplayViewController *helpViewCtrl = [helpDisplayViewController alloc];
    [self.navigationController pushViewController:helpViewCtrl animated:YES];
}
- (void)config_pressed:(id)sender {
    //[[self navigationController] setNavigationBarHidden:NO];
    configViewController *configViewCtrl = [[configViewController alloc] initWithNibName:@"configViewController" bundle:nil];
    [configViewCtrl setModalPresentationStyle:UIModalPresentationFormSheet];
    [configViewCtrl setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    configViewCtrl->appDelegate = appDelegate;
#if 0
// REDESIGN
    configViewCtrl->switchName = [NSString stringWithString:(NSString*)CFArrayGetValueAtIndex([appDelegate switchNameArray], [appDelegate active_switch_index])];
#endif
    [self presentModalViewController:configViewCtrl animated:YES];
}

- (void) switch_names_updated:(NSNotification *) notification {
    [self performSelectorOnMainThread:@selector(reload_switch_name_table) withObject:nil waitUntilDone:NO];
}
- (void) reload_switch_name_table {
}

// Code to support table displaying the names of the switches discovered during detect
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"Cell"];
    }
    return cell;
}

// Support for connecting to a switch when its name is selected from the table
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [appDelegate connect_to_switch:indexPath.row protocol:[appDelegate settings_switch_connection_protocol] retries:10 showMessagesOnError:YES];
    if([appDelegate switch_socket])
        [appDelegate sendSwitchState];

    [self reload_switch_name_table];
}


@end
