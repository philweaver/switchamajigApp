//
//  switchPanelViewControllerTests.m
//  SwitchControl
//
//  Created by Phil Weaver on 11/7/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "switchPanelViewControllerTests.h"

@implementation switchPanelViewControllerTests
- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
    savedDefaults = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"scanningStylePreference"];
    
}

- (void)tearDown
{
    // Tear-down code here.
    NSString *key;
    for(key in [savedDefaults allKeys]) {
        [[NSUserDefaults standardUserDefaults] setObject:[savedDefaults objectForKey:key] forKey:key];
    }
    [super tearDown];
}

- (void)test_002_SwitchPanelViewController_011_Scanning {
    // Disable scanning
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"scanningStylePreference"];
    // Create a panel from a test XML file
    switchPanelViewController *viewController = [switchPanelViewController alloc];
    // Open the test xml file
    NSURL *originalURL = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"__TEST001" ofType:@"xml"]];
    [viewController setUrlToLoad:originalURL];
    UIView *view = [viewController view];
    [viewController viewDidAppear:NO];
    CGRect button0Rect = ((UIButton *)[[view subviews] objectAtIndex:0]).frame;
    CGRect button1Rect = ((UIButton *)[[view subviews] objectAtIndex:1]).frame;
    CGRect button2Rect = ((UIButton *)[[view subviews] objectAtIndex:2]).frame;
    STAssertTrue(button0Rect.size.width == 924, @"Button0 width=%d wrong for no scanning", button0Rect.size.width);
    STAssertTrue(button1Rect.size.width == 944, @"Button1 width=%d wrong for no scanning", button1Rect.size.width);
    STAssertTrue(button2Rect.size.width == 944, @"Button2 width=%d wrong for no scanning", button2Rect.size.width);
    // Repeat with step scanning
    [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"scanningStylePreference"];
    viewController = [switchPanelViewController alloc];
    [viewController setUrlToLoad:originalURL];
    view = [viewController view];
    [viewController viewDidAppear:NO];
    button0Rect = ((UIButton *)[[view subviews] objectAtIndex:0]).frame;
    button1Rect = ((UIButton *)[[view subviews] objectAtIndex:1]).frame;
    button2Rect = ((UIButton *)[[view subviews] objectAtIndex:2]).frame;
    STAssertTrue(button0Rect.size.width == 924, @"Button0 width=%f wrong for step scanning with button 1 selected", button0Rect.size.width);
    STAssertTrue(button1Rect.size.width == 994, @"Button1 width=%f wrong for step scanning with button 1 selected", button1Rect.size.width);
    STAssertTrue(button2Rect.size.width == 944, @"Button2 width=%f wrong for step scanning with button 1 selected", button2Rect.size.width);

#if 0
    // Create a root view controller
    rootViewController = [[rootSwitchViewController alloc] initWithNibName:nil bundle:nil];
    MockNavigationController *naviControl = [[MockNavigationController alloc] initWithRootViewController:rootViewController];
    UIView *rootView = [rootViewController view];
    UIView *subView;
    for (subView in [rootView subviews]) {
        STAssertFalse([subView isKindOfClass:[UITextField class]], @"There should be no UITextField in the root view controller when scanning is off");
    }
    // Enable step scanning; should get UITextView
    [[NSUserDefaults standardUserDefaults] setInteger:2 forKey:@"scanningStylePreference"];
    rootViewController = [[rootSwitchViewController alloc] initWithNibName:nil bundle:nil];
    naviControl = [[MockNavigationController alloc] initWithRootViewController:rootViewController];
    rootView = [rootViewController view];
    [rootViewController viewDidAppear:NO];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    UITextField *scanningTextField = nil;
    for (subView in [rootView subviews]) {
        if([subView isKindOfClass:[UITextField class]]) {
            scanningTextField = (UITextField *)subView;
            scanningTextField = (UITextField *) subView;
            STAssertTrue([scanningTextField isHidden], @"Scanning textField is not first hidden");
        }
    }
    STAssertNotNil(scanningTextField, @"Cannot find UITextField in root view controller for step scanning");
    // Make sure the first subview of the scroll panel is highlighted
    UIButton *firstButton = (UIButton *) [[[rootViewController panelSelectionScrollView] subviews] objectAtIndex:0];
    UIButton *secondButton = (UIButton *) [[[rootViewController panelSelectionScrollView] subviews] objectAtIndex:2];
    int width1 = [firstButton frame].size.width;
    int width2 = [secondButton frame].size.width;
    STAssertTrue(width1 > width2, @"With step scanning enabled, first button should be larger to show selection width1 = %d, width2 = %d", width1, width2);
    // Advance the scanning
    [[scanningTextField delegate] textField:scanningTextField shouldChangeCharactersInRange:NSMakeRange(0,0) replacementString:@" "];
    STAssertTrue([firstButton frame].size.width < [secondButton frame].size.width, @"Button size suggests that scanning did not work");
    // Launch a panel
    naviControl->didReceivePushViewController = NO;
    [[scanningTextField delegate] textField:scanningTextField shouldChangeCharactersInRange:NSMakeRange(0,0) replacementString:@"3"];
    STAssertTrue(naviControl->didReceivePushViewController, @"Scanning didn't launch a switch panel");
#endif
}

@end
