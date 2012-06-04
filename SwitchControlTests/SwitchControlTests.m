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

- (void)test_001_Help
{
    STAssertTrue(nav_controller.navigationBarHidden, @"Navigation bar not hidden in root view.");
    [[rootViewController helpButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertFalse(nav_controller.navigationBarHidden, @"Navigation bar hidden on help screen.");
    [nav_controller popViewControllerAnimated:NO];
    [rootViewController viewWillAppear:YES];
    STAssertTrue(nav_controller.navigationBarHidden, @"Navigation bar not hidden in root view after help.");
}

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
@end
