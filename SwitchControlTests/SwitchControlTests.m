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
    // Call loadview
    [rootViewController loadView];
    // Confirm that help button exists
    STAssertNotNil([rootViewController helpButton], @"Scan Button nil when scanning enabled");
    // Check that the nav bar appears and disappears as designed
    STAssertTrue(nav_controller.navigationBarHidden, @"Navigation bar not hidden in root view.");
    [[rootViewController helpButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertFalse(nav_controller.navigationBarHidden, @"Navigation bar hidden on help screen.");
    [nav_controller popViewControllerAnimated:NO];
    [rootViewController viewWillAppear:YES];
    STAssertTrue(nav_controller.navigationBarHidden, @"Navigation bar not hidden in root view after help.");
    // Confirm that help button does not appear when scanning enabled
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enableScanningPreference"];
    [rootViewController loadView];
    STAssertNil([rootViewController helpButton], @"Scan Button nil when scanning enabled");
    // Confirm that help button does not appear when preference say not to
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"enableScanningPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showHelpButtonPreference"];
    [rootViewController loadView];
    STAssertNil([rootViewController helpButton], @"Scan Button nil when scanning enabled");

}

- (void)test_001_RootViewController_002_ScanningEnabled
{
    // Disable scanning
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"enableScanningPreference"];
    // Call loadview
    [rootViewController loadView];
    // Confirm no scan or select button
    STAssertNil([rootViewController scanButton], @"Scan Button not nil when scanning disabled");
    STAssertNil([rootViewController selectButton], @"Scan Button not nil when scanning disabled");
    // Enable scanning, set select on left
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enableScanningPreference"];
    // Call loadview
    [rootViewController loadView];
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
    // Call loadview
    [rootViewController loadView];
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
    // Call loadview
    [rootViewController loadView];
    // Confirm everything is set up as specified
    STAssertTrue([[rootViewController scanButton] backgroundColor] == [UIColor blueColor], @"Scan Button not yellow as preferences specify");
    STAssertTrue([[rootViewController selectButton] backgroundColor] == [UIColor redColor], @"Select Button not green as preferences specify");
    scanFrame = [[rootViewController scanButton] frame];
    selectFrame = [[rootViewController selectButton] frame];
    STAssertTrue((selectFrame.origin.x > scanFrame.origin.x), @"Select Button x coord %f not right of scan button x coord %f", selectFrame.origin.x, scanFrame.origin.x);
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

- (void)test_001_RootViewController_004_TextSize {
    float textSize = 15;
    [[NSUserDefaults standardUserDefaults] setFloat:textSize forKey:@"textSizePreference"];
    // Text size with no help, config, or scan
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"enableScanningPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showHelpButtonPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showNetworkConfigButtonPreference"];
    [rootViewController loadView]; 
    STAssertTrue([SwitchControlTests CheckAllTextInView:[rootViewController view] hasSize:textSize], @"Text Size Check Failed. Size = %f, no help or config buttons", textSize);
    // Text size with help and config
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showHelpButtonPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showNetworkConfigButtonPreference"];
    [rootViewController loadView]; 
    STAssertTrue([SwitchControlTests CheckAllTextInView:[rootViewController view] hasSize:textSize], @"Text Size Check Failed. Size = %f, help and config buttons", textSize);
    // Text size with scanning
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enableScanningPreference"];
    [rootViewController loadView]; 
    STAssertTrue([SwitchControlTests CheckAllTextInView:[rootViewController view] hasSize:textSize], @"Text Size Check Failed. Size = %f, scanning", textSize);
    
    // Check with large text size
    textSize = 50;
    [[NSUserDefaults standardUserDefaults] setFloat:textSize forKey:@"textSizePreference"];
    // Text size with no help, config, or scan
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"enableScanningPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showHelpButtonPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showNetworkConfigButtonPreference"];
    [rootViewController loadView]; 
    STAssertTrue([SwitchControlTests CheckAllTextInView:[rootViewController view] hasSize:textSize], @"Text Size Check Failed. Size = %f, no help or config buttons", textSize);
    // Text size with help and config
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showHelpButtonPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showNetworkConfigButtonPreference"];
    [rootViewController loadView]; 
    STAssertTrue([SwitchControlTests CheckAllTextInView:[rootViewController view] hasSize:textSize], @"Text Size Check Failed. Size = %f, help and config buttons", textSize);
    // Text size with scanning
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enableScanningPreference"];
    [rootViewController loadView]; 
    STAssertTrue([SwitchControlTests CheckAllTextInView:[rootViewController view] hasSize:textSize], @"Text Size Check Failed. Size = %f, scanning", textSize);
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

- (void) test_003_UDPConnect
{
    // Change the settings to UDP
    [app_delegate setSettings_switch_connection_protocol:IPPROTO_UDP];
    // Wait for the table to contain a switch name
    for(int i=0; i < 20; ++i) {
        if([[rootViewController switchNameTableView] numberOfRowsInSection:0])
            break;
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1]];
    }
    STAssertTrue([[rootViewController switchNameTableView] numberOfRowsInSection:0] > 0, @"Unable to find switch");
    // Connect to the switch
    NSIndexPath *iPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [rootViewController tableView:[rootViewController switchNameTableView] didSelectRowAtIndexPath:iPath];
    // Confirm that the table says "Connected"
    NSString *connectedText = [[[[rootViewController switchNameTableView] cellForRowAtIndexPath:iPath] detailTextLabel] text];
    STAssertEqualObjects(connectedText, @"Connected", @"Did not report connection for UDP");
}

- (void) test_004_TCPConnect
{
    // Change the settings to UDP
    [app_delegate setSettings_switch_connection_protocol:IPPROTO_TCP];
    // Wait for the table to contain a switch name
    for(int i=0; i < 20; ++i) {
        if([[rootViewController switchNameTableView] numberOfRowsInSection:0])
            break;
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1]];
    }
    STAssertTrue([[rootViewController switchNameTableView] numberOfRowsInSection:0] > 0, @"Unable to find switch");
    // Connect to the switch
    NSIndexPath *iPath = [NSIndexPath indexPathForRow:0 inSection:0];
    [rootViewController tableView:[rootViewController switchNameTableView] didSelectRowAtIndexPath:iPath];
    // Confirm that the table says "Connected"
    NSString *connectedText = [[[[rootViewController switchNameTableView] cellForRowAtIndexPath:iPath] detailTextLabel] text];
    STAssertEqualObjects(connectedText, @"Connected", @"Did not report connection for UDP");
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
