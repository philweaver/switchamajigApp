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
#define FRAME_HEIGHT 748
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
    highlighting = nil;
#if 0
    // Handy for testing specific configurations
    [[NSUserDefaults standardUserDefaults] setFloat:100 forKey:@"textSizePreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showHelpButtonPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showNetworkConfigButtonPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"enableScanningPreference"];
    [[NSUserDefaults standardUserDefaults] setFloat:500 forKey:@"switchPanelSizePreference"];
#endif
    panelButtonHeight = [[NSUserDefaults standardUserDefaults] integerForKey:@"switchPanelSizePreference"];
    bool scanning = [[NSUserDefaults standardUserDefaults] integerForKey:@"enableScanningPreference"];
    int textFontSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"textSizePreference"];
    [self setView:[[UIView alloc] initWithFrame:CGRectMake(0, border, FRAME_WIDTH, FRAME_HEIGHT-border)]];
    [[self view] setBackgroundColor:[UIColor blackColor]];
    [self setSwitchPanelURLDictionary:[[NSMutableDictionary alloc] initWithCapacity:10]];
    NSString *sampleText = @"Steering Plus";
    CGSize textSize = [sampleText sizeWithFont:[UIFont systemFontOfSize:textFontSize]];
    int textHeight = textSize.height;
    int scrollPanelHeight = FRAME_HEIGHT-border-textHeight;
    if(textSize.width > (panelButtonHeight*3)/2) {
        panelButtonHeight = (textSize.width*2)/3;
    }

    // There are three types of layouts: 
    // 1) The default, with help and/or config button, whose size is adjustable from settings
    // 2) Same as (1) without help or config button, which allows for a larger scroll panel
    // 3) Scanning. For scanning we don't show the help or config button. Instead we make the scroll view a single row and size it based on the text size, and then use the rest of the space for scan/select.
    if(scanning) {
        if(panelButtonHeight > MAX_BUTTON_HEIGHT_FOR_SCANNING)
            panelButtonHeight = MAX_BUTTON_HEIGHT_FOR_SCANNING;
        scrollPanelHeight = panelButtonHeight+textHeight;
        int scanButtonHeight = FRAME_HEIGHT - border - textHeight - scrollPanelHeight;
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
            spaceOnButtomForExtraButtons = panelButtonHeight;
            scrollPanelHeight -= spaceOnButtomForExtraButtons;
            if(scrollPanelHeight < (panelButtonHeight + textHeight)) {
                // Reduce button size to make room for one row of buttons and text
                panelButtonHeight = (FRAME_HEIGHT-border-button_spacing - 2*textHeight)/2;
                scrollPanelHeight = panelButtonHeight + textHeight;
                spaceOnButtomForExtraButtons = panelButtonHeight;
            }
        }
        
        // Set width of help and config buttons
        int helpConfigButtonWidth = (panelButtonHeight > 200) ? panelButtonHeight : 200;
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
    
    [self setStatusText:[[SJUIStatusMessageLabel alloc] initWithFrame:CGRectMake(border, 0, FRAME_WIDTH-2*border, textHeight)]];
    [[self statusText] setText:@"Welcome to Switchamajig"];
    [[self statusText] setBackgroundColor:[UIColor blackColor]];
    [[self statusText] setTextColor:[UIColor whiteColor]];
    [[self statusText] setFont:[UIFont systemFontOfSize:textFontSize]];
    [[self view] addSubview:[self statusText]];
    [self setPanelSelectionScrollView:[[UIScrollView alloc] initWithFrame:CGRectMake(border, textHeight, FRAME_WIDTH-2*border, scrollPanelHeight)]];
    [[self panelSelectionScrollView] setScrollEnabled:YES];
    [[self view] addSubview:[self panelSelectionScrollView]];
    [self initializeScrollPanelWithTextSize:textSize];
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

- (UIImage *) imageFromViewController:(UIViewController*)viewController scaledTo:(CGSize)scaledSize {
    // Create a graphics context large enough to hold the entire viewController image
    CGSize originalViewSize = [[viewController view] bounds].size;
    int unscaledBitmapByteCount = originalViewSize.width * originalViewSize.height * 4;
    void *bitmapData = malloc(unscaledBitmapByteCount);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(bitmapData, originalViewSize.width, originalViewSize.height, 8, originalViewSize.width*4, colorSpace, kCGImageAlphaPremultipliedLast);
    [[[viewController view] layer] renderInContext:context];
    CGImageRef unscaledImageCG = CGBitmapContextCreateImage(context);
    free(bitmapData);
    CGContextRelease(context);
    
    // Repeat process to scale image
    int scaledBitmapByteCount = scaledSize.width * scaledSize.height * 4;
    bitmapData = malloc(scaledBitmapByteCount);
    context = CGBitmapContextCreate(bitmapData, scaledSize.width, scaledSize.height, 8, scaledSize.width*4, colorSpace, kCGImageAlphaPremultipliedLast);
    CGRect scaledImageRect = CGRectMake(0.0, 0.0, scaledSize.width, scaledSize.height);
    CGContextTranslateCTM(context, 0, scaledSize.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextClearRect(context, scaledImageRect);
    CGContextDrawImage(context, scaledImageRect, unscaledImageCG);
    CGImageRef scaledImageCG = CGBitmapContextCreateImage(context);
    UIImage *scaledImage = [UIImage imageWithCGImage:scaledImageCG];
    free(bitmapData);
    CGContextRelease(context);
    CGImageRelease(scaledImageCG);
    CGImageRelease(unscaledImageCG);
    return scaledImage;
}

- (void)initializeScrollPanelWithTextSize:(CGSize)textSize {
    UIColor *bgColor = [UIColor blackColor];
    UIColor *fgColor = [UIColor whiteColor];
    int selectButtonWidth = panelButtonHeight + (panelButtonHeight/2);

    [switchPanelURLDictionary removeAllObjects];
    // Find all switch panel files
    NSArray *xmlUrls = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"xml" subdirectory:nil];
    NSURL *url;
    
    int current_button_x = button_spacing;
    int current_button_y = 0;
    // Create highlighter
    [self setHighlighting:[[UIView alloc] initWithFrame:CGRectMake(current_button_x-HIGHLIGHT_RECT_THICKNESS, current_button_y-HIGHLIGHT_RECT_THICKNESS, selectButtonWidth+2*HIGHLIGHT_RECT_THICKNESS, panelButtonHeight+2*HIGHLIGHT_RECT_THICKNESS)]];
    [panelSelectionScrollView addSubview:[self highlighting]];
    [[self highlighting] setBackgroundColor:bgColor];
    numberOfPanelsInScrollView = 0;
    for(url in xmlUrls) {
        numberOfPanelsInScrollView++;
        // Render view controller into image
        switchPanelViewController *viewController = [switchPanelViewController alloc];
        [viewController setUrlToLoad:url];
        // Create the specified button
        id myButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [myButton setFrame:CGRectMake((CGFloat)current_button_x, (CGFloat)current_button_y, selectButtonWidth, panelButtonHeight)];
        // Also set rectangle for label
        CGRect panelNameLabelRect = CGRectMake((CGFloat)current_button_x, (CGFloat)current_button_y + panelButtonHeight, selectButtonWidth, textSize.height);
        [myButton addTarget:self action:@selector(launchSwitchPanel:) forControlEvents:(UIControlEventTouchUpInside)]; 
        [panelSelectionScrollView addSubview:myButton];
        current_button_y += panelButtonHeight + textSize.height + button_spacing;
        if(current_button_y + panelButtonHeight + textSize.height >= [panelSelectionScrollView bounds].size.height) {
            current_button_y = 0;
            current_button_x += selectButtonWidth + button_spacing;
        }
        UIImage *scaledImage = [self imageFromViewController:viewController scaledTo:[myButton bounds].size];
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
    [panelSelectionScrollView setContentSize:CGSizeMake(current_button_x, [panelSelectionScrollView layer].bounds.size.height)];
    
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
