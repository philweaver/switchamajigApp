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
@synthesize scanButton;
@synthesize selectButton;
@synthesize highlighting;
@synthesize switchPanelURLDictionary;

#pragma mark - View lifecycle
#define border 20
#define button_spacing 50
#define FRAME_WIDTH 1024
#define FRAME_HEIGHT 768
#define MAX_BUTTON_HEIGHT_FOR_SCANNING 200

+ (UIColor *) uiColorFromScanSelectPreferenceIndex:(int )colorIndex {
    switch(colorIndex) {
        case 0: return [UIColor greenColor];
        case 1: return [UIColor redColor];
        case 2: return [UIColor blueColor];
        case 3: return [UIColor yellowColor];
        case 4: return [UIColor orangeColor];
        default: return [UIColor whiteColor];
    }
}

- (void) loadView {
    appDelegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication]delegate];
    helpButton = nil;
    configButton = nil;
    scanButton = nil;
    selectButton = nil;

    [self setView:[[UIView alloc] initWithFrame:CGRectMake(0, border, FRAME_WIDTH, FRAME_HEIGHT-border)]];
    [[self view] setBackgroundColor:[UIColor blackColor]];
    [self setSwitchPanelURLDictionary:[[NSMutableDictionary alloc] initWithCapacity:10]];
    int textFontSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"textSizePreference"];
    NSString *sampleText = @"Steering Plus";
    CGSize textSize = [sampleText sizeWithFont:[UIFont systemFontOfSize:textFontSize]];
    int textHeight = textSize.height;
    int scrollPanelHeight = FRAME_HEIGHT-border-textHeight;
    selectButtonHeight = [[NSUserDefaults standardUserDefaults] integerForKey:@"switchPanelSizePreference"];
    if(textSize.width > (selectButtonHeight*3)/2) {
        selectButtonHeight = (textSize.width*2)/3;
    }

    // There are three types of layouts: 
    // 1) The default, with help and/or config button, whose size is adjustable from settings
    // 2) Same as (1) without help or config button, which allows for a larger scroll panel
    // 3) Scanning. For scanning we don't show the help or config button. Instead we make the scroll view a single row and size it based on the text size, and then use the rest of the space for scan/select.
    bool scanning = [[NSUserDefaults standardUserDefaults] integerForKey:@"enableScanningPreference"];
    if(scanning) {
        if(selectButtonHeight > MAX_BUTTON_HEIGHT_FOR_SCANNING)
            selectButtonHeight = MAX_BUTTON_HEIGHT_FOR_SCANNING;
        scrollPanelHeight = selectButtonHeight+textHeight;
        int scanButtonHeight = FRAME_HEIGHT - textHeight - scrollPanelHeight;
        int scanButtonWidth = (FRAME_WIDTH - button_spacing)/2;
        // Create and set up scan button
        [self setScanButton:[UIButton buttonWithType:UIButtonTypeCustom]];
        [[self scanButton] setTitle:@"Scan" forState:UIControlStateNormal];
        [[[self scanButton] titleLabel] setFont:[UIFont systemFontOfSize:textFontSize]];
        [[self scanButton] setBackgroundColor:[rootSwitchViewController uiColorFromScanSelectPreferenceIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"scanButtonColorPreference"]]];
        [[self scanButton] setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [[self scanButton] addTarget:self action:@selector(scanPressed:) forControlEvents:UIControlEventTouchUpInside]; 
        [[self view] addSubview:[self scanButton]];
        // Create and set up select button
        [self setSelectButton:[UIButton buttonWithType:UIButtonTypeCustom]];
        [[self selectButton] setTitle:@"Select" forState:UIControlStateNormal];
        [[[self selectButton] titleLabel] setFont:[UIFont systemFontOfSize:textFontSize]];
        [[self selectButton] addTarget:self action:@selector(selectPressed:) forControlEvents:UIControlEventTouchUpInside];
        [[self selectButton] setBackgroundColor:[rootSwitchViewController uiColorFromScanSelectPreferenceIndex:[[NSUserDefaults standardUserDefaults] integerForKey:@"selectButtonColorPreference"]]];
        [[self selectButton] setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        if([[NSUserDefaults standardUserDefaults] integerForKey:@"selectButtonOnLeftPreference"]) {
            [[self selectButton] setFrame:CGRectMake(0, textHeight+scrollPanelHeight, scanButtonWidth, scanButtonHeight)];
            [[self scanButton] setFrame:CGRectMake(FRAME_WIDTH - scanButtonWidth, textHeight+scrollPanelHeight, scanButtonWidth, scanButtonHeight)];
        } else {
            [[self scanButton] setFrame:CGRectMake(0, textHeight+scrollPanelHeight, scanButtonWidth, scanButtonHeight)];
            [[self selectButton] setFrame:CGRectMake(FRAME_WIDTH - scanButtonWidth, textHeight+scrollPanelHeight, scanButtonWidth, scanButtonHeight)];
        }
        [[self view] addSubview:[self selectButton]];
    } else {
        int spaceOnButtomForExtraButtons = 0;
        BOOL displayHelpButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"showHelpButtonPreference"];
        BOOL displayNetworkConfigButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"showNetworkConfigButtonPreference"];
        if(displayHelpButton || displayNetworkConfigButton) {
            spaceOnButtomForExtraButtons = selectButtonHeight;
            scrollPanelHeight -= spaceOnButtomForExtraButtons;
            if(scrollPanelHeight < (selectButtonHeight + textHeight)) {
                // Reduce button size to make room for one row of buttons and text
                selectButtonHeight = (FRAME_HEIGHT-border-button_spacing - 2*textHeight)/2;
                scrollPanelHeight = selectButtonHeight + textHeight;
                spaceOnButtomForExtraButtons = selectButtonHeight;
            }
        }
        
        // Set width of help and config buttons
        int helpConfigButtonWidth = (selectButtonHeight > 200) ? selectButtonHeight : 200;
        if(displayNetworkConfigButton) {
            NSString *configText = @"Configure Network Settings";
            [self setConfigButton:[UIButton buttonWithType:UIButtonTypeRoundedRect]];
            CGSize configTextSize = [configText sizeWithFont:[UIFont systemFontOfSize:textFontSize]];
            if(configTextSize.width > helpConfigButtonWidth)
                helpConfigButtonWidth = configTextSize.width;
            if(helpConfigButtonWidth > FRAME_WIDTH/2)
                helpConfigButtonWidth = FRAME_WIDTH/2;
            [[self configButton] setFrame:CGRectMake(0, [self view].bounds.size.height-spaceOnButtomForExtraButtons, helpConfigButtonWidth, spaceOnButtomForExtraButtons)];
            [[self configButton] setTitle:configText forState:UIControlStateNormal];
            [[[self configButton] titleLabel] setFont:[UIFont systemFontOfSize:textFontSize]];
            [[self configButton] addTarget:self action:@selector(config_pressed:) forControlEvents:UIControlEventTouchUpInside]; 
            [[self view] addSubview:[self configButton]];
        }
        if(displayHelpButton) {
            NSString *helpText = @"Help";
            [self setHelpButton:[UIButton buttonWithType:UIButtonTypeRoundedRect]];
            CGSize helpTextSize = [helpText sizeWithFont:[UIFont systemFontOfSize:textFontSize]];
            if(helpTextSize.width > helpConfigButtonWidth)
                helpConfigButtonWidth = helpTextSize.width;
            if(helpConfigButtonWidth > FRAME_WIDTH/2)
                helpConfigButtonWidth = FRAME_WIDTH/2;
            [[self helpButton] setFrame:CGRectMake(FRAME_WIDTH-helpConfigButtonWidth, [self view].bounds.size.height-spaceOnButtomForExtraButtons, helpConfigButtonWidth, spaceOnButtomForExtraButtons)];
            [[self helpButton] setTitle:@"Help" forState:UIControlStateNormal];
            [[[self helpButton] titleLabel] setFont:[UIFont systemFontOfSize:textFontSize]];
            [[self helpButton] addTarget:self action:@selector(display_help:) forControlEvents:UIControlEventTouchUpInside]; 
            [[self view] addSubview:[self helpButton]];
        }
    }
    
    [self setStatusText:[[UILabel alloc] initWithFrame:CGRectMake(border, 0, FRAME_WIDTH-2*border, textHeight)]];
    [[self statusText] setText:@"Welcome to Switchamajig"];
    [[self statusText] setBackgroundColor:[UIColor blackColor]];
    [[self statusText] setTextColor:[UIColor whiteColor]];
    [[self statusText] setFont:[UIFont systemFontOfSize:textFontSize]];
    [[self view] addSubview:[self statusText]];
    [self setPanelSelectionScrollView:[[UIScrollView alloc] initWithFrame:CGRectMake(border, textHeight, FRAME_WIDTH-2*border, scrollPanelHeight)]];
    [[self panelSelectionScrollView] setScrollEnabled:YES];
    [[self view] addSubview:[self panelSelectionScrollView]];
    [self initializeScrollPanelWithTextSize:textSize];
    // Prepare to run status timer
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(statusMessageCallback) userInfo:nil repeats:NO]; 
    indexOfCurrentScanSelection = 0;
    if(scanning)
        [self highlightCurrentScanSelection:YES];
}

#define HIGHLIGHT_RECT_THICKNESS 3
// Scanning support
- (void) scanPressed:(id)sender {
    [self highlightCurrentScanSelection:NO];
    indexOfCurrentScanSelection++;
    [self highlightCurrentScanSelection:YES];
}

- (void) selectPressed:(id)sender {
    UIButton *panel = [[panelSelectionScrollView subviews] objectAtIndex:indexOfCurrentScanSelection*2 + 1];
    [self launchSwitchPanel:panel];
}

- (void) highlightCurrentScanSelection:(BOOL)highlight {
    if(indexOfCurrentScanSelection < 0)
        indexOfCurrentScanSelection = numberOfPanelsInScrollView-1;
    if(indexOfCurrentScanSelection >= numberOfPanelsInScrollView)
        indexOfCurrentScanSelection = 0;
    UIButton *panel = [[panelSelectionScrollView subviews] objectAtIndex:indexOfCurrentScanSelection*2 + 1];
    CGRect highlightFrame = [panel frame];
    highlightFrame.size.width += HIGHLIGHT_RECT_THICKNESS*2;
    highlightFrame.size.height += HIGHLIGHT_RECT_THICKNESS*2;
    highlightFrame.origin.x -= HIGHLIGHT_RECT_THICKNESS;
    highlightFrame.origin.y -= HIGHLIGHT_RECT_THICKNESS;
    [highlighting setFrame:highlightFrame];
    UIColor *newColor = ((highlight)?[UIColor colorWithRed:0.5 green:0.5 blue:1.0 alpha:1.0]:[UIColor blackColor]);
    [highlighting setBackgroundColor:newColor];
    UITextView *text = [[panelSelectionScrollView subviews] objectAtIndex:indexOfCurrentScanSelection*2 + 2];
    newColor = ((highlight)?[UIColor colorWithRed:0.5 green:0.5 blue:1.0 alpha:1.0]:[UIColor whiteColor]);
    [text setTextColor:newColor];
    if(highlight) {
        // Reposition scroll to center the panel
        [panelSelectionScrollView scrollRectToVisible:highlightFrame animated:YES];
    }
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
        [[self statusText] setText:[NSString stringWithFormat:@"Connected to %@",[friendlyNames objectAtIndex:friendlyNameDictionaryIndex]]];
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

    [switchPanelURLDictionary removeAllObjects];
    // Find all switch panel files
    NSArray *xmlUrls = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"xml" subdirectory:nil];
    NSURL *url;
    
    int current_button_x = button_spacing;
    int current_button_y = 0;
    // Create highlighter
    [self setHighlighting:[[UIView alloc] initWithFrame:CGRectMake(current_button_x-HIGHLIGHT_RECT_THICKNESS, current_button_y-HIGHLIGHT_RECT_THICKNESS, selectButtonWidth+2*HIGHLIGHT_RECT_THICKNESS, selectButtonHeight+2*HIGHLIGHT_RECT_THICKNESS)]];
    [panelSelectionScrollView addSubview:[self highlighting]];
    [[self highlighting] setBackgroundColor:bgColor];
    numberOfPanelsInScrollView = 0;
    for(url in xmlUrls) {
        numberOfPanelsInScrollView++;
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
            current_button_y = 0;
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
        [[self switchPanelURLDictionary] setObject:url forKey:[NSValue valueWithNonretainedObject:myButton]];
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
    [self setSwitchPanelURLDictionary:nil];
    [super viewDidUnload];

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
    NSURL *url = [switchPanelURLDictionary objectForKey:[NSValue valueWithNonretainedObject:sender]];

    if(!url) {
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Select error!" message:@"Panel dictionary lookup failed (code bug)."  delegate:nil cancelButtonTitle:@"OK"  otherButtonTitles:nil];  
        [message show];  
        return;
    }
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
    [appDelegate connect_to_switch:indexPath.row protocol:0 retries:10 showMessagesOnError:YES];
    if([appDelegate switch_socket])
        [appDelegate sendSwitchState];

    [self reload_switch_name_table];
}


@end
