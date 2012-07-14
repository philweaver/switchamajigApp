//
//  SwitchControlTests.m
//  SwitchControlTests
//
//  Created by Phil Weaver on 7/23/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//
#define RUN_ALL_TESTS 1
#import "SwitchControlTests.h"
#import "SJUIStatusMessageLabel.h"
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

@implementation MockNavigationController

- (void) pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    didReceivePushViewController = YES;
    lastViewController = viewController;
    [super pushViewController:viewController animated:animated];
}

- (UIViewController *) popViewControllerAnimated:(BOOL)animated {
    didReceivePopViewController = YES;
    return [super popViewControllerAnimated:animated];
}

@end

@implementation MockSwitchControlDelegate
- (void)performActionSequence:(DDXMLNode *)actionSequenceOnDevice {
    [commandsReceived addObject:actionSequenceOnDevice];
}

@end

@implementation MockSwitchamajigDriver
- (void)issueCommandFromXMLNode:(DDXMLNode *)command {
    //NSLog(@"Mock driver command issued. count = %d", [commandsReceived count]);
    //NSLog(@"Command = %@", [command XMLString]);
    [commandsReceived addObject:[command XMLString]];
    //NSLog(@"Mock driver count = %d on exit", [commandsReceived count]);
}

@end

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

+ (id) findSubviewOf:(UIView *)view withText:(NSString *)text {
    UIView *subView;
    for(subView in [view subviews]) {
        if([subView isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *) subView;
            if([[button titleForState:UIControlStateNormal] isEqualToString:text])
                return subView;
        }
    }
    return nil;
}

#if RUN_ALL_TESTS
- (void)test_000_AppDelegate_Exists
{
    STAssertNotNil(app_delegate, @"Can't find application delegate");
}

- (void)test_000_AppDelegate_000_Status_Messages
{
    SimulatedSwitchamajigController *simulatedController = [SimulatedSwitchamajigController alloc];
    [simulatedController startListening];
    SJUIStatusMessageLabel *statusLabel = [[SJUIStatusMessageLabel alloc] initWithFrame:CGRectMake(0,0,0,0)];
    // Make sure alert messages get through
    [app_delegate addStatusAlertMessage:@"Test" withColor:[UIColor purpleColor] displayForSeconds:2.0];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    NSString *currentMessage = [statusLabel text];
    UIColor *currentColor = [statusLabel textColor];
    STAssertTrue([currentMessage isEqualToString:@"Test"], @"Status alert is %@", currentMessage);
    STAssertTrue([currentColor isEqual:[UIColor purpleColor]], @"Status alert message color wrong");
    // Let time expire, look for no switchamajigs
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)2.5]];
    currentMessage = [statusLabel text];
    currentColor = [statusLabel textColor];
    STAssertTrue([currentMessage isEqualToString:@"No Switchamajigs Found"], @"Message when no SwitchamajigsFound is %@", currentMessage);
    STAssertTrue([currentColor isEqual:[UIColor redColor]], @"No Switchamajigs message color wrong");
    SwitchamajigControllerDeviceListener *listener = [SwitchamajigControllerDeviceListener alloc];
    [app_delegate SwitchamajigDeviceListenerFoundDevice:listener hostname:@"127.0.0.1" friendlyname:@"test_friendly"];
    // Make sure a driver was created
    id driverID = [[app_delegate friendlyNameSwitchamajigDictionary] objectForKey:@"test_friendly"];
    STAssertNotNil(driverID, @"Delegate did not create driver");
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    currentMessage = [statusLabel text];
    currentColor = [statusLabel textColor];
    STAssertTrue([currentMessage isEqualToString:@"Connected to test_friendly"], @"Not seeing found message");
    STAssertTrue([currentColor isEqual:[UIColor whiteColor]], @"Found message color wrong");
    [app_delegate SwitchamajigDeviceListenerHandleBatteryWarning:nil hostname:@"localhost" friendlyname:@"test_friendly"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    currentMessage = [statusLabel text];
    currentColor = [statusLabel textColor];
    STAssertTrue([currentMessage isEqualToString:@"test_friendly needs its batteries replaced"], @"Low battery warning not shown");
    STAssertTrue([currentColor isEqual:[UIColor redColor]], @"Low battery warning color wrong");
    // Wait for messages to go away, verify that we say we're connected
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)5.5]];
    currentMessage = [statusLabel text];
    currentColor = [statusLabel textColor];
    STAssertTrue([currentMessage isEqualToString:@"Connected to test_friendly"], @"Not seeing connected message. Actual message=%@", currentMessage);
    STAssertTrue([currentColor isEqual:[UIColor whiteColor]], @"Found message color wrong");
    // Add a second device
    [app_delegate SwitchamajigDeviceListenerFoundDevice:listener hostname:@"localhost" friendlyname:@"test_friendly2"];
    driverID = [[app_delegate friendlyNameSwitchamajigDictionary] objectForKey:@"test_friendly2"];
    STAssertNotNil(driverID, @"Delegate did not create driver2");
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)5.5]];
    currentMessage = [statusLabel text];
    currentColor = [statusLabel textColor];
    STAssertTrue([currentMessage isEqualToString:@"Connected to test_friendly2"], @"Not seeing second connected message. Actual message=%@", currentMessage);
    STAssertTrue([currentColor isEqual:[UIColor whiteColor]], @"Found message color wrong");
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)3.5]];
    currentMessage = [statusLabel text];
    currentColor = [statusLabel textColor];
    STAssertTrue([currentMessage isEqualToString:@"Connected to test_friendly"], @"Not seeing connected messages cycle properly. Actual message=%@", currentMessage);
    STAssertTrue([currentColor isEqual:[UIColor whiteColor]], @"Found message color wrong");
    // Verify lost contact message
    [app_delegate SwitchamajigDeviceDriverDisconnected:driverID withError:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)5.0]];
    currentMessage = [statusLabel text];
    currentColor = [statusLabel textColor];
    STAssertTrue([currentMessage isEqualToString:@"Disconnected from test_friendly2"], @"Disconnect message not seen. Actual message=%@", currentMessage);
    STAssertTrue([currentColor isEqual:[UIColor redColor]], @"Disconnect message color wrong");
    
    [simulatedController stopListening];
}
#endif

- (void)test_000_AppDelegate_001_Dispatch_Controller_Cmd {
    SwitchamajigControllerDeviceListener *listener = [SwitchamajigControllerDeviceListener alloc];
    [[app_delegate friendlyNameSwitchamajigDictionary] removeAllObjects];
    [app_delegate SwitchamajigDeviceListenerFoundDevice:listener hostname:@"localhost" friendlyname:@"frood"];
    // Verify that the new device is in the dictionary
    STAssertNotNil([[app_delegate friendlyNameSwitchamajigDictionary] objectForKey:@"frood"], @"Device not in dictionary after being detected");
    // Mock up a Sjig controller and to verify that commands come through
    MockSwitchamajigDriver *driver1 = [MockSwitchamajigDriver alloc];
    driver1->commandsReceived = [[NSMutableArray alloc] initWithCapacity:5];
    [[app_delegate friendlyNameSwitchamajigDictionary] setObject:driver1 forKey:@"frood"];
    // Verify that the command is passed to the controller
    NSError *error;
    DDXMLDocument *node1 = [[DDXMLDocument alloc] initWithXMLString:@"<actionsequenceondevice><friendlyname>frood</friendlyname><actionsequence><turnSwitchesOn>1</turnSwitchesOn></actionsequence></actionsequenceondevice>" options:0 error:&error];
    [app_delegate performActionSequence:node1];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    STAssertTrue([driver1->commandsReceived count] == 1, @"Driver did not receive simple command.");
    NSString *commandString = [driver1->commandsReceived objectAtIndex:0];
    STAssertTrue([commandString isEqualToString:@"<turnSwitchesOn>1</turnSwitchesOn>"], @"Did not receive simple command. Instead got %@", commandString);
    // Verify that the command is passed when sent to the default controller
    DDXMLDocument *node2 = [[DDXMLDocument alloc] initWithXMLString:@"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><turnSwitchesOn>1</turnSwitchesOn></actionsequence></actionsequenceondevice>" options:0 error:&error];
    [app_delegate performActionSequence:node2];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    STAssertTrue([driver1->commandsReceived count] == 2, @"Driver did not receive command sent to default.");
    commandString = [driver1->commandsReceived objectAtIndex:1];
    STAssertTrue([commandString isEqualToString:@"<turnSwitchesOn>1</turnSwitchesOn>"], @"Did not receive command sent to default. Instead got %@", commandString);
    // Mock up a second Sjig controller and register it with a different name
    [app_delegate SwitchamajigDeviceListenerFoundDevice:listener hostname:@"localhost" friendlyname:@"hoopy"];
    // Verify that the new device is in the dictionary
    STAssertNotNil([[app_delegate friendlyNameSwitchamajigDictionary] objectForKey:@"hoopy"], @"Second device not in dictionary after being detected");
    // Mock up a Sjig controller and to verify that commands come through
    MockSwitchamajigDriver *driver2 = [MockSwitchamajigDriver alloc];
    driver2->commandsReceived = [[NSMutableArray alloc] initWithCapacity:5];
    [[app_delegate friendlyNameSwitchamajigDictionary] setObject:driver2 forKey:@"hoopy"];
    // Verify that commands can go to both controllers
    DDXMLDocument *node3 = [[DDXMLDocument alloc] initWithXMLString:@"<actionsequenceondevice><friendlyname>hoopy</friendlyname><actionsequence><turnSwitchesOn>2</turnSwitchesOn></actionsequence></actionsequenceondevice>" options:0 error:&error];
    [app_delegate performActionSequence:node3];
    [app_delegate performActionSequence:node1];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    STAssertTrue([driver1->commandsReceived count] == 3, @"Driver did not receive command sent to first driver after second one registered.");
    commandString = [driver1->commandsReceived objectAtIndex:2];
    STAssertTrue([commandString isEqualToString:@"<turnSwitchesOn>1</turnSwitchesOn>"], @"Did not receive command sent to default. Instead got %@", commandString);
    STAssertTrue([driver2->commandsReceived count] == 1, @"Second driver did not receive command.");
    commandString = [driver2->commandsReceived objectAtIndex:0];
    STAssertTrue([commandString isEqualToString:@"<turnSwitchesOn>2</turnSwitchesOn>"], @"Did not receive command sent to default. Instead got %@", commandString);
    
    // Report a loss of contact to the delegate
    [app_delegate SwitchamajigDeviceDriverDisconnected:driver1 withError:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    // Verify that the controller is no longer in dictionary
    STAssertNil([[app_delegate friendlyNameSwitchamajigDictionary] objectForKey:@"frood"], @"Disconnected driver still in dictionary");
    STAssertNotNil([[app_delegate friendlyNameSwitchamajigDictionary] objectForKey:@"hoopy"], @"Second driver disappeared when first was remove.");
    // Verify that sending a command doesn't cause any disasters
    [app_delegate performActionSequence:node1];
   
}
#if RUN_ALL_TESTS
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
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    [nav_controller popViewControllerAnimated:NO];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];

    //[rootViewController viewWillAppear:YES];
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
    rootViewController = [[rootSwitchViewController alloc] initWithNibName:nil bundle:nil];
    [rootViewController view];
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
    rootViewController = [[rootSwitchViewController alloc] initWithNibName:nil bundle:nil];
    [rootViewController view];
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
                //NSLog(@"Intersecting rectangles: (%4.1f, %4.1f, %4.1f, %4.1f) and (%4.1f, %4.1f, %4.1f, %4.1f)", rect1.origin.x, rect1.origin.y, rect1.size.width, rect1.size.height, rect2.origin.x, rect2.origin.y, rect2.size.width, rect2.size.height);
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
            //NSLog(@"Out-of-bounds: (%4.1f, %4.1f, %4.1f, %4.1f) doesn't contain (%4.1f, %4.1f, %4.1f, %4.1f)", rect1.origin.x, rect1.origin.y, rect1.size.width, rect1.size.height, rect2.origin.x, rect2.origin.y, rect2.size.width, rect2.size.height);
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
    float buttonSizes[numButtonSizes] = {200, 100, 494};
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
                //NSLog(@"Test iteration start. textSize = %f, conditionsIndex = %d, buttonSize = %f", textSize, testConditionIndex, buttonSize);
                [[NSUserDefaults standardUserDefaults] setFloat:buttonSize forKey:@"switchPanelSizePreference"];
                // Update the view, and then run the tests
                rootViewController = [[rootSwitchViewController alloc] initWithNibName:nil bundle:nil];
                [rootViewController view];
                // Confirm text sizes
                STAssertTrue([SwitchControlTests CheckAllTextInView:[rootViewController view] hasSize:textSize], @"Text Size Check Failed. textSize = %f, conditionsIndex = %d, buttonSize = %f", textSize, testConditionIndex, buttonSize);
                // Make sure we don't have inappropriate overlaps
                int numOverlaps = [SwitchControlTests numberOfSubviewOverlapsInView:[rootViewController view]];
                STAssertTrue((numOverlaps == num_expected_overlaps), @"Overlapping views: found %d != expected %d textSize = %f, conditionsIndex = %d, buttonSize = %f", numOverlaps, num_expected_overlaps, textSize, testConditionIndex, buttonSize);
                // Stuff should (generally) be inside its parent view
                int numOutOfBounds = [SwitchControlTests numberOfSubviewsOutsideParents:[rootViewController view]];
                STAssertTrue((numOutOfBounds == num_expected_outofbounds), @"Out of bounds views: found %d != expected %d textSize = %f, conditionsIndex = %d, buttonSize = %f", numOutOfBounds, num_expected_outofbounds, textSize, testConditionIndex, buttonSize);
                //NSLog(@"Test iteration complete. textSize = %f, conditionsIndex = %d, buttonSize = %f", textSize, testConditionIndex, buttonSize);
            }
        }
    }
    //NSLog(@"Test 004 complete.");
}

// Confirm that we can launch a switch panel
- (void)test_001_RootViewController_005_LaunchSwitchPanel {
    rootViewController = [[rootSwitchViewController alloc] initWithNibName:nil bundle:nil];
    MockNavigationController *naviControl = [[MockNavigationController alloc] initWithRootViewController:rootViewController];
    naviControl->didReceivePushViewController = NO;
    [rootViewController view]; 
    // Select the first switch panel
    [[[[rootViewController panelSelectionScrollView] subviews] objectAtIndex:1] sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertTrue(naviControl->didReceivePushViewController, @"Selecting switch panel did not push view controller");
    STAssertTrue([naviControl->lastViewController isKindOfClass:[switchPanelViewController class]], @"Switch panel did not display");
}

- (void)test_002_SwitchPanelViewController_001_PanelLayout {
    // Make sure panel displays properly
    switchPanelViewController *viewController = [switchPanelViewController alloc];
    [viewController setUrlToLoad:[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"6_tworows" ofType:@"xml"]]];
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
    STAssertTrue(didFindFirstButton, @"First button in 6_tworows.xml does not exist.");
    STAssertTrue(didFindLastButton, @"Last button in 6_tworows.xml does not exist.");
}

- (void)test_002_SwitchPanelViewController_002_BackButton {
    // Confirm that the back button works properly
    // Set up settings to require two-button back
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"singleTapBackButtonPreference"];
    // Load panel that has both back and enable
    switchPanelViewController *viewController = [switchPanelViewController alloc];
    [viewController setUrlToLoad:[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"__TEST001" ofType:@"xml"]]];
    // Confirm that back button is disabled and enable button is displayed
    UIView *currentView = [viewController view];
    id backButton = [SwitchControlTests findSubviewOf:currentView withText:@"Back"];
    id enableBackButton = [SwitchControlTests findSubviewOf:currentView withText:@"Enable Back Button"];
    STAssertNotNil(backButton, enableBackButton, @"Either the Back or the Back Enable Button doesn't exist");
    STAssertFalse([backButton isEnabled], @"Back button enabled before enable button pressed");
    // Enable the back button
    [enableBackButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    // Confirm that back button is enabled
    STAssertTrue([backButton isEnabled], @"Back button not enabled after enable button pressed");
    // Touch a different control
    [[SwitchControlTests findSubviewOf:currentView withText:@"1"] sendActionsForControlEvents:UIControlEventTouchUpInside];
    // Confirm that back button is disabled again
    STAssertFalse([backButton isEnabled], @"Back button still enabled after pressing another control");
    // Change setting for one-button back
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"singleTapBackButtonPreference"];
    // Re-create panel 
    viewController = [switchPanelViewController alloc];
    [viewController setUrlToLoad:[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"__TEST001" ofType:@"xml"]]];
    currentView = [viewController view];
    // Confirm that the back button is enabled and enable button is not displayed
    backButton = [SwitchControlTests findSubviewOf:currentView withText:@"Back"];
    enableBackButton = [SwitchControlTests findSubviewOf:currentView withText:@"Enable Back Button"];
    STAssertNotNil(backButton, @"Back button doesn't exist with single-button navigation");
    STAssertNil(enableBackButton, @"Enable Back button exists with single-button navigation");
    STAssertTrue([backButton isEnabled], @"Back button not enabled with single-button navigation");
    // Confirm that the back button works
    rootViewController = [[rootSwitchViewController alloc] initWithNibName:nil bundle:nil];
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
    id button = [SwitchControlTests findSubviewOf:theView withText:@"1"];
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
    button = [SwitchControlTests findSubviewOf:theView withText:@"2"];
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
#endif

#if 0
// Implement this once configuration working
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
