//
//  switchPanelViewControllerTests.m
//  SwitchControl
//
//  Created by Phil Weaver on 11/7/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "switchPanelViewControllerTests.h"
#import "rootSwitchViewController.h"
#import "TestMocks.h"
#import "TestEnables.h"

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

#if RUN_ALL_SWITCH_PANEL_VC_TESTS
- (void)test_002_SwitchPanelViewController_001_PanelLayout {
    // Make sure panel displays properly
    switchPanelViewController *viewController = [switchPanelViewController alloc];
    [viewController setUrlToLoad:[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"ctrl_6_tworows" ofType:@"xml"]]];
    UIView *thisView;
    BOOL didFindFirstButton = NO;
    BOOL didFindLastButton = NO;
    for(thisView in [[viewController view] subviews]) {
        CGRect frame = [thisView frame];
        //NSLog(@"x = %f, y = %f, w = %f, h = %f", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
        if((frame.origin.x == 50) && (frame.origin.y == 50) && (frame.size.width == 274) && (frame.size.height == 294)) {
            CGFloat red, green, blue, alpha;
            [[thisView backgroundColor] getRed:&red green:&green blue:&blue alpha:&alpha];
            if((red == 0.0) && (green == 1.0) && (blue == 0.0) && (alpha == 1.0))
                didFindFirstButton = YES;
        }
        if((frame.origin.x == 698) && (frame.origin.y == 394) && (frame.size.width == 274) && (frame.size.height == 294)) {
            CGFloat red, green, blue, alpha;
            [[thisView backgroundColor] getRed:&red green:&green blue:&blue alpha:&alpha];
            if((red == 1.0) && (green == 0.0) && (blue == 1.0) && (alpha == 1.0))
                didFindLastButton = YES;
        }
    }
    STAssertTrue(didFindFirstButton, @"First button in ctrl_6_tworows.xml does not exist.");
    STAssertTrue(didFindLastButton, @"Last button in ctrl_6_tworows.xml does not exist.");
}

- (void)test_002_SwitchPanelViewController_002_BackButton {
    // Confirm that the back button works properly
    // Turn off panel editing, as during editing we suspend the two-button back
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"allowEditingOfSwitchPanelsPreference"];
    // Set up settings to require two-button back
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"singleTapBackButtonPreference"];
    // Load panel that has both back and enable
    switchPanelViewController *viewController = [switchPanelViewController alloc];
    [viewController setUrlToLoad:[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"__TEST001" ofType:@"xml"]]];
    // Confirm that back button is disabled and enable button is displayed
    UIView *currentView = [viewController view];
    id backButton = [HandyTestStuff findSubviewOf:currentView withText:@"Back"];
    id enableBackButton = [HandyTestStuff findSubviewOf:currentView withText:@"Enable Back Button"];
    STAssertNotNil(backButton, enableBackButton, @"Either the Back or the Back Enable Button doesn't exist");
    STAssertFalse([backButton isEnabled], @"Back button enabled before enable button pressed");
    // Enable the back button
    [enableBackButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    // Confirm that back button is enabled
    STAssertTrue([backButton isEnabled], @"Back button not enabled after enable button pressed");
    // Touch a different control
    [[HandyTestStuff findSubviewOf:currentView withText:@"1"] sendActionsForControlEvents:UIControlEventTouchUpInside];
    // Confirm that back button is disabled again
    STAssertFalse([backButton isEnabled], @"Back button still enabled after pressing another control");
    // Change setting for one-button back
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"singleTapBackButtonPreference"];
    // Re-create panel
    viewController = [switchPanelViewController alloc];
    [viewController setUrlToLoad:[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"__TEST001" ofType:@"xml"]]];
    currentView = [viewController view];
    // Confirm that the back button is enabled and enable button is not displayed
    backButton = [HandyTestStuff findSubviewOf:currentView withText:@"Back"];
    enableBackButton = [HandyTestStuff findSubviewOf:currentView withText:@"Enable Back Button"];
    STAssertNotNil(backButton, @"Back button doesn't exist with single-button navigation");
    STAssertNil(enableBackButton, @"Enable Back button exists with single-button navigation");
    STAssertTrue([backButton isEnabled], @"Back button not enabled with single-button navigation");
    // Confirm that the back button works
    rootSwitchViewController *rootViewController = [[rootSwitchViewController alloc] initWithNibName:nil bundle:nil];
    MockNavigationController *naviControl = [[MockNavigationController alloc] initWithRootViewController:rootViewController];
    [naviControl pushViewController:viewController animated:NO];
    naviControl->didReceivePopViewController = NO;
    [backButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertTrue(naviControl->didReceivePopViewController, @"Back button didn't work");
}


- (void)test_002_SwitchPanelViewController_003_CommandProcessing {
    // Set ourselves up to intercept commands sent to the delegate
    MockSwitchControlDelegate *myDelegate = [MockSwitchControlDelegate alloc];
    myDelegate->commandsReceived = [[NSMutableArray alloc] initWithCapacity:5];
    switchPanelViewController *viewController = [switchPanelViewController alloc];
    // Open the test xml file
    [viewController setUrlToLoad:[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"__TEST001" ofType:@"xml"]]];
    // Force the view to load
    UIView *theView = [viewController view];
    // Now change the delegate
    viewController->appDelegate = myDelegate;
    // Press the button
    id button = [HandyTestStuff findSubviewOf:theView withText:@"1"];
    [button sendActionsForControlEvents:UIControlEventTouchDown];
    // Verify the command sent is correct
    DDXMLNode *node = [myDelegate->commandsReceived objectAtIndex:0];
    NSString *xmlstring = [node XMLString];
    NSString *expectedString = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><turnSwitchesOn>1</turnSwitchesOn></actionsequence></actionsequenceondevice>";
    STAssertTrue([xmlstring isEqualToString:expectedString], @"Received %@ on press down", xmlstring);
    // Release the button and verify again
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    xmlstring = [[myDelegate->commandsReceived objectAtIndex:1] XMLString];
    expectedString = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><turnSwitchesOff>1</turnSwitchesOff></actionsequence></actionsequenceondevice>";
    STAssertTrue([xmlstring isEqualToString:expectedString], @"Received %@ on release", xmlstring);
    // Check a button with multiple steps
    button = [HandyTestStuff findSubviewOf:theView withText:@"2"];
    [myDelegate->commandsReceived removeAllObjects];
    [button sendActionsForControlEvents:UIControlEventTouchDown];
    xmlstring = [[myDelegate->commandsReceived objectAtIndex:0] XMLString];
    expectedString = @"<actionsequenceondevice><loop><friendlyname>Hoopy</friendlyname><turnSwitchesOn>1</turnSwitchesOn><delay>0.5</delay><turnSwitchesOff>1</turnSwitchesOff><turnSwitchesOn>2</turnSwitchesOn><delay>0.5</delay><turnSwitchesOff>2</turnSwitchesOff></loop></actionsequenceondevice>";
    STAssertTrue([xmlstring isEqualToString:expectedString], @"Received %@ on press down", xmlstring);
    [button sendActionsForControlEvents:UIControlEventTouchUpInside];
    xmlstring = [[myDelegate->commandsReceived objectAtIndex:1] XMLString];
    expectedString = @"<actionsequenceondevice><friendlyname>Hoopy</friendlyname><stoploop></stoploop><actionsequence><turnSwitchesOff>1 2</turnSwitchesOff></actionsequence></actionsequenceondevice>";
    STAssertTrue([xmlstring isEqualToString:expectedString], @"Received %@ on release", xmlstring);
}

// Test that saving a switch panel works properly
- (void)test_002_SwitchPanelViewController_004_SavePanel {
    // Create a file name that won't conflict with anything
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    NSString * filename = (__bridge_transfer NSString*)CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    CFRelease(newUniqueId);
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSURL *newFileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:filename]];
    
    // Create a panel from a test XML file and enable configuration mode
    switchPanelViewController *viewController = [switchPanelViewController alloc];
    // Open the test xml file
    NSURL *originalURL = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"__TEST001" ofType:@"xml"]];
    [viewController setUrlToLoad:originalURL];
    // Save the switch panel to a file in the user file system
    [viewController savePanelToPath:newFileURL];
    // Confirm that the saved file's XML is identical to the original file's
    NSError *fileError=nil;
    NSString *xmlString1 = [NSString stringWithContentsOfURL:originalURL encoding:NSUTF8StringEncoding error:&fileError];
    NSString *xmlString2 = [NSString stringWithContentsOfURL:newFileURL encoding:NSUTF8StringEncoding error:&fileError];
    // Compare normalized xml strings; don't be picky about formatting
    NSError *xmlError;
    DDXMLDocument *xmlDoc1 = [[DDXMLDocument alloc] initWithXMLString:xmlString1 options:0 error:&xmlError];
    DDXMLDocument *xmlDoc2 = [[DDXMLDocument alloc] initWithXMLString:xmlString2 options:0 error:&xmlError];
    NSString *compareString1 = [xmlDoc1 XMLString];
    NSString *compareString2 = [xmlDoc2 XMLString];
    STAssertTrue([compareString1 isEqualToString:compareString2], @"Saved xml %@ differs from loaded xml %@", compareString2, compareString1);
    // Remove the extra file
    [[[NSFileManager alloc] init] removeItemAtURL:newFileURL error:&fileError];
}

- (void)test_002_SwitchPanelViewController_005_ConfigureLifeCycle {
    // Work with "yellow" panel
    // Make sure it's displayed
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigControllerPreference"];
    SwitchControlAppDelegate *app_delegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication] delegate];
    UINavigationController *nav_controller = [app_delegate navigationController];
    rootSwitchViewController *rootViewController = [[nav_controller viewControllers] objectAtIndex:0];
    [rootViewController ResetScrollPanel];
    
    // Create a panel from a test XML file and enable configuration mode
    switchPanelViewController *viewController = [switchPanelViewController alloc];
    // Open the test xml file
    NSURL *originalURL = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"ctrl_1_yellow" ofType:@"xml"]];
    [viewController setUrlToLoad:originalURL];
    // Disable display of config button in settings
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"allowEditingOfSwitchPanelsPreference"];
    // Verify that button doesn't appear
    id configButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Edit Panel"];
    STAssertNil(configButton, @"Edit button shown when preferences say not to.");
    // Enable display of config button
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"allowEditingOfSwitchPanelsPreference"];
    // Determine the next panel's default name
    NSMutableString *nextPanelName = [[NSMutableString alloc] initWithCapacity:15];
    int i=0;
    NSURL *newFileURL;
    do {
        ++i;
        [nextPanelName setString:[NSString stringWithFormat:@"Panel %d", i]];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        newFileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xml", nextPanelName]]];
    } while ([[NSFileManager defaultManager] fileExistsAtPath:[newFileURL path]]);
    // Press Yellow button on root controller
    id yellowButton = [HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"];
    //NSLog(@"Yellowbutton = %@", yellowButton);
    [yellowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Verify that button does appear
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    configButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Edit Panel"];
    STAssertNotNil(configButton, @"Edit button not shown when enabled in settings.");
    // Verify that delete button does not appear
    id deleteButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Delete Panel"];
    STAssertNil(deleteButton, @"Delete button shown for built-in panel.");
    // Select configure button
    [configButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Verify that new view controller has no edit button, but does have a delete button
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    configButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Edit Panel"];
    STAssertNil(configButton, @"Edit button shown on newly created panel during editing.");
    deleteButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Delete Panel"];
    STAssertNil(deleteButton, @"Delete button shown on newly created during editing.");
    // Go back, which should return to new panel with both edit and delete
    id backButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Back"];
    [backButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    configButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Edit Panel"];
    STAssertNotNil(configButton, @"Edit button not shown on newly created panel after backing away from editing it.");
    deleteButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Delete Panel"];
    STAssertNotNil(deleteButton, @"Delete button not shown on newly created panel after backing away from editing it.");
    // Return to the root view controller
    backButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Back"];
    [backButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    
    // Check that new panel exists with default name
    id newPanelButton = [HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:nextPanelName];
    STAssertNotNil(newPanelButton, @"New panel button not displayed. Expected name %@", nextPanelName);
    // Choose new panel and configure
    [newPanelButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    configButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Edit Panel"];
    [configButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Change name of panel
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    STAssertTrue([[viewController->panelNameTextField text] isEqualToString:nextPanelName], @"Panel name not diplayed on config screen");
    [viewController->panelNameTextField setText:@"hoopy"];
    [viewController->panelNameTextField sendActionsForControlEvents:UIControlEventEditingDidEndOnExit];
    // Go back to root view controller
    [viewController goBack:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController goBack:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Check that previous name file disappeared, new one appeared
    STAssertNil([HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:nextPanelName], @"Panel did not disappear after name change");
    newPanelButton = [HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"hoopy"];
    STAssertNotNil(newPanelButton, @"Panel's new name did not appear after name change");
    
    // Open the panel again
    [newPanelButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    
    // Make sure confirm dialog button isn't visible
    STAssertTrue([viewController->confirmDeleteButton isHidden], @"Confirm delete button visible before being activated");
    
    // Press delete
    deleteButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Delete Panel"];
    [deleteButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    // Make sure that the confirm button is now visible
    STAssertFalse([viewController->confirmDeleteButton isHidden], @"Confirm delete button not visible after being activated");
    
    // Press the switch
    id switchButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"1"];
    [switchButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    // Make sure the confirm delete button disappeared
    STAssertTrue([viewController->confirmDeleteButton isHidden], @"Confirm delete button didn't disappear when switch touched");
    
    // Press delete, agree to delete
    [deleteButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [viewController->confirmDeleteButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Verify we're back at the root view controller
    STAssertTrue([nav_controller visibleViewController] == rootViewController, @"Deleting didn't go back to root view controller");
    // Verify that panel is gone
    newPanelButton = [HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"hoopy"];
    STAssertNil(newPanelButton, @"Panel still appears after being deleted.");
}


- (void)test_002_SwitchPanelViewController_006_EditingSwitchTextAndColor {
    SwitchControlAppDelegate *app_delegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication] delegate];
    UINavigationController *nav_controller = [app_delegate navigationController];
    rootSwitchViewController *rootViewController = [[nav_controller viewControllers] objectAtIndex:0];

    // Bring up the yellow panel to edit
    id yellowButton = [HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    switchPanelViewController *viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController editPanel:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Tap the button
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    id switch1 = [HandyTestStuff findSubviewOf:[viewController view] withText:@"1"];
    [switch1 sendActionsForControlEvents:UIControlEventTouchDown];
    // Change the switch name text
    [viewController->switchNameTextField setText:@"frood"];
    [viewController->switchNameTextField sendActionsForControlEvents:UIControlEventEditingDidEndOnExit];
    // Confirm that the text changed
    STAssertTrue([[switch1 titleForState:UIControlStateNormal] isEqualToString:@"frood"], @"Failed to set switch name");
    // Change the color to green
    id colorButton = [HandyTestStuff findEditColorButtonInView:[viewController view] withColor:[UIColor greenColor]];
    [colorButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    // Verify the the switch is green
    STAssertTrue([[switch1 backgroundColor] isEqual:[UIColor greenColor]], @"Failed to set color to green");
    // Change the color to blue
    colorButton = [HandyTestStuff findEditColorButtonInView:[viewController view] withColor:[UIColor blueColor]];
    [colorButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertTrue([[switch1 backgroundColor] isEqual:[UIColor blueColor]], @"Failed to set color to blue");
    // Delete the panel
    [viewController goBack:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController deletePanel:viewController->confirmDeleteButton];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
}

- (void)test_002_SwitchPanelViewController_007_CreateAndDeleteSwitch {
    SwitchControlAppDelegate *app_delegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication] delegate];
    UINavigationController *nav_controller = [app_delegate navigationController];
    rootSwitchViewController *rootViewController = [[nav_controller viewControllers] objectAtIndex:0];
    // Bring up the yellow panel to edit
    id yellowButton = [HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    switchPanelViewController *viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController editPanel:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    
    // Create a new switch
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [[HandyTestStuff findSubviewOf:[viewController view] withText:@"New Switch"] sendActionsForControlEvents:UIControlEventTouchUpInside];
    id newSwitch = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Switch"];
    STAssertNotNil(newSwitch, @"Failed to create new switch");
    
    // Tap new button
    [newSwitch sendActionsForControlEvents:UIControlEventTouchDown];
    
    // Confirm delete button not visible
    STAssertTrue([viewController->confirmDeleteButton isHidden], @"Confirm Delete Button visible before hitting delete");
    
    // Hit the delete button
    [[HandyTestStuff findSubviewOf:[viewController view] withText:@"Delete Switch"] sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertFalse([viewController->confirmDeleteButton isHidden], @"Confirm Delete Button not visible after hitting delete");
    
    // Make sure button disappears if we hit a different one
    [newSwitch sendActionsForControlEvents:UIControlEventTouchDown];
    STAssertTrue([viewController->confirmDeleteButton isHidden], @"Confirm Delete Button didn't disappear on hitting switch");
    
    // Now hit both delete and confirm
    [[HandyTestStuff findSubviewOf:[viewController view] withText:@"Delete Switch"] sendActionsForControlEvents:UIControlEventTouchUpInside];
    [viewController->confirmDeleteButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    newSwitch = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Switch"];
    STAssertNil(newSwitch, @"Failed to delete new switch");
    // Delete the panel
    [viewController goBack:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController deletePanel:viewController->confirmDeleteButton];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
}

- (void)test_002_SwitchPanelViewController_008_DefineActions {
    SwitchControlAppDelegate *app_delegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication] delegate];
    UINavigationController *nav_controller = [app_delegate navigationController];
    rootSwitchViewController *rootViewController = [[nav_controller viewControllers] objectAtIndex:0];
    // Bring up the yellow panel to edit
    id yellowButton = [HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    switchPanelViewController *viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController editPanel:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    // Tap the button
    yellowButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"1"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchDown];
    // Tap the actionForTouch button
    id touchActionButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Action For Touch"];
    [touchActionButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Verify that the defineAction panel launched
    STAssertTrue([viewController->actionPopover isPopoverVisible], @"Popover did not display for 'Action For Touch'");
    // Confirm that the panel is configured to change the action sequence for the button
    defineActionViewController *defineActionVC = (defineActionViewController *) [viewController->actionPopover contentViewController];
    STAssertTrue([defineActionVC actions] == [yellowButton activateActions], @"Actions for touch not set properly");
    // Dismiss the popover
    [viewController->actionPopover dismissPopoverAnimated:NO];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    // Tap the actionForRelease button
    id releaseActionButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Action For Release"];
    [releaseActionButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Verify that the defineAction panel launched
    STAssertTrue([viewController->actionPopover isPopoverVisible], @"Popover did not display for 'Action For Release'");
    // Confirm that the panel is configured to change the action sequence for the button
    defineActionVC = (defineActionViewController *) [viewController->actionPopover contentViewController];
    STAssertTrue([defineActionVC actions] == [yellowButton deactivateActions], @"Actions for release not set properly");
    // Clean up
    [viewController->actionPopover dismissPopoverAnimated:NO];
    [viewController goBack:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController deletePanel:viewController->confirmDeleteButton];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
}

- (void)test_002_SwitchPanelViewController_009_ImagesOnSwitch {
    SwitchControlAppDelegate *app_delegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication] delegate];
    UINavigationController *nav_controller = [app_delegate navigationController];
    rootSwitchViewController *rootViewController = [[nav_controller viewControllers] objectAtIndex:0];
    // Bring up the yellow panel to edit
    SJUIButtonWithActions *yellowButton = [HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    switchPanelViewController *viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController editPanel:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    // Tap the button
    yellowButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"1"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchDown];
    
    // Determine the next panel's default name
    NSMutableString *nextImageName = [[NSMutableString alloc] initWithCapacity:15];
    int i=0;
    NSURL *newFileURL;
    do {
        ++i;
        [nextImageName setString:[NSString stringWithFormat:@"Image %d", i]];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        newFileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.jpg", nextImageName]]];
    } while ([[NSFileManager defaultManager] fileExistsAtPath:[newFileURL path]]);
    
    UIButton *chooseImageButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Choose Image"];
    STAssertNotNil(chooseImageButton, @"No Choose Image Button");
    
    // Tap the button and then dismiss the dialog. All we can really to is verify that we don't crash
    [chooseImageButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    [viewController->imagePopover dismissPopoverAnimated:YES];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    
    // Create an image and prepare to send it to the image picker delegate method
    UIImage *testImage = [UIImage imageNamed:@"iphone_delete_button.png"];
    NSDictionary *testImageDictionary = [NSDictionary dictionaryWithObject:testImage forKey:UIImagePickerControllerEditedImage];
    [viewController imagePickerController:nil didFinishPickingMediaWithInfo:testImageDictionary];
    
    // Confirm that the URL now exists
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[newFileURL path]], @"New image path %@ does not exist after adding image to button", [newFileURL path]);
    // Confirm that the URL is in the button
    STAssertTrue([[yellowButton imageFilePath] isEqualToString:[newFileURL path]], @"New image path %@ does not match button URL %@", [yellowButton imageFilePath], newFileURL);
    // Confirm that the button says "Remove Image"
    NSString *currentTitle = [chooseImageButton titleForState:UIControlStateNormal];
    STAssertTrue([currentTitle isEqualToString:@"Remove Image"], @"Choose image button didn't switch to remove image when image added. Title is '%@'", currentTitle);
    
    // Delete the image
    [chooseImageButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    // Confirm that the image is gone
    STAssertNil([yellowButton backgroundImageForState:UIControlStateNormal], @"Removing image didn't eliminate image from button");
    // Confirm that image was deleted
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[newFileURL path]], @"Image still in file system after being removed", [newFileURL path]);
    // Confirm that the button again says "Choose Image"
    STAssertTrue([[chooseImageButton titleForState:UIControlStateNormal] isEqualToString:@"Choose Image"], @"Choose image button didn't switch to choose image when image removed");
    [viewController imagePickerController:nil didFinishPickingMediaWithInfo:testImageDictionary];
    STAssertNotNil([yellowButton backgroundImageForState:UIControlStateNormal], @"Image still nil after adding it again");
    
    
    // Delete the switch
    [yellowButton sendActionsForControlEvents:UIControlEventTouchDown];
    [viewController deleteSwitch:viewController->confirmDeleteButton];
    // Confirm that the URL disappeared
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[newFileURL path]], @"New image path %@ still exists after deleting button", [newFileURL path]);
    
    // Create a new switch
    [viewController newSwitch:nil];
    SJUIButtonWithActions *newButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Switch"];
    [newButton sendActionsForControlEvents:UIControlEventTouchDown];
    [viewController imagePickerController:nil didFinishPickingMediaWithInfo:testImageDictionary];
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[newFileURL path]], @"New image path %@ did not reappear after adding image to new button", [newFileURL path]);
    
    // Delete the panel
    [viewController goBack:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController deletePanel:viewController->confirmDeleteButton];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[newFileURL path]], @"New image path %@ did not get deleted when deleting panel", [newFileURL path]);
}

- (void)test_002_SwitchPanelViewController_009_AudioForSwitch {
    SwitchControlAppDelegate *app_delegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication] delegate];
    UINavigationController *nav_controller = [app_delegate navigationController];
    rootSwitchViewController *rootViewController = [[nav_controller viewControllers] objectAtIndex:0];
    // Bring up the yellow panel to edit
    SJUIButtonWithActions *yellowButton = [HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    switchPanelViewController *viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController editPanel:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    // Tap the button
    yellowButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"1"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchDown];
    
    // Determine the next panel's default name
    NSMutableString *nextImageName = [[NSMutableString alloc] initWithCapacity:15];
    int i=0;
    NSURL *newFileURL;
    do {
        ++i;
        [nextImageName setString:[NSString stringWithFormat:@"Audio %d", i]];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        newFileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.caf", nextImageName]]];
    } while ([[NSFileManager defaultManager] fileExistsAtPath:[newFileURL path]]);
    
    UIButton *recordSoundButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Record Sound"];
    STAssertNotNil(recordSoundButton, @"No Record Sound Button");
    // Tap the record button and create a dummy file
    [recordSoundButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    NSData *junkData = [NSData dataWithBytes:"abcdefg" length:7];
    [junkData writeToFile:[newFileURL path] atomically:YES];
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[newFileURL path]], @"Failed to create audio file %@", [newFileURL path]);
    [viewController SJUIRecordAudioViewControllerReadyForDismissal:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Confirm that the button's path is set up and the audio now says to delete
    STAssertTrue([[yellowButton audioFilePath] isEqualToString:[newFileURL path]], @"Audio path not configued properly");
    NSString *currentTitle = [recordSoundButton titleForState:UIControlStateNormal];
    STAssertTrue([currentTitle isEqualToString:@"Delete Sound"], @"Sound button didn't switch to delete after sound file created. Current title is %@", currentTitle);
    
    // Delete the image
    [recordSoundButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    // Confirm that the image is gone
    STAssertNil([yellowButton audioFilePath], @"Removing audio didn't eliminate path from button");
    // Confirm that image was deleted
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[newFileURL path]], @"Audio still in file system after being removed. file = %@", [newFileURL path]);
    // Confirm that the button again says "Choose Image"
    STAssertTrue([[recordSoundButton titleForState:UIControlStateNormal] isEqualToString:@"Record Sound"], @"Record sound button didn't switch to Record Sound when audio removed");
    
    // Add the audio again in order to delete it with the switch
    [recordSoundButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    [junkData writeToFile:[newFileURL path] atomically:YES];
    [viewController SJUIRecordAudioViewControllerReadyForDismissal:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchDown];
    [viewController deleteSwitch:viewController->confirmDeleteButton];
    // Confirm that the URL disappeared
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[newFileURL path]], @"New audio path %@ still exists after deleting button", [newFileURL path]);
    
    // Create a new switch
    [viewController newSwitch:nil];
    SJUIButtonWithActions *newButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Switch"];
    [newButton sendActionsForControlEvents:UIControlEventTouchDown];
    [recordSoundButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [junkData writeToFile:[newFileURL path] atomically:YES];
    [viewController SJUIRecordAudioViewControllerReadyForDismissal:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Delete the panel
    [viewController goBack:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController deletePanel:viewController->confirmDeleteButton];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[newFileURL path]], @"New audio path %@ did not get deleted when deleting panel", [newFileURL path]);
}
- (void)test_002_SwitchPanelViewController_010_IconForSwitch {
    SwitchControlAppDelegate *app_delegate = (SwitchControlAppDelegate *) [[UIApplication sharedApplication] delegate];
    UINavigationController *nav_controller = [app_delegate navigationController];
    rootSwitchViewController *rootViewController = [[nav_controller viewControllers] objectAtIndex:0];
    // Bring up the yellow panel to edit
    SJUIButtonWithActions *yellowButton = [HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    switchPanelViewController *viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController editPanel:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    // Tap the button
    yellowButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"1"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchDown];
    
    UIButton *chooseIconButton = [HandyTestStuff findSubviewOf:[viewController view] withText:@"Choose Icon"];
    STAssertNotNil(chooseIconButton, @"No Choose Icon Button");
    [chooseIconButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    
    chooseIconViewController *iconVC = (chooseIconViewController *) [viewController->iconPopover contentViewController];
    STAssertNotNil(iconVC, @"No icon view controller");
    
    // Check that the picker view has the right number of items, and that only the first one is nil
    int numIcons = [iconVC->iconPicker numberOfRowsInComponent:0];
    STAssertTrue(numIcons == 18, @"Iconpicker has %d elements.", numIcons);
    // With no picker selected, row 0 should be selected
    STAssertTrue([iconVC->iconPicker selectedRowInComponent:0] == 0, @"With no content, iconPicker should start at row 0");
    // The first element should be nil, but the rest should have elements
    STAssertNil([iconVC->iconPicker viewForRow:0 forComponent:0], @"First element of icon picker should be nil");
    for(int i=1; i < numIcons; ++i) {
        [iconVC->iconPicker selectRow:i inComponent:0 animated:NO];
        STAssertNotNil([iconVC->iconPicker viewForRow:i forComponent:0], @"Element %d of icon picker is nil", i);
    }
    // Spot check a couple of choices
    [iconVC->iconPicker selectRow:0 inComponent:0 animated:NO];
    [[iconVC->iconPicker delegate] pickerView:iconVC->iconPicker didSelectRow:0 inComponent:0];
    STAssertNil([iconVC iconName], @"Name not nil for icon 0. Instead is %@", [iconVC iconName]);
    [iconVC->iconPicker selectRow:5 inComponent:0 animated:NO];
    [[iconVC->iconPicker delegate] pickerView:iconVC->iconPicker didSelectRow:5 inComponent:0];
    STAssertTrue([[iconVC iconName] isEqualToString:@"VOL_DownArrow.png"], @"Name wrong for icon 5. Got %@", [iconVC iconName]);
    [viewController->iconPopover dismissPopoverAnimated:NO];
    [[viewController->iconPopover delegate] popoverControllerDidDismissPopover:viewController->iconPopover];
    
    // Re-start the panel and make sure the same icon is selected
    [chooseIconButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    
    iconVC = (chooseIconViewController *) [viewController->iconPopover contentViewController];
    STAssertNotNil(iconVC, @"No icon view controller second time around");
    int selectedRow = [iconVC->iconPicker selectedRowInComponent:0];
    STAssertTrue(selectedRow == 5, @"Did not preserve selected row after configuring it. Curent row = %d", selectedRow);
    // Delete the panel
    [viewController->iconPopover dismissPopoverAnimated:NO];
    [viewController goBack:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController deletePanel:viewController->confirmDeleteButton];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
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
    UITextField *scanningTextField = nil;
    UIView *subView;
    for (subView in [view subviews]) {
        if([subView isKindOfClass:[UITextField class]]) {
            scanningTextField = (UITextField *)subView;
            scanningTextField = (UITextField *) subView;
            STAssertTrue([scanningTextField isHidden], @"Scanning textField is not first hidden");
        }
    }
    STAssertNotNil(scanningTextField, @"Cannot find UITextField in root view controller for step scanning");
    button0Rect = ((UIButton *)[[view subviews] objectAtIndex:0]).frame;
    button1Rect = ((UIButton *)[[view subviews] objectAtIndex:1]).frame;
    button2Rect = ((UIButton *)[[view subviews] objectAtIndex:2]).frame;
    STAssertTrue(button0Rect.size.width == 924, @"Button0 width=%f wrong for step scanning with button 1 selected", button0Rect.size.width);
    STAssertTrue(button1Rect.size.width == 994, @"Button1 width=%f wrong for step scanning with button 1 selected", button1Rect.size.width);
    STAssertTrue(button2Rect.size.width == 944, @"Button2 width=%f wrong for step scanning with button 1 selected", button2Rect.size.width);
    // Advance the scanning
    [[scanningTextField delegate] textField:scanningTextField shouldChangeCharactersInRange:NSMakeRange(0,0) replacementString:@" "];
    button0Rect = ((UIButton *)[[view subviews] objectAtIndex:0]).frame;
    button1Rect = ((UIButton *)[[view subviews] objectAtIndex:1]).frame;
    button2Rect = ((UIButton *)[[view subviews] objectAtIndex:2]).frame;
    STAssertTrue(button0Rect.size.width == 924, @"Button0 width=%f wrong for step scanning with button 2 selected", button0Rect.size.width);
    STAssertTrue(button1Rect.size.width == 944, @"Button1 width=%f wrong for step scanning with button 2 selected", button1Rect.size.width);
    STAssertTrue(button2Rect.size.width == 994, @"Button2 width=%f wrong for step scanning with button 2 selected", button2Rect.size.width);
    // Advance it again with a different keystroke
    [[scanningTextField delegate] textField:scanningTextField shouldChangeCharactersInRange:NSMakeRange(0,0) replacementString:@"1"];
    button0Rect = ((UIButton *)[[view subviews] objectAtIndex:0]).frame;
    button1Rect = ((UIButton *)[[view subviews] objectAtIndex:1]).frame;
    button2Rect = ((UIButton *)[[view subviews] objectAtIndex:2]).frame;
    STAssertTrue(button0Rect.size.width == 924, @"Button0 width=%f wrong for step scanning with button 1 selected again", button0Rect.size.width);
    STAssertTrue(button1Rect.size.width == 994, @"Button1 width=%f wrong for step scanning with button 1 selected again", button1Rect.size.width);
    STAssertTrue(button2Rect.size.width == 944, @"Button2 width=%f wrong for step scanning with button 1 selected again", button2Rect.size.width);
    // Select this switch and make sure a command goes to the delegate
    MockSwitchControlDelegate *mockDelegate = [[MockSwitchControlDelegate alloc] init];
    mockDelegate->commandsReceived = [NSMutableArray arrayWithCapacity:5];
    viewController->appDelegate = mockDelegate;
    [[scanningTextField delegate] textField:scanningTextField shouldChangeCharactersInRange:NSMakeRange(0,0) replacementString:@"3"];
    STAssertTrue([mockDelegate->commandsReceived count]==1, @"No command received for step scan select");
}

- (void)test_002_SwitchPanelViewController_011_SetScanOrder {
    // Make sure button exists when appropriate
    switchPanelViewController *panelVC = [[switchPanelViewController alloc] init];
    [panelVC setUrlToLoad:[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"__TEST001" ofType:@"xml"]]];
    [panelVC setEditingActive:NO];
    UIView *view = [panelVC view];
    [panelVC viewWillAppear:NO];
    UIButton *setScanOrderButton = [HandyTestStuff findSubviewOf:view withText:@"Set Scan Order"];
    STAssertNil(setScanOrderButton, @"Set scan order button visible when editing not active.");
    panelVC = [[switchPanelViewController alloc] init];
    [panelVC setUrlToLoad:[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"__TEST001" ofType:@"xml"]]];
    [panelVC setEditingActive:YES];
    view = [panelVC view];
    [panelVC viewWillAppear:NO];
    setScanOrderButton = [HandyTestStuff findSubviewOf:view withText:@"Set Scan Order"];
    STAssertNotNil(setScanOrderButton, @"Set scan order button not visible when editing.");
    // Activate the button. The rest of the editing UI should disappear and the button title should change
    [setScanOrderButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertEqualObjects([setScanOrderButton titleForState:UIControlStateNormal], @"End of Scan", @"Scan order button title wrong when selected. Currenly %@", [setScanOrderButton titleForState:UIControlStateNormal]);
    UIView *uiViewElement;
    for(uiViewElement in panelVC->configurationUIElements) {
        if(uiViewElement == setScanOrderButton)
            STAssertFalse([uiViewElement isHidden], @"setScanOrderButton should not be hidden");
        else
            STAssertTrue([uiViewElement isHidden], @"UI should be hidden during scan order selection");
    }
    STAssertTrue([panelVC->backButton isHidden], @"Back button should be hidden during scan");
    // Touch a few panels
    [[[view subviews] objectAtIndex:1] sendActionsForControlEvents:UIControlEventTouchDown];
    [[[view subviews] objectAtIndex:0] sendActionsForControlEvents:UIControlEventTouchDown];
    [[[view subviews] objectAtIndex:2] sendActionsForControlEvents:UIControlEventTouchDown];
    [[[view subviews] objectAtIndex:1] sendActionsForControlEvents:UIControlEventTouchDown];
    // End Scanning. UI should reappear and the scan array should be set properly
    [setScanOrderButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertEqualObjects([setScanOrderButton titleForState:UIControlStateNormal], @"Set Scan Order", @"Scan order button title wrong after setting scan. Currenly %@", [setScanOrderButton titleForState:UIControlStateNormal]);
    for(uiViewElement in panelVC->configurationUIElements) {
        STAssertFalse([uiViewElement isHidden], @"UI not restored after setting scan order");
    }
    STAssertFalse([panelVC->backButton isHidden], @"Back button should be restored after scan");
    NSArray *expectedScanOrder = [NSArray arrayWithObjects:[NSNumber numberWithInt:1], [NSNumber numberWithInt:0], [NSNumber numberWithInt:2], [NSNumber numberWithInt:1], nil];
    STAssertTrue([expectedScanOrder isEqualToArray:panelVC->scanOrderIndices], @"Scan order indices wrong");
}

#endif // RUN_ALL_SWITCH_PANEL_VC_TESTS


@end
