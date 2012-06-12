//
//  SwitchControlTests.m
//  SwitchControlTests
//
//  Created by Phil Weaver on 7/23/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import "SwitchControlTests.h"
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

@implementation SwitchControlTests

- (void) reloadRootViewController {
    // Initialize the root view controller
    [app_delegate setNavigationController:[[UINavigationController alloc] initWithRootViewController:[[rootSwitchViewController alloc] initWithNibName:nil bundle:nil]]];
    [[app_delegate window] setRootViewController: [app_delegate navigationController]];
    [app_delegate.window makeKeyAndVisible];  
    UIView *newView = [rootViewController view];
    newView = newView;
    nav_controller = [app_delegate navigationController];
    rootViewController = [[nav_controller viewControllers] objectAtIndex:0];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1.0]];

}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    app_delegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication] delegate];
    nav_controller = [app_delegate navigationController];
    rootViewController = [[nav_controller viewControllers] objectAtIndex:0];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)test_000_AppDelegate
{
    STAssertNotNil(app_delegate, @"Can't find application delegate");
}

- (void)test_001_RootViewController_001_Help
{
    // Disable scanning, enable help button
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"enableScanningPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showHelpButtonPreference"];
    [self reloadRootViewController];
    // Confirm that help button exists
    STAssertNotNil([rootViewController helpButton], @"Help button not appearing");
    // Check that the nav bar appears and disappears as designed
    STAssertTrue(nav_controller.navigationBarHidden, @"Navigation bar not hidden in root view.");
    [[rootViewController helpButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertFalse(nav_controller.navigationBarHidden, @"Navigation bar hidden on help screen.");
    [nav_controller popViewControllerAnimated:NO];
    [rootViewController viewWillAppear:YES];
    STAssertTrue(nav_controller.navigationBarHidden, @"Navigation bar not hidden in root view after help.");
    // Confirm that help button does not appear when scanning enabled
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enableScanningPreference"];
    [self reloadRootViewController];
    STAssertNil([rootViewController helpButton], @"Scan Button nil when scanning enabled");
    // Confirm that help button does not appear when preference say not to
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"enableScanningPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showHelpButtonPreference"];
    [self reloadRootViewController];
    STAssertNil([rootViewController helpButton], @"Scan Button nil when scanning enabled");

}

- (void)test_001_RootViewController_002_ScanningEnabled
{
    // Disable scanning
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"enableScanningPreference"];
    [self reloadRootViewController];
    // Confirm no scan or select button
    STAssertNil([rootViewController scanButton], @"Scan Button not nil when scanning disabled");
    STAssertNil([rootViewController selectButton], @"Scan Button not nil when scanning disabled");
    // Enable scanning, set select on left
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enableScanningPreference"];
    [self reloadRootViewController];
    // Confirm scan and select buttons exist
    STAssertNotNil([rootViewController scanButton], @"Scan Button nil when scanning enabled");
    STAssertNotNil([rootViewController selectButton], @"Scan Button nil when scanning enabled");
}

- (void)test_001_RootViewController_003_ScanningOptions
{
    // Enable scanning, select button on left and green, scan button yellow
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enableScanningPreference"];
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"selectButtonOnLeftPreference"];
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"selectButtonColorPreference"];
    [[NSUserDefaults standardUserDefaults] setInteger:3 forKey:@"scanButtonColorPreference"];
    [self reloadRootViewController];
    // Confirm everything is set up as specified
    STAssertTrue([[rootViewController scanButton] backgroundColor] == [UIColor yellowColor], @"Scan Button not yellow as preferences specify");
    STAssertTrue([[rootViewController selectButton] backgroundColor] == [UIColor greenColor], @"Select Button not green as preferences specify");
    CGRect scanFrame = [[rootViewController scanButton] frame];
    CGRect selectFrame = [[rootViewController selectButton] frame];
    STAssertTrue((selectFrame.origin.x < scanFrame.origin.x), @"Select Button x coord %f not left of scan button x coord %f", selectFrame.origin.x, scanFrame.origin.x);
    // Move select button to right, make it red, make scan button blue
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enableScanningPreference"];
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"selectButtonOnLeftPreference"];
    [[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"selectButtonColorPreference"];
    [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"scanButtonColorPreference"];
    [self reloadRootViewController];
    // Confirm everything is set up as specified
    STAssertTrue([[rootViewController scanButton] backgroundColor] == [UIColor blueColor], @"Scan Button not yellow as preferences specify");
    STAssertTrue([[rootViewController selectButton] backgroundColor] == [UIColor redColor], @"Select Button not green as preferences specify");
    scanFrame = [[rootViewController scanButton] frame];
    selectFrame = [[rootViewController selectButton] frame];
    STAssertTrue((selectFrame.origin.x > scanFrame.origin.x), @"Select Button x coord %f not right of scan button x coord %f", selectFrame.origin.x, scanFrame.origin.x);
}


+ (int) numberOfSubviewOverlapsInView:(UIView *)view {
    NSArray *theSubviews = [view subviews];
    int numOverlaps = 0;
    int i;
    for(i=0; i < [theSubviews count]; ++i) {
        CGRect rect1 = [[theSubviews objectAtIndex:i] frame];
        int j;
        for(j=i+1; j < [theSubviews count]; ++j) {
            CGRect rect2 = [[theSubviews objectAtIndex:j] frame];
            if(CGRectIntersectsRect(rect1, rect2)) {
                NSLog(@"Intersecting rectangles: (%4.1f, %4.1f, %4.1f, %4.1f) and (%4.1f, %4.1f, %4.1f, %4.1f)", rect1.origin.x, rect1.origin.y, rect1.size.width, rect1.size.height, rect2.origin.x, rect2.origin.y, rect2.size.width, rect2.size.height);
                numOverlaps++;
            }
        }
        numOverlaps += [SwitchControlTests numberOfSubviewOverlapsInView:[theSubviews objectAtIndex:i]];
    }
    return numOverlaps;
}

+ (int) numberOfSubviewsOutsideParents:(UIView *)view {
    int numOutOfBounds = 0;
    UIView *subView;
    for(subView in [view subviews]) {
        CGRect rect1 = [[subView superview] frame];
        if([[subView superview] isKindOfClass:[UIScrollView class]]) {
            // For scroll view, use content area, not frame
            UIScrollView *scrollView = (UIScrollView *)[subView superview];
            rect1.size = [scrollView contentSize];
        }
        rect1.origin.x = rect1.origin.y = 0; // Make origin relative to child views
        CGRect rect2 = [subView frame];
        if(!CGRectContainsRect(rect1, rect2)) {
            NSLog(@"Out-of-bounds: (%4.1f, %4.1f, %4.1f, %4.1f) doesn't contain (%4.1f, %4.1f, %4.1f, %4.1f)", rect1.origin.x, rect1.origin.y, rect1.size.width, rect1.size.height, rect2.origin.x, rect2.origin.y, rect2.size.width, rect2.size.height);
            numOutOfBounds++;
        }
        numOutOfBounds += [SwitchControlTests numberOfSubviewsOutsideParents:subView];
    }
    return numOutOfBounds;
}

+ (BOOL) CheckAllTextInView:(UIView *)view hasSize:(float)size {
    UIView *subView;
    for(subView in [view subviews]) {
        //NSLog(@"Checking subview");
        NSString *title = nil;
        CGFloat fontSize;
        if([subView isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subView;
            title = [button titleForState:UIControlStateNormal];
            fontSize = [[[button titleLabel] font] pointSize];
            //NSLog(@" Subview is button. Title = %@, fontsize = %f", title, fontSize);
        }
        if([subView isKindOfClass:[UILabel class]]) {
           UILabel *textView = (UILabel *)subView;
            title = [textView text];
            fontSize = [[textView font]pointSize];
            //NSLog(@" Subview is UILabel. Title = %@, fontsize = %f", title, fontSize);
        }
        if(title != nil) {
            //NSLog(@"Checking size for title %@", title);
        }
        if((title != nil) && (fontSize != size)) {
            NSLog(@"Size does not match with title: %@", title);
            return NO;
        }
        if(![SwitchControlTests CheckAllTextInView:subView hasSize:size])
            return NO;
    }
    // If nothing failed or the list is empty, we're good
    return YES;
}

- (void)test_001_RootViewController_004_TextAndButtonSizes {
    const int num_expected_overlaps = 2; // Highlighting overlaps one button and one text label
    const int num_expected_outofbounds = 1; // Highlighting goes outside the scroll view
    const int numTextSizes = 3;
    float textSizes[numTextSizes] = {15, 50, 100};
    const int numTestConditions = 3;
    const int numButtonSizes = 3;
    float buttonSizes[numButtonSizes] = {100, 200, 500};
    for(int textSizeIndex=0; textSizeIndex < numTextSizes; ++textSizeIndex) {
        float textSize = textSizes[textSizeIndex];
        [[NSUserDefaults standardUserDefaults] setFloat:textSize forKey:@"textSizePreference"];
        for(int testConditionIndex = 0; testConditionIndex < numTestConditions; ++testConditionIndex) {
            switch(testConditionIndex) {
                case 0:
                    // Text size with no help, config, or scan
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"enableScanningPreference"];
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showHelpButtonPreference"];
                    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showNetworkConfigButtonPreference"];
                    break;
                case 1:
                    // Text size with help and config
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showHelpButtonPreference"];
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showNetworkConfigButtonPreference"];
                    break;
                case 2:
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enableScanningPreference"];
                    break;
                default:
                    STFail(@"Test condition not handled.");
            }
            for(int buttonSizeIndex = 0; buttonSizeIndex < numButtonSizes; ++buttonSizeIndex) {
                float buttonSize = buttonSizes[buttonSizeIndex];
                NSLog(@"Test iteration start. textSize = %f, conditionsIndex = %d, buttonSize = %f", textSize, testConditionIndex, buttonSize);
                [[NSUserDefaults standardUserDefaults] setFloat:buttonSize forKey:@"switchPanelSizePreference"];
                // Update the view, and then run the tests
                [self reloadRootViewController];
                NSLog(@"Returned");
                // Confirm text sizes
                STAssertTrue([SwitchControlTests CheckAllTextInView:[rootViewController view] hasSize:textSize], @"Text Size Check Failed. textSize = %f, conditionsIndex = %d, buttonSize = %f", textSize, testConditionIndex, buttonSize);
                // Make sure we don't have inappropriate overlaps
                int numOverlaps = [SwitchControlTests numberOfSubviewOverlapsInView:[rootViewController view]];
                STAssertTrue((numOverlaps == num_expected_overlaps), @"Overlapping views: found %d != expected %d textSize = %f, conditionsIndex = %d, buttonSize = %f", numOverlaps, num_expected_overlaps, textSize, testConditionIndex, buttonSize);
                // Stuff should (generally) be inside its parent view
                int numOutOfBounds = [SwitchControlTests numberOfSubviewsOutsideParents:[rootViewController view]];
                STAssertTrue((numOutOfBounds == num_expected_outofbounds), @"Out of bounds views: found %d != expected %d textSize = %f, conditionsIndex = %d, buttonSize = %f", numOutOfBounds, num_expected_outofbounds, textSize, testConditionIndex, buttonSize);
                NSLog(@"Test iteration complete. textSize = %f, conditionsIndex = %d, buttonSize = %f", textSize, testConditionIndex, buttonSize);
            }
        }
    }
    NSLog(@"Test 004 complete.");
}

- (void)test_001_RootViewController_005_ButtonSize {
    // Small buttons
    // No scanning, help, or config
    // No scanning, but help and config buttons
    // Scanning
}

#if 0
- (void)test_002_FirstViewController
{
    // Select the first switch panel
    [[[[rootViewController panelSelectionScrollView] subviews] objectAtIndex:0] sendActionsForControlEvents:UIControlEventTouchUpInside];
    switchPanelViewController *panel = (switchPanelViewController *) [nav_controller visibleViewController];
    STAssertTrue([panel isKindOfClass:[switchPanelViewController class]], @"Switch panel did not display");
    // Make sure panel loads a view
    UIView *panelView = [panel view];
    panelView = panelView;
    // Check that the back button exists
    STAssertFalse([panel->backButton isEnabled], @"Back button is enabled in switch panel");
    [panel->allowNavButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertTrue([panel->backButton isEnabled], @"Back button did not enable in switch panel");
    // Retrieve the first switch from the dictionary
    STAssertTrue([[panel buttonToSwitchDictionary] count] > 0, @"No switches in dictionary");
    [panel->myButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertFalse([panel->backButton isEnabled], @"Back button did not disable on switch press in switch panel");
    [panel->allowNavButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [panel->backButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertTrue([[nav_controller visibleViewController] isKindOfClass:[rootSwitchViewController class]], @"Back button did not display root switch controller");
}


-(void) test_005_ConfigNavigation
{
    // Connect as UDP
    [self test_003_UDPConnect];
    // Confirm presence of config button for iOS >= 5.0, absence of config button for lower versions
    UIButton *configButton = [rootViewController ConfigButton];
    if(SYSTEM_VERSION_LESS_THAN(@"5.0")) {
        STAssertTrue([configButton isHidden], @"Config Button Visible for iOS < 5.0");
        return;
    }
    STAssertFalse([configButton isHidden], @"Config Button Not Visible for iOS >= 5.0");
    [rootViewController config_pressed:nil];
    // Confirm that the config window appeared
    configViewController *configVC = (configViewController *) [nav_controller visibleViewController];
    STAssertTrue([configVC isKindOfClass:[configViewController class]], @"Config window did not display");
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)2]];
    [configVC Cancel:nil];
    // Give the window a couple of seconds to disappear
    for(int i=0; i < 10; ++i) {
        if([[nav_controller visibleViewController] isKindOfClass:[rootSwitchViewController class]])
            break;
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1]];
    }
    STAssertTrue([[nav_controller visibleViewController] isKindOfClass:[rootSwitchViewController class]], @"Failed to cancel out of config window.");
}
#endif
@end
