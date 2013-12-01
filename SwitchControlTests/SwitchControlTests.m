//
//  SwitchControlTests.m
//  SwitchControlTests
//
//  Created by Phil Weaver on 7/23/11.
//  Copyright 2012 PAW Solutions. All rights reserved.
//
#import "SwitchControlTests.h"
#import "SJUIStatusMessageLabel.h"
#import "defineActionViewController.h"
#import "chooseIconViewController.h"
#import "quickStartSettingsViewController.h"
#import "quickIRConfigViewController.h"
#import "SwitchControlAppDelegate.h"
#import "TestEnables.h"
#import "TestMocks.h"

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
    [HandyTestStuff logMemUsage];
}

- (void) SJUIRecordAudioViewControllerReadyForDismissal:(id)viewController {
    didCallSJUIRecordAudioViewControllerReadyForDismissal = true;
}

#if RUN_ALL_TESTS_IN_MAIN_FILE
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
    // Mock up two Sjig controllers and to verify that commands come through
    MockSwitchamajigControllerDriver *driver1 = [MockSwitchamajigControllerDriver alloc];
    driver1->commandsReceived = [[NSMutableArray alloc] initWithCapacity:5];
    [[app_delegate friendlyNameSwitchamajigDictionary] setObject:driver1 forKey:@"frood"];
    MockSwitchamajigIRDriver *irDriver = [MockSwitchamajigIRDriver alloc];
    irDriver->commandsReceived = [[NSMutableArray alloc] initWithCapacity:5];
    [[app_delegate friendlyNameSwitchamajigDictionary] setObject:irDriver forKey:@"shrubbery"];
    // Configure QuickIR so we know what command to expect
    [app_delegate setIRBrand:@"Sony" andCodeSet:@"All Models All Types" andDevice:@"TV" forDeviceGroup:@"TV"];
    // Verify that Default commands are passed to the correct controller
    NSError *error;
    DDXMLDocument *node1 = [[DDXMLDocument alloc] initWithXMLString:@"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><turnSwitchesOn>1</turnSwitchesOn></actionsequence></actionsequenceondevice>" options:0 error:&error];
    [app_delegate performActionSequence:node1];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    node1 = [[DDXMLDocument alloc] initWithXMLString:@"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><quickIrCommand><deviceType>TV</deviceType><function>POWER ON/OFF</function><function>POWER TOGGLE</function></quickIrCommand></actionsequence></actionsequenceondevice>" options:0 error:&error];
    [app_delegate performActionSequence:node1];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    node1 = [[DDXMLDocument alloc] initWithXMLString:@"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><docommand key=\"0\" repeat=\"1\" seq=\"0\" command=\"Apple:Audio Accessory:UEI Setup Code 1115:PAUSE\" ir_data=\"UT111526\" ch=\"0\"></docommand></actionsequence></actionsequenceondevice>" options:0 error:&error];
    [app_delegate performActionSequence:node1];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    STAssertTrue([driver1->commandsReceived count] == 1, @"Controller driver received %d commands.", [driver1->commandsReceived count]);
    STAssertTrue([irDriver->commandsReceived count] == 2, @"IR driver received %d commands.", [irDriver->commandsReceived count]);
    NSString *commandString = [driver1->commandsReceived objectAtIndex:0];
    STAssertTrue([commandString isEqualToString:@"<turnSwitchesOn>1</turnSwitchesOn>"], @"IR driver command[1] is %@", commandString);
    commandString = [irDriver->commandsReceived objectAtIndex:0];
    STAssertTrue([commandString isEqualToString:@"<docommand key=\"0\" repeat=\"1\" seq=\"0\" command=\"0\" ir_data=\"P6501 802c 4a32 dbaa dc4d dd2c a526 3d20 427f 8cc4 0f67 d291 9f35 bff7 d926 dda7 137d eb0b ac1e eba4 fd0d 8a2b 872c e5aa 9d57 e90d 30d1 aa22 a451 10cc 9a9e 4c40  \" ch=\"0\"/>"], @"IR driver command[0] is %@", commandString);
    commandString = [irDriver->commandsReceived objectAtIndex:1];
    STAssertTrue([commandString isEqualToString:@"<docommand key=\"0\" repeat=\"1\" seq=\"0\" command=\"Apple:Audio Accessory:UEI Setup Code 1115:PAUSE\" ir_data=\"UT111526\" ch=\"0\"/>"], @"Controller driver command[0] is %@", commandString);
    // Verify that the command is passed when sent to the default controller
    DDXMLDocument *node2 = [[DDXMLDocument alloc] initWithXMLString:@"<actionsequenceondevice><friendlyname>frood</friendlyname><actionsequence><turnSwitchesOn>1</turnSwitchesOn></actionsequence></actionsequenceondevice>" options:0 error:&error];
    [app_delegate performActionSequence:node2];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    STAssertTrue([driver1->commandsReceived count] == 2, @"Driver did not receive command sent to it.");
    commandString = [driver1->commandsReceived objectAtIndex:1];
    STAssertTrue([commandString isEqualToString:@"<turnSwitchesOn>1</turnSwitchesOn>"], @"Did not receive command sent to named driver. Instead got %@", commandString);
    // Mock up a second Sjig controller and register it with a different name
    [app_delegate SwitchamajigDeviceListenerFoundDevice:listener hostname:@"localhost" friendlyname:@"hoopy"];
    // Verify that the new device is in the dictionary
    STAssertNotNil([[app_delegate friendlyNameSwitchamajigDictionary] objectForKey:@"hoopy"], @"Second device not in dictionary after being detected");
    // Mock up a Sjig controller and to verify that commands come through
    MockSwitchamajigControllerDriver *driver2 = [MockSwitchamajigControllerDriver alloc];
    driver2->commandsReceived = [[NSMutableArray alloc] initWithCapacity:5];
    [[app_delegate friendlyNameSwitchamajigDictionary] setObject:driver2 forKey:@"hoopy"];
    // Verify that commands can go to both controllers
    DDXMLDocument *node3 = [[DDXMLDocument alloc] initWithXMLString:@"<actionsequenceondevice><friendlyname>hoopy</friendlyname><actionsequence><turnSwitchesOn>2</turnSwitchesOn></actionsequence></actionsequenceondevice>" options:0 error:&error];
    [app_delegate performActionSequence:node3];
    node1 = [[DDXMLDocument alloc] initWithXMLString:@"<actionsequenceondevice><friendlyname>frood</friendlyname><actionsequence><turnSwitchesOn>1</turnSwitchesOn></actionsequence></actionsequenceondevice>" options:0 error:&error];
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
    MockSwitchamajigControllerDriver *driver1 = [MockSwitchamajigControllerDriver alloc];
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

- (void)test_000_AppDelegate_003_IRDefaults {
    [app_delegate setIRBrand:@"Sony" andCodeSet:@"hoopy" andDevice:@"DVD" forDeviceGroup:@"DVD/Blu Ray"];
    NSString *brand = [app_delegate getIRBrandForDeviceGroup:@"DVD/Blu Ray"];
    NSString *codeSet = [app_delegate getIRCodeSetForDeviceGroup:@"DVD/Blu Ray"];
    NSString *device = [app_delegate getIRDeviceForDeviceGroup:@"DVD/Blu Ray"];
    STAssertTrue([brand isEqualToString:@"Sony"], @"Brand not set for ir defaults. Instead got %@", brand);
    STAssertTrue([codeSet isEqualToString:@"hoopy"], @"Code set not set for ir defaults. Instead got %@", codeSet);
    STAssertTrue([device isEqualToString:@"DVD"], @"Device not set for ir defaults. Instead got %@", codeSet);
    [app_delegate setIRBrand:@"Panasonic" andCodeSet:@"frood" andDevice:@"Blu Ray" forDeviceGroup:@"DVD/Blu Ray"];
    brand = [app_delegate getIRBrandForDeviceGroup:@"DVD/Blu Ray"];
    codeSet = [app_delegate getIRCodeSetForDeviceGroup:@"DVD/Blu Ray"];
    device = [app_delegate getIRDeviceForDeviceGroup:@"DVD/Blu Ray"];
    STAssertTrue([brand isEqualToString:@"Panasonic"], @"Brand not set for ir defaults. Instead got %@", brand);
    STAssertTrue([codeSet isEqualToString:@"frood"], @"Code set not set for ir defaults. Instead got %@", codeSet);
    STAssertTrue([device isEqualToString:@"Blu Ray"], @"Device not set for ir defaults. Instead got %@", codeSet);
}


- (void)test_000_AppDelegate_004_QuickIRCommand {
    SwitchamajigControllerDeviceListener *listener = [SwitchamajigControllerDeviceListener alloc];
    [[app_delegate friendlyNameSwitchamajigDictionary] removeAllObjects];
    [app_delegate SwitchamajigDeviceListenerFoundDevice:listener hostname:@"localhost" friendlyname:@"frood"];
    // Verify that the new device is in the dictionary
    STAssertNotNil([[app_delegate friendlyNameSwitchamajigDictionary] objectForKey:@"frood"], @"Device not in dictionary after being detected");
    // Mock up a Sjig controller and to verify that commands come through
    MockSwitchamajigIRDriver *driver1 = [MockSwitchamajigIRDriver alloc];
    driver1->commandsReceived = [[NSMutableArray alloc] initWithCapacity:5];
    [[app_delegate friendlyNameSwitchamajigDictionary] setObject:driver1 forKey:@"frood"];
    // Verify that the command is passed to the controller
    NSError *error;
    DDXMLDocument *node1 = [[DDXMLDocument alloc] initWithXMLString:@"<actionsequenceondevice><friendlyname>frood</friendlyname><actionsequence><quickIrCommand><deviceType>TV</deviceType><function>POWER ON/OFF</function><function>POWER TOGGLE</function></quickIrCommand></actionsequence></actionsequenceondevice>" options:0 error:&error];
    [app_delegate setIRBrand:@"Sony" andCodeSet:@"All Models All Types" andDevice:@"TV" forDeviceGroup:@"TV"];
    [app_delegate performActionSequence:node1];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    STAssertTrue([driver1->commandsReceived count] == 1, @"Driver did not receive ir command.");
    NSString *commandString = [driver1->commandsReceived objectAtIndex:0];
    STAssertTrue([commandString isEqualToString:@"<docommand key=\"0\" repeat=\"1\" seq=\"0\" command=\"0\" ir_data=\"P6501 802c 4a32 dbaa dc4d dd2c a526 3d20 427f 8cc4 0f67 d291 9f35 bff7 d926 dda7 137d eb0b ac1e eba4 fd0d 8a2b 872c e5aa 9d57 e90d 30d1 aa22 a451 10cc 9a9e 4c40  \" ch=\"0\"/>"], @"Did not receive simple command. Instead got %@", commandString);
}

- (void)test_000_AppDelegate_005_Insteon {
    // Confirm that the appdelegate is the delegate for the insteon listener
    STAssertEqualObjects([app_delegate->sjigInsteonListener delegate], app_delegate, @"App Delegate isn't set up to listen for Insteons.");
    // Confirm that we respond to Insteon found
    SwitchamajigInsteonDeviceListener *listener = [SwitchamajigInsteonDeviceListener alloc];
    [[app_delegate friendlyNameSwitchamajigDictionary] removeAllObjects];
    [app_delegate SwitchamajigDeviceListenerFoundDevice:listener hostname:@"localhost" friendlyname:@"insteon_test"];
    STAssertEqualObjects([[[app_delegate friendlyNameSwitchamajigDictionary] objectForKey:@"insteon_test"] class], [SwitchamajigInsteonDeviceDriver class], @"Insteon driver not set up after listener reports found");
    // Confirm that commands are sent along to driver
    MockSwitchamajigInsteonDriver *driver = [MockSwitchamajigInsteonDriver alloc];
    driver->commandsReceived = [[NSMutableArray alloc] initWithCapacity:5];
    [[app_delegate friendlyNameSwitchamajigDictionary] setObject:driver forKey:@"insteon_test"];
    // Verify that the command is passed to the controller
    NSError *error;
    DDXMLDocument *node1 = [[DDXMLDocument alloc] initWithXMLString:@"<actionsequenceondevice><friendlyname>insteon_test</friendlyname><actionsequence><insteon_send><dst_addr>2016B7</dst_addr><command>ON</command><username>admin</username><password>shadow</password></insteon_send></actionsequence></actionsequenceondevice>" options:0 error:&error];
    [app_delegate performActionSequence:node1];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    STAssertTrue([driver->commandsReceived count] == 1, @"Driver did not receive ir command.");
    NSString *commandString = [driver->commandsReceived objectAtIndex:0];
    STAssertTrue([commandString isEqualToString:@"<insteon_send><dst_addr>2016B7</dst_addr><command>ON</command><username>admin</username><password>shadow</password></insteon_send>"], @"Did not receive insteon command. Instead got %@", commandString);
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

+ (int) numberOfSubviewOverlapsInView:(UIView *)view {
    NSArray *theSubviews = [view subviews];
    int numOverlaps = 0;
    int i;
    if([view isKindOfClass:[UIButton class]]) {
        // Starting in ios 6, I'm seeing lots of overlaps inside a UIButton. Since I'm not really worried about how buttons are constructed, exclude them.
         return 0;
    }
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
            /*NSLog(@"Out-of-bounds: (%4.1f, %4.1f, %4.1f, %4.1f) doesn't contain (%4.1f, %4.1f, %4.1f, %4.1f)", rect1.origin.x, rect1.origin.y, rect1.size.width, rect1.size.height, rect2.origin.x, rect2.origin.y, rect2.size.width, rect2.size.height);
            if([view isKindOfClass:[UIButton class]]) {
                NSLog(@"Superview is button. Title is %@", [(UIButton*)view titleForState:UIControlStateNormal]);
            }
            if([subView isKindOfClass:[UIButton class]]) {
                NSLog(@"Subview is button. Title is %@", [(UIButton*)subView titleForState:UIControlStateNormal]);
            }*/
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
    const int num_expected_overlaps = 0; 
    const int num_expected_outofbounds = 0;
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
         [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigControllerPreference"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigIRPreference"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"allowEditingOfSwitchPanelsPreference"];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showQuickStartWizardButtonPreference"];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
        rootSwitchViewController *tempRootViewController = [rootSwitchViewController alloc];
         tempRootViewController = [tempRootViewController init];
        [tempRootViewController.view setFrame:CGRectMake(0, 20, 1024, 748)];
        // Confirm text sizes
        STAssertTrue([SwitchControlTests CheckAllTextInView:[tempRootViewController view] hasSize:textSize], @"Text Size Check Failed. textSize = %f, conditionsIndex = %d, buttonSize = %f", textSize, testConditionIndex, buttonSize);
        // Make sure we don't have inappropriate overlaps
        int numOverlaps = [SwitchControlTests numberOfSubviewOverlapsInView:[tempRootViewController view]];
        STAssertTrue((numOverlaps == num_expected_overlaps), @"Overlapping views: found %d != expected %d textSize = %f, conditionsIndex = %d, buttonSize = %f", numOverlaps, num_expected_overlaps, textSize, testConditionIndex, buttonSize);
        // Stuff should (generally) be inside its parent view
        int numOutOfBounds = [SwitchControlTests numberOfSubviewsOutsideParents:[tempRootViewController view]];
        STAssertTrue((numOutOfBounds == num_expected_outofbounds), @"Out of bounds views: found %d != expected %d textSize = %f, conditionsIndex = %d, buttonSize = %f", numOutOfBounds, num_expected_outofbounds, textSize, testConditionIndex, buttonSize);
        [nav_controller popViewControllerAnimated:NO];
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
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
    [[[[rootViewController panelSelectionScrollView] subviews] objectAtIndex:0] sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertTrue(naviControl->didReceivePushViewController, @"Selecting switch panel did not push view controller");
    STAssertTrue([naviControl->lastViewController isKindOfClass:[switchPanelViewController class]], @"Switch panel did not display");
}


// Check settings for various support
- (void)test_001_RootViewController_006_LaunchSwitchPanel {
    // Enable showing of default panels
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showDefaultPanelsPreference"];
    // Disable individual support
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"supportSwitchamajigControllerPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"supportSwitchamajigIRPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"allowEditingOfSwitchPanelsPreference"];
    [rootViewController ResetScrollPanel];
    // Shouldn't see much
    STAssertNil([HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"], @"Yellow panel shown with controller support disabled.");
    STAssertNil([HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Simple TV"], @"IR Basic panel shown with IR support disabled.");
    STAssertNil([HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Blank"], @"Blank panel shown with editing support disabled.");
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigControllerPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigIRPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"allowEditingOfSwitchPanelsPreference"];
    [rootViewController ResetScrollPanel];
    // Should see them now
    STAssertNotNil([HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"], @"Yellow panel not shown with controller support enabled.");
    STAssertNotNil([HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Simple TV"], @"IR Basic panel not shown with IR support enabled.");
    STAssertNotNil([HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Blank"], @"Blank panel not shown with editing support enabled.");
    // Disable showing of default panels
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showDefaultPanelsPreference"];
    [rootViewController ResetScrollPanel];
    // Again shouldn't see much
    STAssertNil([HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Yellow"], @"Yellow panel shown with default panels turned off.");
    STAssertNil([HandyTestStuff findSubviewOf:[rootViewController panelSelectionScrollView] withText:@"Simple TV"], @"IR Basic panel shown with default panels turned off.");
    // Re-enable support for default panels
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showDefaultPanelsPreference"];

}

- (void)test_001_RootViewController_007_Scanning {
    // Disable scanning
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"scanningStylePreference"];
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
}

- (void)test_004_QuickStartViewController_000_AppearanceAndInitialization {
    // Check that the root controller will display the settings if the program hasn't been run before
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"firstRun"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showQuickStartWizardButtonPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"supportSwitchamajigControllerPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigIRPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"allowEditingOfSwitchPanelsPreference"];
    rootViewController = [[rootSwitchViewController alloc] initWithNibName:nil bundle:nil];
    MockNavigationController *naviControl = [[MockNavigationController alloc] initWithRootViewController:rootViewController];
    naviControl->didReceivePushViewController = NO;
    [rootViewController view];
    [rootViewController viewDidLoad];
    STAssertNil([rootViewController showQuickstartWizardButton], @"Quick start wizard button should not exist when preferences say not to show it");
    STAssertTrue(naviControl->didReceivePushViewController, @"quickStart not shown on first run");
    STAssertTrue([naviControl->lastViewController isKindOfClass:[quickStartSettingsViewController class]], @"Wrong kind of view controller shown for quickstart");
    quickStartSettingsViewController *qsViewController = (quickStartSettingsViewController *)naviControl->lastViewController;
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    [qsViewController view];
    [qsViewController viewDidLoad];
    // Check that the toggle switches are initialized properly
    STAssertFalse([[qsViewController supportSwitchamajigControllerSwitch] isOn], @"Support Controller Switch not initialized correctly");
    STAssertTrue([[qsViewController supportSwitchamajigIRSwitch] isOn], @"Support Controller Switch not initialized correctly");
    STAssertFalse([[qsViewController allowEditingSwitch] isOn], @"Support Controller Switch not initialized correctly");
    // Confirm that the navigation controller shows the back button
    // Confirm that future restarts don't show quickstart
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"showQuickStartWizardButtonPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigControllerPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"supportSwitchamajigIRPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"allowEditingOfSwitchPanelsPreference"];
    rootViewController = [[rootSwitchViewController alloc] initWithNibName:nil bundle:nil];
    naviControl = [[MockNavigationController alloc] initWithRootViewController:rootViewController];
    naviControl->didReceivePushViewController = NO;
    [rootViewController view];
    [rootViewController viewDidLoad];
    STAssertNotNil([rootViewController showQuickstartWizardButton], @"Quick start wizard button should not exist when preferences say to show it");
    STAssertFalse(naviControl->didReceivePushViewController, @"quickStart shown on second run");
    [[rootViewController showQuickstartWizardButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertTrue(naviControl->didReceivePushViewController, @"quickStart not shown on button press");
    // Check that the toggle switches are initialized properly
    qsViewController = (quickStartSettingsViewController *)naviControl->lastViewController;
    [qsViewController view];
    [qsViewController viewDidLoad];
    STAssertTrue([[qsViewController supportSwitchamajigControllerSwitch] isOn], @"Support Controller Switch not initialized correctly");
    STAssertFalse([[qsViewController supportSwitchamajigIRSwitch] isOn], @"Support Controller Switch not initialized correctly");
    STAssertTrue([[qsViewController allowEditingSwitch] isOn], @"Support Controller Switch not initialized correctly");
}

- (void)test_005_QuickIRConfigViewController_000_InitializationAndBasicFunctions {
    MockSwitchControlDelegate *mySwitchDelegate = [MockSwitchControlDelegate alloc];
    quickIRConfigViewController *qirVC = [[quickIRConfigViewController alloc] initWithNibName:@"quickIRConfigViewController" bundle:[NSBundle mainBundle]];
    [qirVC setAppDelegate:mySwitchDelegate];
    [qirVC setDeviceGroup:@"TV"];
    NSURL *tvControlURL = [NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"qs_tv" ofType:@"xml"]];
    [qirVC setUrlForControlPanel:tvControlURL];
    [qirVC view];
    [qirVC viewDidLoad];
    // Check that the code set is configured correctly
    NSString *currentBrand = [qirVC pickerView:[qirVC brandPickerView] titleForRow:[[qirVC brandPickerView] selectedRowInComponent:0] forComponent:0];
    STAssertTrue([currentBrand isEqualToString:@"Panasonic:TV"], @"Brand failed to initialize from delegate");
    // Check that the delegate was set to the proper value
    STAssertTrue([mySwitchDelegate->lastIRDevice isEqualToString:@"TV"], @"Did not update delegate with proper device. Instead is %@", mySwitchDelegate->lastIRDevice);
    STAssertTrue([mySwitchDelegate->lastIRBrand isEqualToString:@"Panasonic"], @"Did not update delegate with proper brand. Instead is %@", mySwitchDelegate->lastIRBrand);
    STAssertTrue([mySwitchDelegate->lastIRCodeSet isEqualToString:@"All Models"], @"Did not update delegate with proper code set. Instead is %@", mySwitchDelegate->lastIRCodeSet);
    // Fiddle with the UI a bit
    [[qirVC filterBrandButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[qirVC brandPickerView] selectRow:5 inComponent:0 animated:NO];
    [qirVC pickerView:[qirVC brandPickerView] didSelectRow:5 inComponent:0];
    STAssertTrue([mySwitchDelegate->lastIRBrand isEqualToString:@"Akai"], @"Did not update delegate with proper brand. Instead is %@", mySwitchDelegate->lastIRBrand);
    STAssertTrue([mySwitchDelegate->lastIRCodeSet isEqualToString:@"Code Group 2 (RPTV)"], @"Did not update delegate with proper code set. Instead is %@", mySwitchDelegate->lastIRCodeSet);
    [[qirVC codeSetPickerView] selectRow:1 inComponent:0 animated:NO];
    [qirVC pickerView:[qirVC codeSetPickerView] didSelectRow:1 inComponent:0];
    STAssertTrue([mySwitchDelegate->lastIRBrand isEqualToString:@"Akai"], @"Did not update delegate with proper brand. Instead is %@", mySwitchDelegate->lastIRBrand);
    STAssertTrue([mySwitchDelegate->lastIRCodeSet isEqualToString:@"Code Group 1 (Plasma Displays)"], @"Did not update delegate with proper code set. Instead is %@", mySwitchDelegate->lastIRCodeSet);
}

- (void)test006_SJUIRecordAudioViewController_000_LifeCycle {
    // Create a view controller
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSURL *tempSoundURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:@"__tempSound.caf"]];
    didCallSJUIRecordAudioViewControllerReadyForDismissal = false;
    SJUIRecordAudioViewController *audioRecorder;
    
    // Cancel while recording
    audioRecorder = [[SJUIRecordAudioViewController alloc] initWithURL:tempSoundURL andDelegate:self];
    [audioRecorder record:nil];
    [audioRecorder cancel:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    STAssertTrue(didCallSJUIRecordAudioViewControllerReadyForDismissal, @"Audio recorder did not try to dismiss itself on cancel");
    audioRecorder = nil;
    // File should not exist
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[tempSoundURL path]], @"Audio file not deleted on cancel");
    
    // Hit done while recording
    audioRecorder = [[SJUIRecordAudioViewController alloc] initWithURL:tempSoundURL andDelegate:self];
    didCallSJUIRecordAudioViewControllerReadyForDismissal = false;
    // Done during record
    [audioRecorder record:nil];
    [audioRecorder done:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    STAssertTrue(didCallSJUIRecordAudioViewControllerReadyForDismissal, @"Audio recorder did not try to dismiss itself on done");
    audioRecorder = nil;
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[tempSoundURL path]], @"Audio file not present after done");
    [[NSFileManager defaultManager] removeItemAtPath:[tempSoundURL path] error:nil];
   
    // Record and play back
    audioRecorder = [[SJUIRecordAudioViewController alloc] initWithURL:tempSoundURL andDelegate:self];
    didCallSJUIRecordAudioViewControllerReadyForDismissal = false;
    // Record a brief segment
    [audioRecorder record:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    [audioRecorder record:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[tempSoundURL path]], @"Audio file not present after recording");
    // Play the audio
    [audioRecorder play:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Play it again and hit done during playback
    [audioRecorder play:nil];
    [audioRecorder done:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    STAssertTrue(didCallSJUIRecordAudioViewControllerReadyForDismissal, @"Audio recorder did not try to dismiss itself on done");
    audioRecorder = nil;
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[tempSoundURL path]], @"Audio file not present after hitting done during playback");

    [[NSFileManager defaultManager] removeItemAtPath:[tempSoundURL path] error:nil];
    // Cancel during playback
    audioRecorder = [[SJUIRecordAudioViewController alloc] initWithURL:tempSoundURL andDelegate:self];
    didCallSJUIRecordAudioViewControllerReadyForDismissal = false;
    // Record a brief segment
    [audioRecorder record:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    [audioRecorder record:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    STAssertTrue([[NSFileManager defaultManager] fileExistsAtPath:[tempSoundURL path]], @"Audio file not present after recording");
    // Play it again and hit cancel during playback
    [audioRecorder play:nil];
    [audioRecorder cancel:nil];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    STAssertTrue(didCallSJUIRecordAudioViewControllerReadyForDismissal, @"Audio recorder did not try to dismiss itself on done");
    audioRecorder = nil;
    STAssertFalse([[NSFileManager defaultManager] fileExistsAtPath:[tempSoundURL path]], @"Audio file present after hitting cancel during playback");
}

#endif // RUN_ALL_TESTS

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
