//
//  SwitchControlTests.m
//  SwitchControlTests
//
//  Created by Phil Weaver on 7/23/11.
//  Copyright 2012 PAW Solutions. All rights reserved.
//
#define RUN_ALL_TESTS 1
#import "SwitchControlTests.h"
#import "SJUIStatusMessageLabel.h"
#import "defineActionViewController.h"
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
- (void)issueCommandFromXMLNode:(DDXMLNode *)command error:(NSError **)err {
    //NSLog(@"Mock driver command issued. count = %d", [commandsReceived count]);
    //NSLog(@"Command = %@", [command XMLString]);
    [commandsReceived addObject:[command XMLString]];
    //NSLog(@"Mock driver count = %d on exit", [commandsReceived count]);
}

@end

@implementation SwitchControlTests

- (void) reloadRootViewController {
    // Update the view, and then run the tests
    UIView *viewToRemove;
    for(viewToRemove in [[rootViewController view] subviews])
        [viewToRemove removeFromSuperview];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];       
    [rootViewController loadView];
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
            NSString *title = [button titleForState:UIControlStateNormal];
            //NSLog(@"Findsubview: looking for %@. Current text is %@.\n", text, title);
            if([title isEqualToString:text])
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

- (void)test_000_AppDelegate_002_Multi_Step_Commands {
    SimulatedSwitchamajigController *simulatedController = [SimulatedSwitchamajigController alloc];
    [simulatedController startListening];
    SwitchamajigControllerDeviceListener *listener = [SwitchamajigControllerDeviceListener alloc];
    [[app_delegate friendlyNameSwitchamajigDictionary] removeAllObjects];
    [app_delegate SwitchamajigDeviceListenerFoundDevice:listener hostname:@"localhost" friendlyname:@"frood"];
    // Mock up a Sjig controller and to verify that commands come through
    MockSwitchamajigDriver *driver1 = [MockSwitchamajigDriver alloc];
    driver1->commandsReceived = [[NSMutableArray alloc] initWithCapacity:5];
    [[app_delegate friendlyNameSwitchamajigDictionary] setObject:driver1 forKey:@"frood"];
    // Send a multi-step command with a delay to the controller
    NSError *error;
    DDXMLDocument *node1 = [[DDXMLDocument alloc] initWithXMLString:@"<actionsequenceondevice><friendlyname>frood</friendlyname><actionsequence><turnSwitchesOn>1</turnSwitchesOn><delay>1</delay><turnSwitchesOff>1</turnSwitchesOff></actionsequence></actionsequenceondevice>" options:0 error:&error];
    [app_delegate performActionSequence:node1];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    int numCommandsReceived = [driver1->commandsReceived count];
    STAssertTrue(numCommandsReceived == 1, @"Should have one command after starting sequence. Instead have %d.", numCommandsReceived);
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    numCommandsReceived = [driver1->commandsReceived count];
    STAssertTrue(numCommandsReceived == 2, @"Should have one command after running sequence. Instead have %d.", numCommandsReceived);
    // Verify that the commands were as expected
    NSString *commandString = [driver1->commandsReceived objectAtIndex:0];
    STAssertTrue([commandString isEqualToString:@"<turnSwitchesOn>1</turnSwitchesOn>"], @"First command was incorrect. Recieved %@.", commandString);
    commandString = [driver1->commandsReceived objectAtIndex:1];
    STAssertTrue([commandString isEqualToString:@"<turnSwitchesOff>1</turnSwitchesOff>"], @"Second command was incorrect. Recieved %@.", commandString);

    // Send a loop command 
    [driver1->commandsReceived removeAllObjects];
    DDXMLDocument *node2 = [[DDXMLDocument alloc] initWithXMLString:@"<actionsequenceondevice><friendlyname>frood</friendlyname><actionname>test</actionname><actionsequence><loop><turnSwitchesOn>1</turnSwitchesOn><delay>1</delay><turnSwitchesOff>1</turnSwitchesOff><delay>1</delay></loop></actionsequence></actionsequenceondevice>" options:0 error:&error];
    [app_delegate performActionSequence:node2];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    // Watch timing of command for two loops
    numCommandsReceived = [driver1->commandsReceived count];
    STAssertTrue(numCommandsReceived == 1, @"Should have one command after starting loop. Instead have %d.", numCommandsReceived);
    for(int i=2; i <5; ++i) { 
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
        numCommandsReceived = [driver1->commandsReceived count];
        STAssertTrue(numCommandsReceived == i, @"Should have %d commands in loop. Instead have %d.", i, numCommandsReceived);
    }
    // Stop the loop
    DDXMLDocument *node3 = [[DDXMLDocument alloc] initWithXMLString:@"<actionsequenceondevice><friendlyname>frood</friendlyname><actionsequence><stopactionwithname>test</stopactionwithname><turnSwitchesOff>1</turnSwitchesOff></actionsequence></actionsequenceondevice>" options:0 error:&error];
    [app_delegate performActionSequence:node3];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)2.0]];
    numCommandsReceived = [driver1->commandsReceived count];
    STAssertTrue(numCommandsReceived == 5, @"Should have five command after stopping loop. Instead have %d.", numCommandsReceived);
    
    // Verify that the commands were as expected
    commandString = [driver1->commandsReceived objectAtIndex:0];
    STAssertTrue([commandString isEqualToString:@"<turnSwitchesOn>1</turnSwitchesOn>"], @"First loop command was incorrect. Recieved %@.", commandString);
    commandString = [driver1->commandsReceived objectAtIndex:1];
    STAssertTrue([commandString isEqualToString:@"<turnSwitchesOff>1</turnSwitchesOff>"], @"Second loop command was incorrect. Recieved %@.", commandString);
    commandString = [driver1->commandsReceived objectAtIndex:2];
    STAssertTrue([commandString isEqualToString:@"<turnSwitchesOn>1</turnSwitchesOn>"], @"Third loop command was incorrect. Recieved %@.", commandString);
    commandString = [driver1->commandsReceived objectAtIndex:3];
    STAssertTrue([commandString isEqualToString:@"<turnSwitchesOff>1</turnSwitchesOff>"], @"Fourth loop command was incorrect. Recieved %@.", commandString);
    commandString = [driver1->commandsReceived objectAtIndex:4];
    STAssertTrue([commandString isEqualToString:@"<turnSwitchesOff>1</turnSwitchesOff>"], @"Fifth loop command was incorrect. Recieved %@.", commandString);
    [simulatedController stopListening];
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
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    [nav_controller popViewControllerAnimated:NO];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];

    //[rootViewController viewWillAppear:YES];
    STAssertTrue(nav_controller.navigationBarHidden, @"Navigation bar not hidden in root view after help.");
    /* Confirm that help button does not appear when scanning enabled
    Scanning disabled
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"enableScanningPreference"];
    [self reloadRootViewController];
    STAssertNil([rootViewController helpButton], @"Scan Button nil when scanning enabled"); */
    // Confirm that help button does not appear when preference say not to
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"enableScanningPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showHelpButtonPreference"];
    [self reloadRootViewController];
    STAssertNil([rootViewController helpButton], @"Scan Button nil when scanning enabled");

}

#if 0
// Scanning not supported
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
#endif
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
            if([title isEqualToString:@"Help"] || [title isEqualToString:@"Configure Network Settings"])
                continue;
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
            NSLog(@"Size does not match with title: %@. Should be %f, is %f", title, size, fontSize);
            return NO;
        }
        if(![SwitchControlTests CheckAllTextInView:subView hasSize:size])
            return NO;
    }
    // If nothing failed or the list is empty, we're good
    return YES;
}

- (void) gutsOfSizeTestWithTextSize:(float)textSize buttonSize:(float)buttonSize conditionIndex:(int)testConditionIndex {
    const int num_expected_overlaps = 2; // Highlighting overlaps one button and one text label
    const int num_expected_outofbounds = 1; // Highlighting goes outside the scroll view
    [[NSUserDefaults standardUserDefaults] setFloat:textSize forKey:@"textSizePreference"];
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
    @autoreleasepool {
        [[NSUserDefaults standardUserDefaults] setFloat:buttonSize forKey:@"switchPanelSizePreference"];
        // Update the view, and then run the tests
        UIView *viewToRemove;
        for(viewToRemove in [[rootViewController view] subviews])
            [viewToRemove removeFromSuperview];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigControllerPreference"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigIRPreference"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"allowEditingOfSwitchPanelsPreference"];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
        [rootViewController loadView];
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

- (void)test_001_RootViewController_004a_TextAndButtonSizesWithTextSize15 {
    const int numTestConditions = 2;
    const int numButtonSizes = 3;
    float buttonSizes[numButtonSizes] = {400, 100, 44};
    float textSize = 20;
    for(int testConditionIndex = 0; testConditionIndex < numTestConditions; ++testConditionIndex) {
        for(int buttonSizeIndex = 0; buttonSizeIndex < numButtonSizes; ++buttonSizeIndex) {
            float buttonSize = buttonSizes[buttonSizeIndex];
            [self gutsOfSizeTestWithTextSize:textSize buttonSize:buttonSize conditionIndex:testConditionIndex];
        }
    }
    NSLog(@"Test 004a complete.");
}

- (void)test_001_RootViewController_004b_TextAndButtonSizesWithTextSize50 {
    const int numTestConditions = 2; // Was 3 for scanning
    const int numButtonSizes = 3;
    float buttonSizes[numButtonSizes] = {400, 100, 44};
    float textSize = 50;
    for(int testConditionIndex = 0; testConditionIndex < numTestConditions; ++testConditionIndex) {
        for(int buttonSizeIndex = 0; buttonSizeIndex < numButtonSizes; ++buttonSizeIndex) {
            float buttonSize = buttonSizes[buttonSizeIndex];
            [self gutsOfSizeTestWithTextSize:textSize buttonSize:buttonSize conditionIndex:testConditionIndex];
        }
    }
    NSLog(@"Test 004b complete.");
}

- (void)test_001_RootViewController_004c_TextAndButtonSizesWithTextSize100 {
    const int numTestConditions = 2;
    const int numButtonSizes = 3;
    float buttonSizes[numButtonSizes] = {400, 100, 44};
    float textSize = 75;
    for(int testConditionIndex = 0; testConditionIndex < numTestConditions; ++testConditionIndex) {
        for(int buttonSizeIndex = 0; buttonSizeIndex < numButtonSizes; ++buttonSizeIndex) {
            float buttonSize = buttonSizes[buttonSizeIndex];
            [self gutsOfSizeTestWithTextSize:textSize buttonSize:buttonSize conditionIndex:testConditionIndex];
        }
    }
    NSLog(@"Test 004c complete.");
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

// Check settings for various support
- (void)test_001_RootViewController_006_LaunchSwitchPanel {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"supportSwitchamajigControllerPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"supportSwitchamajigIRPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"allowEditingOfSwitchPanelsPreference"];
    [rootViewController ResetScrollPanel];
    // Shouldn't see much
    STAssertNil([SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"], @"Yellow panel shown with controller support disabled.");
    STAssertNil([SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"IR Basic"], @"IR Basic panel shown with IR support disabled.");
    STAssertNil([SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Blank"], @"Blank panel shown with editing support disabled.");
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigControllerPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigIRPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"allowEditingOfSwitchPanelsPreference"];
    [rootViewController ResetScrollPanel];
    // Should see them now much
    STAssertNotNil([SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"], @"Yellow panel not shown with controller support enabled.");
    STAssertNotNil([SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"IR Basic"], @"IR Basic panel not shown with IR support enabled.");
    STAssertNotNil([SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Blank"], @"Blank panel not shown with editing support enabled.");

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
    // Turn off panel editing, as during editing we suspend the two-button back
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"allowEditingOfSwitchPanelsPreference"];
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
    [rootViewController ResetScrollPanel];

    // Create a panel from a test XML file and enable configuration mode
    switchPanelViewController *viewController = [switchPanelViewController alloc];
    // Open the test xml file
    NSURL *originalURL = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"1_yellow" ofType:@"xml"]];
    [viewController setUrlToLoad:originalURL];
    // Disable display of config button in settings
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"allowEditingOfSwitchPanelsPreference"];
    // Verify that button doesn't appear
    id configButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Edit Panel"];
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
    id yellowButton = [SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"];
    //NSLog(@"Yellowbutton = %@", yellowButton);
    [yellowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Verify that button does appear
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    configButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Edit Panel"];
    STAssertNotNil(configButton, @"Edit button not shown when enabled in settings.");
    // Verify that delete button does not appear
    id deleteButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Delete Panel"];
    STAssertNil(deleteButton, @"Delete button shown for built-in panel.");
    // Select configure button
    [configButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Verify that new view controller has no edit button, but does have a delete button
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    configButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Edit Panel"];
    STAssertNil(configButton, @"Edit button shown on newly created panel during editing.");
    deleteButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Delete Panel"];
    STAssertNil(deleteButton, @"Delete button shown on newly created during editing.");
    // Go back, which should return to new panel with both edit and delete
    id backButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Back"];
    [backButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    configButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Edit Panel"];
    STAssertNotNil(configButton, @"Edit button not shown on newly created panel after backing away from editing it.");
    deleteButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Delete Panel"];
    STAssertNotNil(deleteButton, @"Delete button not shown on newly created panel after backing away from editing it.");
    // Return to the root view controller
    backButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Back"];
    [backButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];

    // Check that new panel exists with default name
    id newPanelButton = [SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:nextPanelName];
    STAssertNotNil(newPanelButton, @"New panel button not displayed. Expected name %@", nextPanelName);
    // Choose new panel and configure
    [newPanelButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    configButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Edit Panel"];
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
    STAssertNil([SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:nextPanelName], @"Panel did not disappear after name change");
    newPanelButton = [SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"hoopy"];
    STAssertNotNil(newPanelButton, @"Panel's new name did not appear after name change");
    
    // Open the panel again
    [newPanelButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    
    // Make sure confirm dialog button isn't visible
    STAssertTrue([viewController->confirmDeleteButton isHidden], @"Confirm delete button visible before being activated");
    
    // Press delete
    deleteButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Delete Panel"];
    [deleteButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    // Make sure that the confirm button is now visible
    STAssertFalse([viewController->confirmDeleteButton isHidden], @"Confirm delete button not visible after being activated");
    
    // Press the switch
    id switchButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"1"];
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
    newPanelButton = [SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"hoopy"];
    STAssertNil(newPanelButton, @"Panel still appears after being deleted.");
}


+ (id) findEditColorButtonInView:(UIView *)superview withColor:(UIColor *)color {
    UIView *view;
    for(view in [superview subviews]) {
        if(![view isKindOfClass:[UIButton class]])
            continue;
        CGRect frame = [view frame];
        if(frame.origin.x != 980)
            continue;
        UIButton *button = (UIButton *)view;
        if(([button buttonType] == UIButtonTypeCustom) && ([[button backgroundColor] isEqual:color]))
            return button;
    }
    return nil;
}

- (void)test_002_SwitchPanelViewController_006_EditingSwitchTextAndColor {
    // Bring up the yellow panel to edit
    id yellowButton = [SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    switchPanelViewController *viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController editPanel:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Tap the button
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    id switch1 = [SwitchControlTests findSubviewOf:[viewController view] withText:@"1"];
    [switch1 sendActionsForControlEvents:UIControlEventTouchDown];
    // Change the switch name text
    [viewController->switchNameTextField setText:@"frood"];
    [viewController->switchNameTextField sendActionsForControlEvents:UIControlEventEditingDidEndOnExit];
    // Confirm that the text changed
    STAssertTrue([[switch1 titleForState:UIControlStateNormal] isEqualToString:@"frood"], @"Failed to set switch name");
    // Change the color to green
    id colorButton = [SwitchControlTests findEditColorButtonInView:[viewController view] withColor:[UIColor greenColor]];
    [colorButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    // Verify the the switch is green
    STAssertTrue([[switch1 backgroundColor] isEqual:[UIColor greenColor]], @"Failed to set color to green");
    // Change the color to blue
    colorButton = [SwitchControlTests findEditColorButtonInView:[viewController view] withColor:[UIColor blueColor]];
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
    // Bring up the yellow panel to edit
    id yellowButton = [SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    switchPanelViewController *viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController editPanel:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];

    // Create a new switch
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [[SwitchControlTests findSubviewOf:[viewController view] withText:@"New Switch"] sendActionsForControlEvents:UIControlEventTouchUpInside];
    id newSwitch = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Switch"];
    STAssertNotNil(newSwitch, @"Failed to create new switch");
    
    // Tap new button
    [newSwitch sendActionsForControlEvents:UIControlEventTouchDown];
    
    // Confirm delete button not visible
    STAssertTrue([viewController->confirmDeleteButton isHidden], @"Confirm Delete Button visible before hitting delete");
    
    // Hit the delete button
    [[SwitchControlTests findSubviewOf:[viewController view] withText:@"Delete Switch"] sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertFalse([viewController->confirmDeleteButton isHidden], @"Confirm Delete Button not visible after hitting delete");
    
    // Make sure button disappears if we hit a different one
    [newSwitch sendActionsForControlEvents:UIControlEventTouchDown];
    STAssertTrue([viewController->confirmDeleteButton isHidden], @"Confirm Delete Button didn't disappear on hitting switch");
    
    // Now hit both delete and confirm
    [[SwitchControlTests findSubviewOf:[viewController view] withText:@"Delete Switch"] sendActionsForControlEvents:UIControlEventTouchUpInside];
    [viewController->confirmDeleteButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    
    newSwitch = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Switch"];
    STAssertNil(newSwitch, @"Failed to delete new switch");
    // Delete the panel
    [viewController goBack:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController deletePanel:viewController->confirmDeleteButton];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
}

- (void)test_002_SwitchPanelViewController_008_DefineActions {
    // Bring up the yellow panel to edit
    id yellowButton = [SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    switchPanelViewController *viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController editPanel:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];    
    // Tap the button
    yellowButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"1"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchDown];
    // Tap the actionForTouch button
    id touchActionButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Action For Touch"];
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
    id releaseActionButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Action For Release"];
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
    // Bring up the yellow panel to edit
    SJUIButtonWithActions *yellowButton = [SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    switchPanelViewController *viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController editPanel:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];    
    // Tap the button
    yellowButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"1"];
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
    
    UIButton *chooseImageButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Choose Image"];
    STAssertNotNil(chooseImageButton, @"No Choose Image Button");
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
    SJUIButtonWithActions *newButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Switch"];    
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
    // Bring up the yellow panel to edit
    SJUIButtonWithActions *yellowButton = [SwitchControlTests findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"];
    [yellowButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    switchPanelViewController *viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    [viewController editPanel:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    viewController = (switchPanelViewController *) [nav_controller visibleViewController];
    // Tap the button
    yellowButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"1"];
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
    
    UIButton *recordSoundButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Record Sound"];
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
    SJUIButtonWithActions *newButton = [SwitchControlTests findSubviewOf:[viewController view] withText:@"Switch"];
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
#endif

- (void)test_003_defineActionViewController_001_Initialization {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"supportSwitchamajigControllerPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"supportSwitchamajigIRPreference"];
    // Create and initialize with no friendly names or actions
    NSMutableArray *actions = [[NSMutableArray alloc] initWithCapacity:5];
    SwitchControlAppDelegate *dummy_app_delegate = [SwitchControlAppDelegate alloc];
    [dummy_app_delegate setFriendlyNameSwitchamajigDictionary:[[NSMutableDictionary alloc] initWithCapacity:5]];
    defineActionViewController *defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    // Confirm that currently have only "Default", and "No Action"
    STAssertTrue([defineVC->actionPicker numberOfRowsInComponent:0] == 1, @"With no friendly names, defineActionPicker should show only one value: 'Default'");
    STAssertTrue([defineVC->actionPicker numberOfRowsInComponent:1] == 1, @"With no drivers supported, defineActionPicker should show only one action: 'No Action'");
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigControllerPreference"];
    defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    STAssertTrue([defineVC->actionPicker numberOfRowsInComponent:1] == 3, @"With only controller supported, defineActionPicker should show three actions.");
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigIRPreference"];
    defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    STAssertTrue([defineVC->actionPicker numberOfRowsInComponent:1] == 5, @"With both controller and IR supported, defineActionPicker should show five actions.");
   
    STAssertTrue([defineVC->actionPicker selectedRowInComponent:0] == 0, @"Default value not selected when no friendly names");
    STAssertTrue([[defineVC pickerView:defineVC->actionPicker titleForRow:0 forComponent:0] isEqualToString:@"Default"], @"With no friendly names, defineActionPicker should show only one value: 'Default'");
    STAssertTrue([[defineVC pickerView:defineVC->actionPicker titleForRow:[defineVC->actionPicker selectedRowInComponent:1] forComponent:1] isEqualToString:@"No Action"], @"Must show 'No Action' when none defined in XML");
    SJActionUITurnSwitchesOn *turnSwitchesOnUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Turn Switches On"];
    SJActionUITurnSwitchesOff *turnSwitchesOffUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Turn Switches Off"];
    STAssertNotNil(turnSwitchesOnUI, @"Must have a turn switches on UI");
    STAssertNotNil(turnSwitchesOffUI, @"Must have a turn switches off UI");
    for(int i=0; i < 6; ++i) {
        STAssertTrue([turnSwitchesOnUI->switchButtons[i] isHidden], @"Switch on buttons not hidden for no action");
        STAssertTrue([turnSwitchesOffUI->switchButtons[i] isHidden], @"Switch off buttons not hidden for no action");
    }

    // Add a couple of names to the friendly list, and create a "switch on" action
    [[dummy_app_delegate friendlyNameSwitchamajigDictionary] setObject:@"dummy1" forKey:@"hoopy"];
    [[dummy_app_delegate friendlyNameSwitchamajigDictionary] setObject:@"dummy2" forKey:@"frood"];
    NSString *xmlString = @"<actionsequenceondevice><friendlyname>Default</friendlyname> <actionsequence> <turnSwitchesOn>1 3</turnSwitchesOn> </actionsequence></actionsequenceondevice>";
    NSError *xmlError;
    DDXMLDocument *document = [[DDXMLDocument alloc] initWithXMLString:xmlString options:0 error:&xmlError];
    if(xmlError)
        NSLog(@"XML error creating document: %@", xmlError);
    //NSLog(@"xmlString: %@", xmlString);
    //NSLog(@"document XMLString: %@", [document XMLString]);
    DDXMLNode *docChild = [[document children] objectAtIndex:0];
    //NSLog(@"actions count before = %d", [actions count]);
    [actions removeAllObjects];
    [actions addObject:docChild];
    //NSLog(@"actions count after = %d", [actions count]);
    //[actions addObject:[[document children] objectAtIndex:0]];
    //NSLog(@"docchild: %@", [docChild XMLString]);
    //NSLog(@"action[0]: %@", [[actions objectAtIndex:0] XMLString]);
    //DDXMLNode *arrayValue = [actions objectAtIndex:0];
    //NSLog(@"Value from array = %@", [arrayValue XMLString]);
    defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    [defineVC loadView];
    STAssertTrue([defineVC->actionPicker numberOfRowsInComponent:0] == 3, @"With two friendly names, must have three values in picker including 'Default' Instead have %d", [defineVC->actionPicker numberOfRowsInComponent:0]);
    STAssertTrue([[defineVC pickerView:defineVC->actionPicker titleForRow:[defineVC->actionPicker selectedRowInComponent:0] forComponent:0] isEqualToString:@"Default"], @"Friendly name 'Default' not selected as specified in xml");
    STAssertTrue([[defineVC pickerView:defineVC->actionPicker titleForRow:[defineVC->actionPicker selectedRowInComponent:1] forComponent:1] isEqualToString:@"Turn Switches On"], @"'Turn Switches On' action not selected when in action sequence");
    int switchMask = 0;
    // Check mask and verify the buttons are visible
    turnSwitchesOnUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Turn Switches On"];
    turnSwitchesOffUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Turn Switches Off"];
    for(int i=0; i < 6; ++i) {
        STAssertFalse([turnSwitchesOnUI->switchButtons[i] isHidden], @"Switch on buttons hidden for switches on");
        STAssertTrue([turnSwitchesOffUI->switchButtons[i] isHidden], @"Switch off buttons not hidden for switches on");
        if([[turnSwitchesOnUI->switchButtons[i] backgroundColor] isEqual:[UIColor redColor]])
            switchMask |= (1 << i);
    }
    STAssertTrue(switchMask == 5, @"Switch mask wrong for turn switches on. Should be 5 instead is %d", switchMask);
    
    // Repeat for turn switches off
    xmlString = @"<actionsequenceondevice><friendlyname>frood</friendlyname> <actionsequence> <turnSwitchesOff>2 4 5 6</turnSwitchesOff> </actionsequence></actionsequenceondevice>";
    document = [[DDXMLDocument alloc] initWithXMLString:xmlString options:0 error:nil];
    [actions removeAllObjects];
    [actions addObject:[[document children] objectAtIndex:0]];
    defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    [defineVC loadView];
    STAssertTrue([defineVC->actionPicker numberOfRowsInComponent:0] == 3, @"With two friendly names, must have three values in picker including 'Default'");
    STAssertTrue([[defineVC pickerView:defineVC->actionPicker titleForRow:[defineVC->actionPicker selectedRowInComponent:0] forComponent:0] isEqualToString:@"frood"], @"Friendly name 'frood' not selected as specified in xml");
    STAssertTrue([[defineVC pickerView:defineVC->actionPicker titleForRow:[defineVC->actionPicker selectedRowInComponent:1] forComponent:1] isEqualToString:@"Turn Switches Off"], @"'Turn Switches Off' action not selected when in action sequence");
    switchMask = 0;
    turnSwitchesOnUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Turn Switches On"];
    turnSwitchesOffUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Turn Switches Off"];
    for(int i=0; i < 6; ++i) {
        STAssertFalse([turnSwitchesOffUI->switchButtons[i] isHidden], @"Switch off buttons hidden for switches off");
        STAssertTrue([turnSwitchesOnUI->switchButtons[i] isHidden], @"Switch on buttons not hidden for switches off");
        if([[turnSwitchesOffUI->switchButtons[i] backgroundColor] isEqual:[UIColor redColor]])
            switchMask |= (1 << i);
    }
    STAssertTrue(switchMask == 58, @"Switch mask wrong for turn switches on. Should be 58 instead is %d", switchMask);

    // Confirm that complex action sequence is interpreted as no action
    xmlString = @"<actionsequenceondevice><friendlyname>frood</friendlyname> <actionsequence> <delay>1.0</delay><turnSwitchesOff>2 4 5 6</turnSwitchesOff> </actionsequence></actionsequenceondevice>";
    document = [[DDXMLDocument alloc] initWithXMLString:xmlString options:0 error:nil];
    [actions removeAllObjects];
    [actions addObject:[[document children] objectAtIndex:0]];
    defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    [defineVC loadView];
    STAssertTrue([[defineVC pickerView:defineVC->actionPicker titleForRow:[defineVC->actionPicker selectedRowInComponent:1] forComponent:1] isEqualToString:@"No Action"], @"Must show 'No Action' when XML command is complex");
}

- (void)test_003_defineActionViewController_002_UpdateNoActionAndSwitches {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigControllerPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"supportSwitchamajigIRPreference"];
    // Create and initialize with no friendly names or actions
    NSMutableArray *actions = [[NSMutableArray alloc] initWithCapacity:5];
    SwitchControlAppDelegate *dummy_app_delegate = [SwitchControlAppDelegate alloc];
    [dummy_app_delegate setFriendlyNameSwitchamajigDictionary:[[NSMutableDictionary alloc] initWithCapacity:5]];
    [[dummy_app_delegate friendlyNameSwitchamajigDictionary] setObject:@"dummy1" forKey:@"hoopy"];
    defineActionViewController *defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    // Select Default and no action
    [defineVC->actionPicker selectRow:0 inComponent:0 animated:NO];
    [defineVC->actionPicker selectRow:0 inComponent:1 animated:NO];
    [defineVC pickerView:defineVC->actionPicker didSelectRow:0 inComponent:1];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    // There should now be an action
    STAssertTrue([actions count], @"Actions count isn't 1 with default sjig and no action");
    NSString *expectedAction = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence></actionsequence></actionsequenceondevice>";
    NSString *actionString = [[actions objectAtIndex:0] XMLString];
    STAssertTrue([actionString isEqualToString:expectedAction], @"Actions string incorrect for noaction. Expected %@ but got %@", expectedAction, actionString);
    // Select different switchamajig and the turnswitcheson
    [defineVC->actionPicker selectRow:1 inComponent:0 animated:NO];
    [defineVC->actionPicker selectRow:1 inComponent:1 animated:NO];
    [defineVC pickerView:defineVC->actionPicker didSelectRow:1 inComponent:1];
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    actionString = [[actions objectAtIndex:0] XMLString];
    expectedAction = @"<actionsequenceondevice><friendlyname>hoopy</friendlyname><actionsequence><turnSwitchesOn></turnSwitchesOn></actionsequence></actionsequenceondevice>";
    STAssertTrue([actionString isEqualToString:expectedAction], @"Actions string incorrect for turnswitcheson with no switches. Expected %@ but got %@", expectedAction, actionString);
    // Set a couple of switches
    SJActionUITurnSwitchesOn *turnSwitchesOnUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Turn Switches On"];
    SJActionUITurnSwitchesOff *turnSwitchesOffUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Turn Switches Off"];
    [turnSwitchesOnUI->switchButtons[0] sendActionsForControlEvents:UIControlEventTouchUpInside];
    [turnSwitchesOnUI->switchButtons[4] sendActionsForControlEvents:UIControlEventTouchUpInside];
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    actionString = [[actions objectAtIndex:0] XMLString];
    expectedAction = @"<actionsequenceondevice><friendlyname>hoopy</friendlyname><actionsequence><turnSwitchesOn>1 5 </turnSwitchesOn></actionsequence></actionsequenceondevice>";
    STAssertTrue([actionString isEqualToString:expectedAction], @"Actions string incorrect for turnswitcheson with switches 1 and 4. Expected %@ but got %@", expectedAction, actionString);
    [defineVC->actionPicker selectRow:2 inComponent:1 animated:NO];
    [defineVC pickerView:defineVC->actionPicker didSelectRow:2 inComponent:1];
    [turnSwitchesOffUI->switchButtons[0] sendActionsForControlEvents:UIControlEventTouchUpInside];
    [turnSwitchesOffUI->switchButtons[4] sendActionsForControlEvents:UIControlEventTouchUpInside];
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    actionString = [[actions objectAtIndex:0] XMLString];
    expectedAction = @"<actionsequenceondevice><friendlyname>hoopy</friendlyname><actionsequence><turnSwitchesOff>1 5 </turnSwitchesOff></actionsequence></actionsequenceondevice>";
    STAssertTrue([actionString isEqualToString:expectedAction], @"Actions string incorrect for turnswitchesoff with switches 1 and 4. Expected %@ but got %@", expectedAction, actionString);
    // Change switch selection
    [turnSwitchesOffUI->switchButtons[0] sendActionsForControlEvents:UIControlEventTouchUpInside];
    [turnSwitchesOffUI->switchButtons[1] sendActionsForControlEvents:UIControlEventTouchUpInside];
    [turnSwitchesOffUI->switchButtons[5] sendActionsForControlEvents:UIControlEventTouchUpInside];
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    actionString = [[actions objectAtIndex:0] XMLString];
    expectedAction = @"<actionsequenceondevice><friendlyname>hoopy</friendlyname><actionsequence><turnSwitchesOff>2 5 6 </turnSwitchesOff></actionsequence></actionsequenceondevice>";
    STAssertTrue([actionString isEqualToString:expectedAction], @"Actions string incorrect for turnswitchesoff with switches 2, 5, and 6. Expected %@ but got %@", expectedAction, actionString);
}

- (void)test_003_defineActionViewController_003_IR {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigControllerPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigIRPreference"];
    // Make sure the IR controls aren't visible by default
    NSMutableArray *actions = [[NSMutableArray alloc] initWithCapacity:5];
    SwitchControlAppDelegate *dummy_app_delegate = [SwitchControlAppDelegate alloc];
    [dummy_app_delegate setFriendlyNameSwitchamajigDictionary:[[NSMutableDictionary alloc] initWithCapacity:5]];
    [[dummy_app_delegate friendlyNameSwitchamajigDictionary] setObject:@"dummy1" forKey:@"hoopy"];
    defineActionViewController *defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    SJActionUIIRDatabaseCommand *actionUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Standard IR Command"];
    STAssertTrue([actionUI->irPicker isHidden] && [actionUI->irPickerLabel isHidden] && [actionUI->filterBrandButton isHidden] && [actionUI->filterFunctionButton isHidden] && [actionUI->testIrButton isHidden], @"IR UI is visible when no action is passed in");
    // Select IR command from action picker
    [defineVC->actionPicker selectRow:3 inComponent:1 animated:NO];
    [defineVC pickerView:defineVC->actionPicker didSelectRow:3 inComponent:1];
    STAssertFalse([actionUI->irPicker isHidden] || [actionUI->irPickerLabel isHidden] || [actionUI->filterBrandButton isHidden] || [actionUI->filterFunctionButton isHidden], @"IR UI not visible after selecting IR action.");
    STAssertTrue([actionUI->testIrButton isHidden], @"Test IR button visible with no IR devices connected");
    // Verify that we got the expected command
    NSString *expectedCommand = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><docommand key=\"0\" repeat=\"n\" seq=\"n\" command=\"Apple:Audio Accessory:UEI Setup Code 1115:PAUSE\" ir_data=\"UT111526\" ch=\"0\"></docommand></actionsequence></actionsequenceondevice>";
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    DDXMLNode *action = [actions objectAtIndex:0];
    NSString *actualCommand = [action XMLString];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Actual command mismatches. Got %@", actualCommand);
    // Verify that more/fewer brands works
    int numBrands = [actionUI pickerView:actionUI->irPicker numberOfRowsInComponent:0];
    STAssertTrue(numBrands == 20, @"Num brands wrong when reduced list shown. Has %d brands.", numBrands);
    STAssertTrue([[actionUI->filterBrandButton titleForState:UIControlStateNormal] isEqualToString:@"Show More Brands"], @"Text wrong on show more brands");
    [actionUI->filterBrandButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertTrue([[actionUI->filterBrandButton titleForState:UIControlStateNormal] isEqualToString:@"Show Fewer Brands"], @"Text wrong on show fewer brands");
    numBrands = [actionUI pickerView:actionUI->irPicker numberOfRowsInComponent:0];
    STAssertTrue(numBrands == 638, @"Num brands wrong when expanded list shown. Has %d brands.", numBrands);
    [actionUI->filterBrandButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertTrue([[actionUI->filterBrandButton titleForState:UIControlStateNormal] isEqualToString:@"Show More Brands"], @"Text wrong on show more brands after activating toggle twice");
    numBrands = [actionUI pickerView:actionUI->irPicker numberOfRowsInComponent:0];
    STAssertTrue(numBrands == 20, @"Num brands wrong when reduced list reshown. Has %d brands.", numBrands);
    // Verify that more/fewer functions works
    int numFunctions = [actionUI pickerView:actionUI->irPicker numberOfRowsInComponent:3];
    STAssertTrue(numFunctions == 4, @"Num functions wrong when reduced list shown. Has %d functions.", numFunctions);
    STAssertTrue([[actionUI->filterFunctionButton titleForState:UIControlStateNormal] isEqualToString:@"Show More Functions"], @"Text wrong on show more functions");
    [actionUI->filterFunctionButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertTrue([[actionUI->filterFunctionButton titleForState:UIControlStateNormal] isEqualToString:@"Show Fewer Functions"], @"Text wrong on show fewer functions");
    numFunctions = [actionUI pickerView:actionUI->irPicker numberOfRowsInComponent:3];
    STAssertTrue(numFunctions == 15, @"Num functions wrong when expanded list shown. Has %d functions.", numFunctions);
    [actionUI->filterFunctionButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertTrue([[actionUI->filterFunctionButton titleForState:UIControlStateNormal] isEqualToString:@"Show More Functions"], @"Text wrong on show more functions after activating toggle twice");
    numFunctions = [actionUI pickerView:actionUI->irPicker numberOfRowsInComponent:3];
    STAssertTrue(numFunctions == 4, @"Num functions wrong when reduced list reshown. Has %d functions.", numFunctions);
    // Touch every wheel on the UI
    [actionUI->irPicker selectRow:1 inComponent:0 animated:NO];
    [actionUI pickerView:actionUI->irPicker didSelectRow:1 inComponent:0];
    expectedCommand = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><docommand key=\"0\" repeat=\"n\" seq=\"n\" command=\"Coby:DTA Converter:UEI Setup Code 2667:CHANNEL DOWN\" ir_data=\"UT26675\" ch=\"0\"></docommand></actionsequence></actionsequenceondevice>";
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    action = [actions objectAtIndex:0];
    actualCommand = [action XMLString];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatches. Got %@", actualCommand);
    [actionUI->irPicker selectRow:2 inComponent:1 animated:NO];
    [actionUI pickerView:actionUI->irPicker didSelectRow:2 inComponent:1];
    expectedCommand = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><docommand key=\"0\" repeat=\"n\" seq=\"n\" command=\"Coby:DVD:Code Group 1:NEXT\" ir_data=\"P141f 1f26 7e1d 2595 018b 56a8 3032 b9a4 d95c 04e7 037b 83eb 5146 4643 5211 c619 f5d3 201b fc5c be57 a76a e9d5 ae7b 85a3 e2fd 670d 1b21 4432 ec1b b994 12df fcaa e2fd 670d 1b21 4432 ec1b b994 12df fcaa 9898 3e97 2ac3 90f9 5d0b 60b1 9030 2cee 9898 3e97 2ac3 90f9 5d0b 60b1 9030 2cee 5ef0 d152 e750 eb37 9785 838d 5f3b db42 6cb1 e039 98fa 9321 4a15 5627 fe87 486a 3c7c 84e2 390c 7b16 b638 3b12 6903 a545  \" ch=\"0\"></docommand></actionsequence></actionsequenceondevice>";
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    action = [actions objectAtIndex:0];
    actualCommand = [action XMLString];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatches. Got %@", actualCommand);
    [actionUI->irPicker selectRow:1 inComponent:2 animated:NO];
    [actionUI pickerView:actionUI->irPicker didSelectRow:1 inComponent:2];
    expectedCommand = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><docommand key=\"0\" repeat=\"n\" seq=\"n\" command=\"Coby:DVD:Code Group 2:FORWARD\" ir_data=\"P9464 7681 617b 5328 b4a2 abdd e391 6116 d95c 04e7 037b 83eb 5146 4643 5211 c619 f5d3 201b fc5c be57 a76a e9d5 ae7b 85a3 e2fd 670d 1b21 4432 ec1b b994 12df fcaa e2fd 670d 1b21 4432 ec1b b994 12df fcaa d95c 04e7 037b 83eb 5146 4643 5211 c619 9898 3e97 2ac3 90f9 5d0b 60b1 9030 2cee e2fd 670d 1b21 4432 ec1b b994 12df fcaa 1c3b de22 9f02 46e7 a341 90a8 212c 9071 395d da19 85c7 ad30 ca0b e6c2 27e3 8562  \" ch=\"0\"></docommand></actionsequence></actionsequenceondevice>";
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    action = [actions objectAtIndex:0];
    actualCommand = [action XMLString];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatches. Got %@", actualCommand);
    [actionUI->irPicker selectRow:1 inComponent:3 animated:NO];
    [actionUI pickerView:actionUI->irPicker didSelectRow:1 inComponent:3];
    expectedCommand = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><docommand key=\"0\" repeat=\"n\" seq=\"n\" command=\"Coby:DVD:Code Group 2:NEXT\" ir_data=\"Pa99a 533c fbc7 4574 b7cd 5bfe 1469 5e76 d95c 04e7 037b 83eb 5146 4643 5211 c619 f5d3 201b fc5c be57 a76a e9d5 ae7b 85a3 e2fd 670d 1b21 4432 ec1b b994 12df fcaa 4a1e 30e8 3e1c 8ea7 f51a fa30 6840 2414 9a09 e9c6 3593 4e7d d90b 9fd7 b774 9c96 9945 1207 d1e0 701d 533d bac8 e2ae d8bc 4a58 3f03 6eb4 4c41 8b69 06de 27bc 5281 65cb 7fa2 bc40 7e47 c758 d9a6 75be 1e10 310b 3e9d 126d d57c f98b d8d3 7504 1c7f  \" ch=\"0\"></docommand></actionsequence></actionsequenceondevice>";
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    action = [actions objectAtIndex:0];
    actualCommand = [action XMLString];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatches. Got %@", actualCommand);
    // Verify that testIR button appears when driver is present
    MockSwitchamajigDriver *driver = [[MockSwitchamajigDriver alloc] initWithHostname:@"localhost"];
    driver->commandsReceived = [[NSMutableArray alloc] initWithCapacity:5];
    [[dummy_app_delegate friendlyNameSwitchamajigDictionary] setObject:driver forKey:@"hoopy"];
    defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    actionUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Standard IR Command"];
    //STAssertTrue([actionUI->testIrButton isHidden], @"Test IR button visible before IR driver selected");
    [defineVC->actionPicker selectRow:1 inComponent:0 animated:NO];
    [defineVC pickerView:defineVC->actionPicker didSelectRow:1 inComponent:0];
    STAssertFalse([actionUI->testIrButton isHidden], @"Test IR button not visible after IR driver selected");
    [actionUI->testIrButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    STAssertTrue([driver->commandsReceived count]==1, @"No command received for test IR command");
    expectedCommand = @"<docommand key=\"0\" repeat=\"n\" seq=\"n\" command=\"Coby:DVD:Code Group 2:NEXT\" ir_data=\"Pa99a 533c fbc7 4574 b7cd 5bfe 1469 5e76 d95c 04e7 037b 83eb 5146 4643 5211 c619 f5d3 201b fc5c be57 a76a e9d5 ae7b 85a3 e2fd 670d 1b21 4432 ec1b b994 12df fcaa 4a1e 30e8 3e1c 8ea7 f51a fa30 6840 2414 9a09 e9c6 3593 4e7d d90b 9fd7 b774 9c96 9945 1207 d1e0 701d 533d bac8 e2ae d8bc 4a58 3f03 6eb4 4c41 8b69 06de 27bc 5281 65cb 7fa2 bc40 7e47 c758 d9a6 75be 1e10 310b 3e9d 126d d57c f98b d8d3 7504 1c7f  \" ch=\"0\"></docommand>";
    actualCommand = [driver->commandsReceived objectAtIndex:0];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatch for test IR. Got %@", actualCommand);
}

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
