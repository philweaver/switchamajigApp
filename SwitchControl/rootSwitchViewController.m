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
#import "quickStartSettingsViewController.h"
#import "configViewController.h"
#import <QuartzCore/QuartzCore.h>

@implementation rootSwitchViewController
@synthesize configButton;
@synthesize helpButton;
@synthesize showQuickstartWizardButton;
@synthesize panelSelectionScrollView;
@synthesize statusText;
@synthesize scanButton;
@synthesize selectButton;
//@synthesize highlighting;
@synthesize switchPanelURLDictionary;

#pragma mark - View lifecycle
#define border 20
#define button_spacing 50
#define FRAME_WIDTH 1024
#define FRAME_HEIGHT 748

enum {SCANNING_STYLE_NONE=0,SCANNING_STYLE_AUTO_SCAN=1,SCANNING_STYLE_STEP_SCAN=2};

- (void) loadView {
    appDelegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication]delegate];
    helpButton = nil;
    configButton = nil;
    scanButton = nil;
    selectButton = nil;
//    highlighting = nil;
#if 0
    // Handy for testing specific configurations
    [[NSUserDefaults standardUserDefaults] setFloat:50 forKey:@"textSizePreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showHelpButtonPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showNetworkConfigButtonPreference"];
    [[NSUserDefaults standardUserDefaults] setFloat:0 forKey:@"scanningStylePreference"];
    [[NSUserDefaults standardUserDefaults] setFloat:494 forKey:@"switchPanelSizePreference"];
#endif
    panelButtonHeight = [[NSUserDefaults standardUserDefaults] integerForKey:@"switchPanelSizePreference"];
    scanningStyle = [[NSUserDefaults standardUserDefaults] integerForKey:@"scanningStylePreference"];
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

    // Figure out if we need space on the bottom to make room for the help, network config, and quickstart buttons.
    int spaceOnBottomForExtraButtons = 0;
    BOOL displayHelpButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"showHelpButtonPreference"];
    BOOL displayNetworkConfigButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"showNetworkConfigButtonPreference"];
    BOOL displayQuickStartWizardButton = [[NSUserDefaults standardUserDefaults] boolForKey:@"showQuickStartWizardButtonPreference"];
    if(displayHelpButton || displayNetworkConfigButton || displayQuickStartWizardButton) {
        /* Don't make config and text buttons resizable
         spaceOnButtomForExtraButtons = panelButtonHeight;
         */
        spaceOnBottomForExtraButtons = 50;
        scrollPanelHeight -= spaceOnBottomForExtraButtons;
        /* if(scrollPanelHeight < (panelButtonHeight + textHeight)) {
         // Reduce button size to make room for one row of buttons and text
         panelButtonHeight = (FRAME_HEIGHT-border-button_spacing - 2*textHeight)/2;
         scrollPanelHeight = panelButtonHeight + textHeight;
         spaceOnBottomForExtraButtons = panelButtonHeight;
         } */
    }
    
    // Set width of help and config buttons
    int helpConfigButtonWidth = 250; // (panelButtonHeight > 200) ? panelButtonHeight : 200;
    if(displayNetworkConfigButton && [UIAlertView instancesRespondToSelector:@selector(setAlertViewStyle:)])
    {
        NSString *configText = @"Configure Network Settings";
        [self setConfigButton:[UIButton buttonWithType:UIButtonTypeRoundedRect]];
        [[self configButton] setFrame:CGRectMake(0, [self view].bounds.size.height-spaceOnBottomForExtraButtons, helpConfigButtonWidth, spaceOnBottomForExtraButtons)];
        [[self configButton] setTitle:configText forState:UIControlStateNormal];
        [[[self configButton] titleLabel] setFont:[UIFont systemFontOfSize:20/*textFontSize*/]];
        [[self configButton] addTarget:self action:@selector(config_pressed:) forControlEvents:UIControlEventTouchUpInside];
        [[self view] addSubview:[self configButton]];
    }
    if(displayHelpButton) {
        NSString *helpText = @"Help";
        [self setHelpButton:[UIButton buttonWithType:UIButtonTypeRoundedRect]];
        [[self helpButton] setFrame:CGRectMake(FRAME_WIDTH-helpConfigButtonWidth, [self view].bounds.size.height-spaceOnBottomForExtraButtons, helpConfigButtonWidth, spaceOnBottomForExtraButtons)];
        [[self helpButton] setTitle:helpText forState:UIControlStateNormal];
        [[[self helpButton] titleLabel] setFont:[UIFont systemFontOfSize:20/*textFontSize*/]];
        [[self helpButton] addTarget:self action:@selector(display_help:) forControlEvents:UIControlEventTouchUpInside];
        [[self view] addSubview:[self helpButton]];
    }
    if(displayQuickStartWizardButton) {
        [self setShowQuickstartWizardButton:[UIButton buttonWithType:UIButtonTypeRoundedRect]];
        [[self showQuickstartWizardButton] setFrame:CGRectMake((FRAME_WIDTH-helpConfigButtonWidth)/2, [self view].bounds.size.height-spaceOnBottomForExtraButtons, helpConfigButtonWidth, spaceOnBottomForExtraButtons)];
        [[self showQuickstartWizardButton] setTitle:@"Quick-Start Wizard" forState:UIControlStateNormal];
        [[[self showQuickstartWizardButton] titleLabel] setFont:[UIFont systemFontOfSize:20/*textFontSize*/]];
        [[self showQuickstartWizardButton] addTarget:self action:@selector(display_qswizard:) forControlEvents:UIControlEventTouchUpInside];
        [[self view] addSubview:[self showQuickstartWizardButton]];
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
    if(scanningStyle != SCANNING_STYLE_NONE) {
        // Set up for scanning
        UITextField *scanningInputTextField = [[UITextField alloc] initWithFrame:CGRectMake(0,0,1,1)];
        [scanningInputTextField setHidden:YES];
        [scanningInputTextField setDelegate:self];
        [[self view] addSubview:scanningInputTextField];
        [scanningInputTextField becomeFirstResponder];
    }
}

#define HIGHLIGHT_RECT_THICKNESS 3
// Scanning support
- (void) scanPressed:(id)sender {
    if(scanningStyle == SCANNING_STYLE_STEP_SCAN) {
        [self highlightCurrentScanSelection:NO];
        indexOfCurrentScanSelection++;
        [self highlightCurrentScanSelection:YES];
    }
}

- (void) selectPressed:(id)sender {
    if(scanningStyle == SCANNING_STYLE_STEP_SCAN) {
        UIButton *panel = [[panelSelectionScrollView subviews] objectAtIndex:indexOfCurrentScanSelection*2];
        [self launchSwitchPanel:panel];
    }
}

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    for(int i=0; i < [string length]; ++i) {
        unichar keystroke = [string characterAtIndex:i];
        if((keystroke == ' ') || (keystroke == '1'))
            [self scanPressed:nil];
        if((keystroke == '\n') || (keystroke == '3'))
            [self selectPressed:nil];
    }
    return NO; // This field isn't visible anyway; don't update it
}

- (void) highlightCurrentScanSelection:(BOOL)highlight {
    if(indexOfCurrentScanSelection < 0)
        indexOfCurrentScanSelection = numberOfPanelsInScrollView-1;
    if(indexOfCurrentScanSelection >= numberOfPanelsInScrollView)
        indexOfCurrentScanSelection = 0;
    UIButton *panel = [[panelSelectionScrollView subviews] objectAtIndex:indexOfCurrentScanSelection*2 + 0];
    UITextView *text = [[panelSelectionScrollView subviews] objectAtIndex:indexOfCurrentScanSelection*2 + 1];
    // Expand panel when selected
    CGRect currentPanelRect = panel.layer.bounds;
    CGRect newPanelRect = currentPanelRect;
    newPanelRect.size.width = (highlight) ? panelButtonWidth+button_spacing : panelButtonWidth;
    newPanelRect.size.height = (highlight) ? panelButtonHeight+button_spacing : panelButtonHeight;
    [UIView beginAnimations:nil context:NULL];
    CGAffineTransform scaling = CGAffineTransformMakeScale(newPanelRect.size.width/currentPanelRect.size.width, newPanelRect.size.height/currentPanelRect.size.height);
    CGAffineTransform translateText = CGAffineTransformMakeTranslation(0, (newPanelRect.size.height-currentPanelRect.size.height)/2);
    panel.transform = scaling;
    text.transform = translateText;
    [UIView commitAnimations];
    //CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"bounds"];
    //animation.fromValue = [NSValue valueWithCGRect:currentPanelFrame];
    //animation.toValue = [NSValue valueWithCGRect:newPanelFrame];
    //panel.layer.bounds = newPanelFrame;
    //[panel.layer addAnimation:animation forKey:@"bounds"];
/*    UIColor *newColor = ((highlight)?[UIColor colorWithRed:0.5 green:0.5 blue:1.0 alpha:1.0]:[UIColor blackColor]);
    CGRect highlightFrame = [panel frame];
    highlightFrame.size.width += HIGHLIGHT_RECT_THICKNESS*2;
    highlightFrame.size.height += HIGHLIGHT_RECT_THICKNESS*2;
    highlightFrame.origin.x -= HIGHLIGHT_RECT_THICKNESS;
    highlightFrame.origin.y -= HIGHLIGHT_RECT_THICKNESS;
    [highlighting setFrame:highlightFrame];
    [highlighting setBackgroundColor:newColor];*/
    if(highlight) {
        // Reposition scroll to center the panel
        [panelSelectionScrollView scrollRectToVisible:[panel frame] animated:YES];
        [text setBackgroundColor:[UIColor colorWithRed:0.5 green:0.5 blue:1.0 alpha:1.0]];
        [text setTextColor:[UIColor blackColor]];
    } else {
        [text setTextColor:[UIColor whiteColor]];
        [text setBackgroundColor:[UIColor blackColor]];
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
    // When we're first run, display the quick-start wizard
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"firstRun"]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"firstRun"];
        [self display_qswizard:nil];
    }
}

- (void) viewDidAppear:(BOOL)animated {
    if(scanningStyle == SCANNING_STYLE_STEP_SCAN)
        [self highlightCurrentScanSelection:YES];
}

- (UIImage *) imageFromViewController:(UIViewController*)viewController scaledTo:(CGSize)scaledSize {
    // Create a graphics context large enough to hold the entire viewController image
    CGSize originalViewSize = [[viewController view] bounds].size;
    int unscaledBitmapByteCount = originalViewSize.width * originalViewSize.height * 4;
    void *bitmapData1 = malloc(unscaledBitmapByteCount);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context1 = CGBitmapContextCreate(bitmapData1, originalViewSize.width, originalViewSize.height, 8, originalViewSize.width*4, colorSpace, kCGImageAlphaPremultipliedLast);
    [[[viewController view] layer] renderInContext:context1];
    CGImageRef unscaledImageCG = CGBitmapContextCreateImage(context1);
    
    // Repeat process to scale image
    int scaledBitmapByteCount = scaledSize.width * scaledSize.height * 4;
    void *bitmapData2 = malloc(scaledBitmapByteCount);
    CGContextRef context2 = CGBitmapContextCreate(bitmapData2, scaledSize.width, scaledSize.height, 8, scaledSize.width*4, colorSpace, kCGImageAlphaPremultipliedLast);
    CGRect scaledImageRect = CGRectMake(0.0, 0.0, scaledSize.width, scaledSize.height);
    CGContextTranslateCTM(context2, 0, scaledSize.height);
    CGContextScaleCTM(context2, 1.0, -1.0);
    CGContextClearRect(context2, scaledImageRect);
    CGContextDrawImage(context2, scaledImageRect, unscaledImageCG);
    CGImageRef scaledImageCG = CGBitmapContextCreateImage(context2);
    UIImage *scaledImage = [UIImage imageWithCGImage:scaledImageCG];
    CGImageRelease(scaledImageCG);
    CGContextRelease(context2);
    free(bitmapData2);
    CGImageRelease(unscaledImageCG);
    viewController.view.layer.contents = nil; // Stackoverflow comment said this eliminates memory leak
    CGContextRelease(context1);
    free(bitmapData1);
    return scaledImage;
}

- (bool)addPanelButtonToScrollViewFromUrl:(NSURL*)url atOrigin:(CGPoint)origin withButtonSize:(CGSize)buttonSize andTextSize:(CGSize)textSize {
    if(url == nil)
        return false;
    int fontSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"textSizePreference"];
    numberOfPanelsInScrollView++;
    // Render view controller into image
    switchPanelViewController *viewController = [switchPanelViewController alloc];
    [viewController setUrlToLoad:url];
    [[viewController view] setFrame:CGRectMake(0, 20, 1024, 748)]; // Init as if we were full-size
    // Create the specified button
    id myButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [myButton setFrame:CGRectMake(origin.x, origin.y, buttonSize.width, buttonSize.height)];
    // Also set rectangle for label
    CGRect panelNameLabelRect = CGRectMake(origin.x, origin.y + buttonSize.height, buttonSize.width, textSize.height);
    [myButton addTarget:self action:@selector(launchSwitchPanel:) forControlEvents:(UIControlEventTouchUpInside)]; 
    [panelSelectionScrollView addSubview:myButton];
    UIImage *scaledImage = [self imageFromViewController:viewController scaledTo:[myButton bounds].size];
    [myButton setBackgroundImage:scaledImage forState:UIControlStateNormal];
    // Add text label
    UILabel *panelNameLabel = [[UILabel alloc] initWithFrame:panelNameLabelRect];
    [panelNameLabel setBackgroundColor:[UIColor blackColor]];
    [panelNameLabel setTextColor:[UIColor whiteColor]];
    [panelNameLabel setText:[viewController switchPanelName]];
    [myButton setTitle:[viewController switchPanelName] forState:UIControlStateNormal]; // Used by test code to find buttons
    [myButton setTitleColor:[UIColor clearColor] forState:UIControlStateNormal]; // Make title invisible
    [[myButton titleLabel] setFont:[UIFont systemFontOfSize:fontSize]];
    [panelNameLabel setTextAlignment:UITextAlignmentCenter];
    [panelNameLabel setFont:[UIFont systemFontOfSize:fontSize]];
    [panelSelectionScrollView addSubview:panelNameLabel];
    [[self switchPanelURLDictionary] setObject:url forKey:[NSValue valueWithNonretainedObject:myButton]];
    return true;
}

- (void)initializeScrollPanelWithTextSize:(CGSize)textSize {
    panelButtonWidth = panelButtonHeight + (panelButtonHeight/2);

    [switchPanelURLDictionary removeAllObjects];
    
    int current_button_x = button_spacing;
    int current_button_y = 0;
    // Create highlighter
    //[self setHighlighting:[[UIView alloc] initWithFrame:CGRectMake(current_button_x-HIGHLIGHT_RECT_THICKNESS, current_button_y-HIGHLIGHT_RECT_THICKNESS, panelButtonWidth+2*HIGHLIGHT_RECT_THICKNESS, panelButtonHeight+2*HIGHLIGHT_RECT_THICKNESS)]];
    //[panelSelectionScrollView addSubview:[self highlighting]];
    //[[self highlighting] setBackgroundColor:[UIColor blackColor]];
    numberOfPanelsInScrollView = 0;
    // Find all default switch panel files
    NSArray *xmlUrls = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"xml" subdirectory:nil];
    NSURL *url;
    for(url in xmlUrls) {
        // Only process built-in panels that we are supporting
        BOOL displayThisPanel = NO;
        BOOL isIR = [[NSPredicate predicateWithFormat:@"SELF CONTAINS \"ir_\""] evaluateWithObject:[url absoluteString]];
        BOOL isCtrl = [[NSPredicate predicateWithFormat:@"SELF CONTAINS \"ctrl_\""] evaluateWithObject:[url absoluteString]];
        BOOL isBlank = [[NSPredicate predicateWithFormat:@"SELF CONTAINS \"blank\""] evaluateWithObject:[url absoluteString]];
        if(isIR && [[NSUserDefaults standardUserDefaults] boolForKey:@"supportSwitchamajigIRPreference"])
            displayThisPanel = YES;
        if(isCtrl && [[NSUserDefaults standardUserDefaults] boolForKey:@"supportSwitchamajigControllerPreference"])
            displayThisPanel = YES;
        if(isBlank && [[NSUserDefaults standardUserDefaults] boolForKey:@"allowEditingOfSwitchPanelsPreference"])
            displayThisPanel = YES;
        if(displayThisPanel) {
            bool success = [self addPanelButtonToScrollViewFromUrl:url atOrigin:CGPointMake(current_button_x, current_button_y) withButtonSize:CGSizeMake(panelButtonWidth, panelButtonHeight) andTextSize:textSize];
            if(!success)
                continue;
            current_button_y += panelButtonHeight + textSize.height + button_spacing;
            if(current_button_y + panelButtonHeight + textSize.height >= [panelSelectionScrollView bounds].size.height) {
                current_button_y = 0;
                current_button_x += panelButtonWidth + button_spacing;
            }
        }
    }
    // Find all user switch panel files
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSArray *DocumentDirectoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:nil];
    NSString *filename;
    for(filename in DocumentDirectoryContents) {
        NSString *fullpath = [documentsDirectory stringByAppendingPathComponent:filename];
        // Only do xml files
        BOOL isXml = [[NSPredicate predicateWithFormat:@"SELF contains \".xml\""] evaluateWithObject:fullpath];
        if(!isXml)
            continue;
        url = [NSURL fileURLWithPath:fullpath];
        bool success = [self addPanelButtonToScrollViewFromUrl:url atOrigin:CGPointMake(current_button_x, current_button_y) withButtonSize:CGSizeMake(panelButtonWidth, panelButtonHeight) andTextSize:textSize];
        if(!success)
            continue;
        current_button_y += panelButtonHeight + textSize.height + button_spacing;
        if(current_button_y + panelButtonHeight + textSize.height >= [panelSelectionScrollView bounds].size.height) {
            current_button_y = 0;
            current_button_x += panelButtonWidth + button_spacing;
        }
    }
    if(current_button_y != button_spacing)
        current_button_x += panelButtonWidth + button_spacing;
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
    if(interfaceOrientation == UIInterfaceOrientationLandscapeRight)
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
    [self ResetScrollPanel];
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

- (void)display_qswizard:(id)sender {
    [[self navigationController] setNavigationBarHidden:NO];
    quickStartSettingsViewController *qsViewCtrl = [quickStartSettingsViewController alloc];
    [qsViewCtrl setAppDelegate:appDelegate];
    [self.navigationController pushViewController:qsViewCtrl animated:YES];
}

- (void)config_pressed:(id)sender {
    SwitchamajigControllerDeviceDriver *driver = [appDelegate firstSwitchamajigControllerDriver];
    if(driver) {
        NSString *name = [[[appDelegate friendlyNameSwitchamajigDictionary] allKeysForObject:driver] objectAtIndex:0];
        configViewController *configViewCtrl = [[configViewController alloc] initWithNibName:@"configViewController" bundle:nil];
        [configViewCtrl setModalPresentationStyle:UIModalPresentationFormSheet];
        [configViewCtrl setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        [configViewCtrl setDriver:driver];
        configViewCtrl->appDelegate = appDelegate;
        configViewCtrl->switchName = name;
        [self presentModalViewController:configViewCtrl animated:YES];
    }
}


@end
