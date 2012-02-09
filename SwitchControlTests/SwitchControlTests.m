//
//  SwitchControlTests.m
//  SwitchControlTests
//
//  Created by Phil Weaver on 7/23/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import "SwitchControlTests.h"

@implementation SwitchControlTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    app_delegate = [[UIApplication sharedApplication] delegate];
    nav_controller = [app_delegate navigationController];
    rootViewController = [[nav_controller viewControllers] objectAtIndex:0];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testAppDelegate
{
    STAssertNotNil(app_delegate, @"Can't find application delegate");
}

- (void)testHelp
{
    STAssertTrue(nav_controller.navigationBarHidden, @"Navigation bar not hidden in root view.");
    [[rootViewController helpButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertFalse(nav_controller.navigationBarHidden, @"Navigation bar hidden on help screen.");
    [nav_controller popViewControllerAnimated:NO];
    [rootViewController viewWillAppear:YES];
    STAssertTrue(nav_controller.navigationBarHidden, @"Navigation bar not hidden in root view after help.");
}

- (void)testFirstViewController
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
    STAssertTrue((CFDictionaryGetCount([panel buttonToSwitchDictionary]) > 0), @"No switches in dictionary");
    [panel->myButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertFalse([panel->backButton isEnabled], @"Back button did not disable on switch press in switch panel");
    [panel->allowNavButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [panel->backButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertTrue([[nav_controller visibleViewController] isKindOfClass:[rootSwitchViewController class]], @"Back button did not display root switch controller");
}

@end
