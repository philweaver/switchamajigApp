//
//  SJActionUITests.m
//  SwitchControl
//
//  Created by Phil Weaver on 11/15/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "SJActionUITests.h"
#import "SJActionUITurnSwitchesOnOff.h"
#import "SJActionUIIRDatabaseCommand.h"
#import "SJActionUIlearnedIRCommand.h"
#import "SJActionUIIRQuickstart.h"
#import "SJActionUIBack.h"
#import "TestMocks.h"
#import "TestEnables.h"

@implementation SJActionUITests
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
    [HandyTestStuff logMemUsage];
}

#if RUN_ALL_ACTIONUI_TESTS
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
    STAssertTrue([defineVC->actionPicker numberOfRowsInComponent:1] == 2, @"With no drivers supported, defineActionPicker should show only two actions: 'No Action' and 'Back'");
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigControllerPreference"];
    defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    STAssertTrue([defineVC->actionPicker numberOfRowsInComponent:1] == 4, @"With only controller supported, defineActionPicker should show four actions.");
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigIRPreference"];
    defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    STAssertTrue([defineVC->actionPicker numberOfRowsInComponent:1] == 7, @"With both controller and IR supported, defineActionPicker shows %d actions.", [defineVC->actionPicker numberOfRowsInComponent:1]);
    
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
    [defineVC->actionPicker selectRow:2 inComponent:1 animated:NO];
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
    [defineVC->actionPicker selectRow:3 inComponent:1 animated:NO];
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
    SJActionUIIRDatabaseCommand *actionUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"IR from Database"];
    STAssertTrue([actionUI->irPicker isHidden] && [actionUI->irPickerLabel isHidden] && [actionUI->filterBrandButton isHidden] && [actionUI->filterFunctionButton isHidden] && [actionUI->testIrButton isHidden], @"IR UI is visible when no action is passed in");
    // Select IR command from action picker
    [defineVC->actionPicker selectRow:5 inComponent:1 animated:NO];
    [defineVC pickerView:defineVC->actionPicker didSelectRow:5 inComponent:1];
    STAssertFalse([actionUI->irPicker isHidden] || [actionUI->irPickerLabel isHidden] || [actionUI->filterBrandButton isHidden] || [actionUI->filterFunctionButton isHidden], @"IR UI not visible after selecting IR action.");
    STAssertTrue([actionUI->testIrButton isHidden], @"Test IR button visible with no IR devices connected");
    // Verify that we got the expected command
    NSString *expectedCommand = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><docommand key=\"0\" repeat=\"0\" seq=\"0\" command=\"Apple:Audio Accessory:UEI Setup Code 1115:PAUSE\" ir_data=\"UT111526\" ch=\"0\"></docommand></actionsequence></actionsequenceondevice>";
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
    expectedCommand = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><docommand key=\"0\" repeat=\"0\" seq=\"0\" command=\"Coby:DTA Converter:UEI Setup Code 2667:CHANNEL DOWN\" ir_data=\"UT26675\" ch=\"0\"></docommand></actionsequence></actionsequenceondevice>";
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    action = [actions objectAtIndex:0];
    actualCommand = [action XMLString];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatches. Got %@", actualCommand);
    [actionUI->irPicker selectRow:2 inComponent:1 animated:NO];
    [actionUI pickerView:actionUI->irPicker didSelectRow:2 inComponent:1];
    expectedCommand = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><docommand key=\"0\" repeat=\"0\" seq=\"0\" command=\"Coby:DVD:Code Group 1:NEXT\" ir_data=\"P141f 1f26 7e1d 2595 018b 56a8 3032 b9a4 d95c 04e7 037b 83eb 5146 4643 5211 c619 f5d3 201b fc5c be57 a76a e9d5 ae7b 85a3 e2fd 670d 1b21 4432 ec1b b994 12df fcaa e2fd 670d 1b21 4432 ec1b b994 12df fcaa 9898 3e97 2ac3 90f9 5d0b 60b1 9030 2cee 9898 3e97 2ac3 90f9 5d0b 60b1 9030 2cee 5ef0 d152 e750 eb37 9785 838d 5f3b db42 6cb1 e039 98fa 9321 4a15 5627 fe87 486a 3c7c 84e2 390c 7b16 b638 3b12 6903 a545  \" ch=\"0\"></docommand></actionsequence></actionsequenceondevice>";
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    action = [actions objectAtIndex:0];
    actualCommand = [action XMLString];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatches. Got %@", actualCommand);
    [actionUI->irPicker selectRow:1 inComponent:2 animated:NO];
    [actionUI pickerView:actionUI->irPicker didSelectRow:1 inComponent:2];
    expectedCommand = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><docommand key=\"0\" repeat=\"0\" seq=\"0\" command=\"Coby:DVD:Code Group 2:FORWARD\" ir_data=\"P9464 7681 617b 5328 b4a2 abdd e391 6116 d95c 04e7 037b 83eb 5146 4643 5211 c619 f5d3 201b fc5c be57 a76a e9d5 ae7b 85a3 e2fd 670d 1b21 4432 ec1b b994 12df fcaa e2fd 670d 1b21 4432 ec1b b994 12df fcaa d95c 04e7 037b 83eb 5146 4643 5211 c619 9898 3e97 2ac3 90f9 5d0b 60b1 9030 2cee e2fd 670d 1b21 4432 ec1b b994 12df fcaa 1c3b de22 9f02 46e7 a341 90a8 212c 9071 395d da19 85c7 ad30 ca0b e6c2 27e3 8562  \" ch=\"0\"></docommand></actionsequence></actionsequenceondevice>";
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    action = [actions objectAtIndex:0];
    actualCommand = [action XMLString];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatches. Got %@", actualCommand);
    [actionUI->irPicker selectRow:1 inComponent:3 animated:NO];
    [actionUI pickerView:actionUI->irPicker didSelectRow:1 inComponent:3];
    expectedCommand = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><docommand key=\"0\" repeat=\"0\" seq=\"0\" command=\"Coby:DVD:Code Group 2:NEXT\" ir_data=\"Pa99a 533c fbc7 4574 b7cd 5bfe 1469 5e76 d95c 04e7 037b 83eb 5146 4643 5211 c619 f5d3 201b fc5c be57 a76a e9d5 ae7b 85a3 e2fd 670d 1b21 4432 ec1b b994 12df fcaa 4a1e 30e8 3e1c 8ea7 f51a fa30 6840 2414 9a09 e9c6 3593 4e7d d90b 9fd7 b774 9c96 9945 1207 d1e0 701d 533d bac8 e2ae d8bc 4a58 3f03 6eb4 4c41 8b69 06de 27bc 5281 65cb 7fa2 bc40 7e47 c758 d9a6 75be 1e10 310b 3e9d 126d d57c f98b d8d3 7504 1c7f  \" ch=\"0\"></docommand></actionsequence></actionsequenceondevice>";
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    action = [actions objectAtIndex:0];
    actualCommand = [action XMLString];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatches. Got %@", actualCommand);
    [actionUI->irPicker selectRow:5 inComponent:4 animated:NO];
    [actionUI pickerView:actionUI->irPicker didSelectRow:1 inComponent:3];
    expectedCommand = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><docommand key=\"0\" repeat=\"5\" seq=\"0\" command=\"Coby:DVD:Code Group 2:NEXT\" ir_data=\"Pa99a 533c fbc7 4574 b7cd 5bfe 1469 5e76 d95c 04e7 037b 83eb 5146 4643 5211 c619 f5d3 201b fc5c be57 a76a e9d5 ae7b 85a3 e2fd 670d 1b21 4432 ec1b b994 12df fcaa 4a1e 30e8 3e1c 8ea7 f51a fa30 6840 2414 9a09 e9c6 3593 4e7d d90b 9fd7 b774 9c96 9945 1207 d1e0 701d 533d bac8 e2ae d8bc 4a58 3f03 6eb4 4c41 8b69 06de 27bc 5281 65cb 7fa2 bc40 7e47 c758 d9a6 75be 1e10 310b 3e9d 126d d57c f98b d8d3 7504 1c7f  \" ch=\"0\"></docommand></actionsequence></actionsequenceondevice>";
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    action = [actions objectAtIndex:0];
    actualCommand = [action XMLString];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatches. Got %@", actualCommand);
    // Verify that testIR button appears when driver is present
    MockSwitchamajigIRDriver *driver = [[MockSwitchamajigIRDriver alloc] initWithHostname:@"localhost"];
    driver->commandsReceived = [[NSMutableArray alloc] initWithCapacity:5];
    [[dummy_app_delegate friendlyNameSwitchamajigDictionary] setObject:driver forKey:@"hoopy"];
    defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    actionUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"IR from Database"];
    //STAssertTrue([actionUI->testIrButton isHidden], @"Test IR button visible before IR driver selected");
    [defineVC->actionPicker selectRow:1 inComponent:0 animated:NO];
    [defineVC pickerView:defineVC->actionPicker didSelectRow:1 inComponent:0];
    STAssertFalse([actionUI->irPicker isHidden] || [actionUI->irPickerLabel isHidden] || [actionUI->filterBrandButton isHidden] || [actionUI->filterFunctionButton isHidden], @"IR UI not visible when initialized with IR action.");
    STAssertFalse([actionUI->testIrButton isHidden], @"Test IR button not visible after IR driver selected");
    [actionUI->testIrButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    STAssertTrue([driver->commandsReceived count]==1, @"No command received for test IR command");
    expectedCommand = @"<docommand key=\"0\" repeat=\"5\" seq=\"0\" command=\"Coby:DVD:Code Group 2:NEXT\" ir_data=\"Pa99a 533c fbc7 4574 b7cd 5bfe 1469 5e76 d95c 04e7 037b 83eb 5146 4643 5211 c619 f5d3 201b fc5c be57 a76a e9d5 ae7b 85a3 e2fd 670d 1b21 4432 ec1b b994 12df fcaa 4a1e 30e8 3e1c 8ea7 f51a fa30 6840 2414 9a09 e9c6 3593 4e7d d90b 9fd7 b774 9c96 9945 1207 d1e0 701d 533d bac8 e2ae d8bc 4a58 3f03 6eb4 4c41 8b69 06de 27bc 5281 65cb 7fa2 bc40 7e47 c758 d9a6 75be 1e10 310b 3e9d 126d d57c f98b d8d3 7504 1c7f  \" ch=\"0\"></docommand>";
    actualCommand = [driver->commandsReceived objectAtIndex:0];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatch for test IR. Got %@", actualCommand);
}

- (void)test_003_defineActionViewController_004_IRLearning {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigControllerPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigIRPreference"];
    // Make sure the IR controls aren't visible by default
    NSMutableArray *actions = [[NSMutableArray alloc] initWithCapacity:5];
    SwitchControlAppDelegate *dummy_app_delegate = [SwitchControlAppDelegate alloc];
    [dummy_app_delegate setFriendlyNameSwitchamajigDictionary:[[NSMutableDictionary alloc] initWithCapacity:5]];
    [[dummy_app_delegate friendlyNameSwitchamajigDictionary] setObject:@"dummy1" forKey:@"hoopy"];
    defineActionViewController *defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    SJActionUIlearnedIRCommand *actionUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Learned IR Command"];
    STAssertTrue([actionUI->learnedIrPicker isHidden] && [actionUI->learnedIRPickerLabel isHidden] && [actionUI->learningIRInstructionsLabel isHidden] && [actionUI->learnIRButton isHidden] && [actionUI->testLearnedIRButton isHidden], @"Learned IR UI is visible when no action is passed in");
    // Select IR command from action picker
    [defineVC->actionPicker selectRow:6 inComponent:1 animated:NO];
    [defineVC pickerView:defineVC->actionPicker didSelectRow:6 inComponent:1];
    STAssertFalse([actionUI->learnedIrPicker isHidden] || [actionUI->learnedIRPickerLabel isHidden], @"Learned IR UI not visible after selecting IR action.");
    STAssertTrue([actionUI->testLearnedIRButton isHidden], @"Test IR button visible with no IR devices connected");
    STAssertTrue([actionUI->learnIRButton isHidden], @"Learn IR button visible with no IR devices connected");
    STAssertTrue([actionUI->learningIRInstructionsLabel isHidden] /*&& [actionUI->learningIRCancelButton isHidden]*/ && [actionUI->learnIRImage isHidden], @"IR learning UI visible without activating IR learning");
    NSString *xmlCommandString = [actionUI XMLStringForAction];
    // With no commands, action should be nil
    STAssertNil(xmlCommandString, @"Should not have valid action when nothing has been learned");
    // Re-open the UI when a driver is present
    MockSwitchamajigIRDriver *driver = [[MockSwitchamajigIRDriver alloc] initWithHostname:@"localhost"];
    driver->commandsReceived = [[NSMutableArray alloc] initWithCapacity:5];
    [[dummy_app_delegate friendlyNameSwitchamajigDictionary] setObject:driver forKey:@"hoopy"];
    defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    [defineVC->actionPicker selectRow:6 inComponent:1 animated:NO];
    [defineVC pickerView:defineVC->actionPicker didSelectRow:6 inComponent:1];
    actionUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Learned IR Command"];
    STAssertFalse([actionUI->testLearnedIRButton isHidden], @"Test Learned IR button not visible after IR driver selected");
    STAssertFalse([actionUI->learnIRButton isHidden], @"Learn IR button not visible after IR driver selected");
    // This is 1 only because of a workaround because returning 0 in ios6 crashes the app
    STAssertTrue([actionUI->learnedIrPicker numberOfRowsInComponent:0] == 1, @"Command present before IR learning");
    [actionUI->learnIRButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    // Verify that the learn IR UI is now visible
    STAssertFalse([actionUI->learningIRInstructionsLabel isHidden] /*|| [actionUI->learningIRCancelButton isHidden]*/ || [actionUI->learnIRImage isHidden], @"IR learning UI not visible after pressing IR learning button");
    // Verify that other buttons are disabled
    STAssertFalse([defineVC->doneButton isUserInteractionEnabled] || [defineVC->cancelButton isUserInteractionEnabled] || [defineVC->cancelButton isUserInteractionEnabled] || [defineVC->actionPicker isUserInteractionEnabled] || [actionUI->testLearnedIRButton isUserInteractionEnabled], @"Rest of UI not disabled during IR learning");
    // Learn an IR command
    [dummy_app_delegate SwitchamajigIRDeviceDriverDelegateDidReceiveLearnedIRCommand:driver irCommand:@"L30 12d00 da0400da 92cc06d0 36f00da 29000da dbb213 23333333 33332333 33322323 33333332 32222332 32233320"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    // Verify that the learn IR UI disappeared
    STAssertTrue([actionUI->learningIRInstructionsLabel isHidden] /*&& [actionUI->learningIRCancelButton isHidden]*/ && [actionUI->learnIRImage isHidden], @"Learned IR UI is visible after learned IR command arrived.");
    // Verify that rest of UI now enabled
    STAssertTrue([defineVC->doneButton isUserInteractionEnabled] && [defineVC->cancelButton isUserInteractionEnabled] && [defineVC->cancelButton isUserInteractionEnabled] && [defineVC->actionPicker isUserInteractionEnabled] && [actionUI->testLearnedIRButton isUserInteractionEnabled], @"UI not re-enabled after IR learning command arrived");
    // Verify that the IR picker now has a command
    STAssertTrue([actionUI->learnedIrPicker numberOfRowsInComponent:0] != 0, @"No command present after learned IR command arrived");
    STAssertTrue([actionUI->learnedIrPicker numberOfRowsInComponent:0] < 2, @"More than one command present after IR learning");
    // Confirm that command is correct
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    xmlCommandString = [actionUI XMLStringForAction];
    NSString *expectedCommand = @"<docommand key=\"0\" repeat=\"0\" seq=\"0\" command=\"Learned:Learned IR Command 1\" ir_data=\"L30 12d00 da0400da 92cc06d0 36f00da 29000da dbb213 23333333 33332333 33322323 33333332 32222332 32233320\" ch=\"0\"></docommand>";
    STAssertTrue([xmlCommandString isEqualToString:expectedCommand], @"Actual command mismatches. Got %@", xmlCommandString);
    // Set the picker wheel to repeat five times
    [actionUI->learnedIrPicker selectRow:5 inComponent:1 animated:NO];
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    xmlCommandString = [actionUI XMLStringForAction];

    expectedCommand = @"<docommand key=\"0\" repeat=\"5\" seq=\"0\" command=\"Learned:Learned IR Command 1\" ir_data=\"L30 12d00 da0400da 92cc06d0 36f00da 29000da dbb213 23333333 33332333 33322323 33333332 32222332 32233320\" ch=\"0\"></docommand>";
    STAssertTrue([xmlCommandString isEqualToString:expectedCommand], @"Actual command mismatches with repeat count = 5. Got %@", xmlCommandString);
    
    // Re-initialize the UI with with the command
    defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    actionUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Learned IR Command"];
    xmlCommandString = [actionUI XMLStringForAction];
    STAssertTrue([xmlCommandString isEqualToString:expectedCommand], @"Command is wrong after reloading it. Got %@", xmlCommandString);
    // Confirm that picker is properly initialized
    int currentRepeatCount = [actionUI->learnedIrPicker selectedRowInComponent:1];
    STAssertTrue(currentRepeatCount == 5, @"Repeat count did not initialize correctly. Value is %d", currentRepeatCount);
}


- (void)test_003_defineActionViewController_005_QuickIR {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigControllerPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"supportSwitchamajigIRPreference"];
    // Make sure the IR controls aren't visible by default
    NSMutableArray *actions = [[NSMutableArray alloc] initWithCapacity:5];
    MockSwitchControlDelegate *dummy_app_delegate = [MockSwitchControlDelegate alloc];
    dummy_app_delegate->irCodeSetToSend = nil;
    [dummy_app_delegate setFriendlyNameSwitchamajigDictionary:[[NSMutableDictionary alloc] initWithCapacity:5]];
    [[dummy_app_delegate friendlyNameSwitchamajigDictionary] setObject:@"dummy1" forKey:@"hoopy"];
    defineActionViewController *defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    [defineVC viewDidLoad];
    SJActionUIIRQuickstart *actionUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Quickstart IR"];
    STAssertTrue([actionUI->irPicker isHidden] && [actionUI->irPickerLabel isHidden] && [actionUI->filterFunctionButton isHidden] && [actionUI->testIrButton isHidden], @"Quick IR UI is visible when no action is passed in");
    // Select Quick IR command from action picker
    [defineVC->actionPicker selectRow:4 inComponent:1 animated:NO];
    [defineVC pickerView:defineVC->actionPicker didSelectRow:4 inComponent:1];
    STAssertFalse([actionUI->irPicker isHidden] || [actionUI->irPickerLabel isHidden] || [actionUI->filterFunctionButton isHidden], @"IR UI not visible after selecting IR action.");
    STAssertTrue([actionUI->testIrButton isHidden], @"Test IR button visible with no IR devices connected");
    // Verify that we got the expected command
    NSString *expectedCommand = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><quickIrCommand><deviceType>TV</deviceType><function>POWER TOGGLE</function></quickIrCommand></actionsequence></actionsequenceondevice>";
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    DDXMLNode *action = [actions objectAtIndex:0];
    NSString *actualCommand = [action XMLString];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Actual command mismatches. Got %@", actualCommand);
    // Verify that we have the right number of device types
    int numDeviceTypes = [actionUI pickerView:actionUI->irPicker numberOfRowsInComponent:0];
    STAssertTrue(numDeviceTypes == 3, @"Num device types wrong. Has %d device types.", numDeviceTypes);
    // Verify that more/fewer functions works
    int numFunctions = [actionUI pickerView:actionUI->irPicker numberOfRowsInComponent:1];
    STAssertTrue(numFunctions == 24, @"Num functions wrong when reduced list shown. Has %d functions.", numFunctions);
    STAssertTrue([[actionUI->filterFunctionButton titleForState:UIControlStateNormal] isEqualToString:@"Show More Functions"], @"Text wrong on show more functions");
    [actionUI->filterFunctionButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertTrue([[actionUI->filterFunctionButton titleForState:UIControlStateNormal] isEqualToString:@"Show Fewer Functions"], @"Text wrong on show fewer functions");
    numFunctions = [actionUI pickerView:actionUI->irPicker numberOfRowsInComponent:1];
    STAssertTrue(numFunctions == 24, @"Num functions wrong when expanded list shown. Has %d functions.", numFunctions);
    [actionUI->filterFunctionButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    STAssertTrue([[actionUI->filterFunctionButton titleForState:UIControlStateNormal] isEqualToString:@"Show More Functions"], @"Text wrong on show more functions after activating toggle twice");
    numFunctions = [actionUI pickerView:actionUI->irPicker numberOfRowsInComponent:1];
    STAssertTrue(numFunctions == 24, @"Num functions wrong when reduced list reshown. Has %d functions.", numFunctions);
    // Touch every wheel on the UI
    [actionUI->irPicker selectRow:1 inComponent:0 animated:NO];
    [actionUI pickerView:actionUI->irPicker didSelectRow:1 inComponent:0];
    expectedCommand = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><quickIrCommand><deviceType>Cable/Satellite</deviceType><function>POWER TOGGLE</function></quickIrCommand></actionsequence></actionsequenceondevice>";
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    action = [actions objectAtIndex:0];
    actualCommand = [action XMLString];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatches. Got %@", actualCommand);
    [actionUI->irPicker selectRow:2 inComponent:1 animated:NO];
    [actionUI pickerView:actionUI->irPicker didSelectRow:2 inComponent:1];
    expectedCommand = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><quickIrCommand><deviceType>Cable/Satellite</deviceType><function>PLAY</function></quickIrCommand></actionsequence></actionsequenceondevice>";
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    action = [actions objectAtIndex:0];
    actualCommand = [action XMLString];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatches. Got %@", actualCommand);
    // Verify setActions
    expectedCommand = @"<quickIrCommand><deviceType>DVD/Blu Ray</deviceType><function>PAUSE</function></quickIrCommand>";
    DDXMLDocument *initialActionDoc = [[DDXMLDocument alloc] initWithXMLString:expectedCommand options:0 error:nil];
    DDXMLNode *initialActionNode = [[initialActionDoc children] objectAtIndex:0];
    STAssertTrue([actionUI setAction:initialActionNode], @"Quick start UI doesn't recognize action");
    actualCommand = [actionUI XMLStringForAction];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatches. Got %@", actualCommand);
    
    // Verify that testIR button appears when driver is present
    MockSwitchamajigIRDriver *driver = [[MockSwitchamajigIRDriver alloc] initWithHostname:@"localhost"];
    driver->commandsReceived = [[NSMutableArray alloc] initWithCapacity:5];
    [[dummy_app_delegate friendlyNameSwitchamajigDictionary] setObject:driver forKey:@"hoopy"];
    defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    actionUI = [defineVC->actionNamesToSJActionUIDict objectForKey:@"Quickstart IR"];
    //STAssertTrue([actionUI->testIrButton isHidden], @"Test IR button visible before IR driver selected");
    [defineVC->actionPicker selectRow:1 inComponent:0 animated:NO];
    [defineVC pickerView:defineVC->actionPicker didSelectRow:1 inComponent:0];
    STAssertFalse([actionUI->testIrButton isHidden], @"Test IR button not visible after IR driver selected");
    dummy_app_delegate->irCodeSetToSend = @"All Models";
    [actionUI->testIrButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    STAssertTrue([driver->commandsReceived count]==1, @"No command received for test IR command");
    expectedCommand = @"<docommand key=\"0\" repeat=\"1\" seq=\"0\" command=\"0\" ir_data=\"Pedc4 89d6 7d56 a9c8 a757 0d59 5a57 6131 69ad f67f 1603 f1f0 03f1 8e2e 91d6 dc80 1cdd f511 21fa 5dd2 c024 97e3 d947 3a3e 1cdd f511 21fa 5dd2 c024 97e3 d947 3a3e 69ad f67f 1603 f1f0 03f1 8e2e 91d6 dc80 1cdd f511 21fa 5dd2 c024 97e3 d947 3a3e 915c 0451 0974 21e5 9629 07aa 26af 1aa7 bf23 820c c3fd c3ea 054c 350c 9fe1 2b02 1cdd f511 21fa 5dd2 c024 97e3 d947 3a3e 1cdd f511 21fa 5dd2 c024 97e3 d947 3a3e 11b4 6bc6 beac b29a 1d62 6584 cd9a 8f1e bf23 820c c3fd c3ea 054c 350c 9fe1 2b02 28bc 7199 bf62 289d 84f6 24d6 e8ae add2  \" ch=\"0\"></docommand>";
    actualCommand = [driver->commandsReceived objectAtIndex:0];
    STAssertTrue([actualCommand isEqualToString:expectedCommand], @"Command mismatch for test IR. Got %@", actualCommand);
}

- (void)test_003_defineActionViewController_006_Back {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"supportSwitchamajigControllerPreference"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"supportSwitchamajigIRPreference"];
    // Create and initialize with no friendly names or actions
    NSMutableArray *actions = [[NSMutableArray alloc] initWithCapacity:5];
    SwitchControlAppDelegate *dummy_app_delegate = [SwitchControlAppDelegate alloc];
    defineActionViewController *defineVC = [[defineActionViewController alloc] initWithActions:actions appDelegate:dummy_app_delegate];
    [defineVC loadView];
    // Select Default and Back
    [defineVC->actionPicker selectRow:0 inComponent:0 animated:NO];
    [defineVC->actionPicker selectRow:1 inComponent:1 animated:NO];
    [defineVC pickerView:defineVC->actionPicker didSelectRow:1 inComponent:1];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    [defineVC->doneButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    // There should now be an action
    STAssertTrue([actions count], @"Actions count isn't 1 with default sjig and back");
    NSString *expectedAction = @"<actionsequenceondevice><friendlyname>Default</friendlyname><actionsequence><back></back></actionsequence></actionsequenceondevice>";
    NSString *actionString = [[actions objectAtIndex:0] XMLString];
    STAssertTrue([actionString isEqualToString:expectedAction], @"Actions string incorrect for noaction. Expected %@ but got %@", expectedAction, actionString);
    // Confirm that the app delegate pops the nav controller when it gets this command
    MockNavigationController *navController = [[MockNavigationController alloc] init];
    navController->didReceivePopToRootViewController = false;
    DDXMLDocument *initialActionDoc = [[DDXMLDocument alloc] initWithXMLString:expectedAction options:0 error:nil];
    DDXMLNode *initialActionNode = [[initialActionDoc children] objectAtIndex:0];
    [dummy_app_delegate setNavigationController:navController];
    [dummy_app_delegate performActionSequence:initialActionNode];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.1]];
    STAssertTrue(navController->didReceivePopToRootViewController, @"Back action did not cause app delegate to pop the navigation controller");
    SJActionUIBack *back = [[SJActionUIBack alloc] init];
    DDXMLDocument *backActionDoc = [[DDXMLDocument alloc] initWithXMLString:@"<back></back>" options:0 error:nil];
    DDXMLNode *backActionNode = [[backActionDoc children] objectAtIndex:0];
    STAssertTrue([back setAction:backActionNode], @"Back action didn't accept xml node");
}

#endif // RUN_ALL_ACTIONUI_TESTS
@end
