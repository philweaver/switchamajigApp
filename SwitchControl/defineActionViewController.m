//
//  defineActionViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 7/25/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "defineActionViewController.h"
#import "../../KissXML/KissXML/DDXMLDocument.h"
#import "../../SwitchamajigDriver/SwitchamajigDriver/SwitchamajigDriver.h"
#import "SJActionUITurnSwitchesOnOff.h"
#import "SJActionUIIRDatabaseCommand.h"
#import "SJActionUIlearnedIRCommand.h"
#import "SJActionUIIRQuickstart.h"

@implementation defineActionViewController
@synthesize actions;
@synthesize appDelegate;
@synthesize delegate;

- (id) initWithActions:(NSMutableArray *)actionsInit appDelegate:(SwitchControlAppDelegate *)theAppDelegate {
    self = [super init];
    if(self != nil) {
        [self setActions:actionsInit];
        [self setAppDelegate:theAppDelegate];
        [self setContentSizeForViewInPopover:CGSizeMake(800, 600)];
        [[theAppDelegate statusInfoLock] lock];
        friendlyNamesArray = [[NSMutableArray alloc] initWithArray:[[appDelegate friendlyNameSwitchamajigDictionary] allKeys]];
        [[theAppDelegate statusInfoLock] unlock];
        // Initialize dictionary of all possible actions
        SJActionUITurnSwitchesOn *turnSwitchesOnUI = [[SJActionUITurnSwitchesOn alloc] init];
        SJActionUITurnSwitchesOff *turnSwitchesOffUI = [[SJActionUITurnSwitchesOff alloc] init];
        SJActionUIIRDatabaseCommand *irDBUI = [[SJActionUIIRDatabaseCommand alloc] init];
        SJActionUIlearnedIRCommand *irLearnUI = [[SJActionUIlearnedIRCommand alloc] init];
        SJActionUIIRQuickstart *irQuickStartUI = [[SJActionUIIRQuickstart alloc] init];
        SJActionUINoAction *noactionUI = [[SJActionUINoAction alloc] init];
        actionNamesToSJActionUIDict = [[NSDictionary alloc] initWithObjectsAndKeys:turnSwitchesOnUI, [SJActionUITurnSwitchesOn name],turnSwitchesOffUI, [SJActionUITurnSwitchesOff name], irQuickStartUI, [SJActionUIIRQuickstart name], irDBUI, [SJActionUIIRDatabaseCommand name], irLearnUI, [SJActionUIlearnedIRCommand name], noactionUI, [SJActionUINoAction name], nil];
        // Maintain a separate array of which actions are supported right now
        availableActions = [[NSMutableArray alloc] initWithCapacity:5];
        [availableActions addObject:[SJActionUINoAction name]];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"supportSwitchamajigControllerPreference"]) {
            [availableActions addObject:[SJActionUITurnSwitchesOn name]];
            [availableActions addObject:[SJActionUITurnSwitchesOff name]];
        }
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"supportSwitchamajigIRPreference"]) {
            [availableActions addObject:[SJActionUIIRQuickstart name]];
            [availableActions addObject:[SJActionUIIRDatabaseCommand name]];
            [availableActions addObject:[SJActionUIlearnedIRCommand name]];
        }
    }
    return self;
}


- (void)loadView {
    CGSize viewSize = [self contentSizeForViewInPopover];
    CGRect cgRct = CGRectMake(0, 0, viewSize.width, viewSize.height);
    UIView *myView = [[UIView alloc] initWithFrame:cgRct];
    [self setView:myView];
    [myView setBackgroundColor:[UIColor blackColor]];
    NSInteger startingFriendlyNameIndex = 0;

    // Add default and current friendly name to list of friendly names if not already there
    if(![friendlyNamesArray containsObject:@"Default"])
        [friendlyNamesArray insertObject:@"Default" atIndex:0];
    NSError *xmlError;
    DDXMLNode *action;
    for(action in [self actions]) {
        NSArray *friendlyNamesDDXML = [action nodesForXPath:@".//friendlyname" error:&xmlError];
        DDXMLNode *friendlyNameNode;
        for(friendlyNameNode in friendlyNamesDDXML) {
            NSString *friendlyName = [friendlyNameNode stringValue];
            NSInteger indexOfNameNode = [friendlyNamesArray indexOfObject:friendlyName];
            if(indexOfNameNode == NSNotFound) {
                [friendlyNamesArray insertObject:friendlyName atIndex:1];
                startingFriendlyNameIndex = 1;
            } else {
                startingFriendlyNameIndex = indexOfNameNode;
            }
        }
    }

    // Initialize Picker
    actionPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(100, 50, 600, 162)];
    [actionPicker setDelegate:self];
    [actionPicker setDataSource:self];
    [actionPicker setShowsSelectionIndicator:YES];
    [actionPicker selectRow:startingFriendlyNameIndex inComponent:0 animated:NO];
    [myView addSubview:actionPicker];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 6, 300, 44)];
    [label setBackgroundColor:[UIColor blackColor]];
    [label setTextColor:[UIColor whiteColor]];
    [label setText:@"Choose Device"];
    [label setTextAlignment:UITextAlignmentCenter];
    [label setFont:[UIFont systemFontOfSize:20]];
    [myView addSubview:label];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(400, 6, 300, 44)];
    [label setBackgroundColor:[UIColor blackColor]];
    [label setTextColor:[UIColor whiteColor]];
    [label setText:@"Choose Action"];
    [label setTextAlignment:UITextAlignmentCenter];
    [label setFont:[UIFont systemFontOfSize:20]];
    [myView addSubview:label];
    
    cancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [cancelButton setFrame:CGRectMake(600, 550, 200, 44)];
    [cancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(onCancel:) forControlEvents:UIControlEventTouchUpInside];
    [myView addSubview:cancelButton];
    
    doneButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [doneButton setFrame:CGRectMake(000, 550, 200, 44)];
    [doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(onDone:) forControlEvents:UIControlEventTouchUpInside];
    [myView addSubview:doneButton];
    
    // Load the UI for all possible actions
    SJActionUI *actionUI;
    for(actionUI in [actionNamesToSJActionUIDict allValues]) {
        [actionUI setDefineActionVC:self];
        [actionUI createUI];
    }
    
    // Determine initial action
    NSString *initialActionName = [SJActionUINoAction name];
    if([[self actions] count] == 1) { // Only support a single action for now
        action = [[self actions] objectAtIndex:0];
        //NSLog(@"action: %@", [action XMLString]);
        NSArray *actionSequences = [action nodesForXPath:@".//actionsequence" error:&xmlError];
        if([actionSequences count] == 1) { // Only support a single action for now
            DDXMLNode *actionSequence = [actionSequences objectAtIndex:0];
            NSArray *actionNodes = [actionSequence children];
            if([actionNodes count] >= 1) {
                DDXMLNode *actionNode = [actionNodes objectAtIndex:0];
                // Check if any of the actions can handle th
                for(actionUI in [actionNamesToSJActionUIDict allValues]) {
                    if([actionUI setAction:actionNode]) {
                        // This action UI can handle this action
                        initialActionName = [[actionUI class] name];
                        break;
                    }
                }
            }
        }
    }
    // If our initial action isn't supported, support it
    if(![availableActions containsObject:initialActionName])
        [availableActions addObject:initialActionName];
    [actionPicker reloadComponent:1];
    // Initialize the action picker
    int actionIndex = [availableActions indexOfObject:initialActionName];
    [actionPicker selectRow:actionIndex inComponent:1 animated:NO];
    [self pickerView:actionPicker didSelectRow:actionIndex inComponent:1];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return NO;
}

-(void) onCancel:(id)sender {
    // Dismiss
    [[self delegate] SJUIDefineActionViewControllerReadyForDismissal:self];
}

-(void) onDone:(id)sender {
    // Update the action
    NSMutableString *xmlString = [NSMutableString stringWithCapacity:500];
    [xmlString setString:@"<actionsequenceondevice>"];
    [xmlString appendString:@"<friendlyname>"];
    [xmlString appendString:[self pickerView:actionPicker titleForRow:[actionPicker selectedRowInComponent:0] forComponent:0]];
    [xmlString appendString:@"</friendlyname>"];
    [xmlString appendString:@"<actionsequence>"];
    NSString *actionName = [self pickerView:actionPicker titleForRow:[actionPicker selectedRowInComponent:1] forComponent:1];
    SJActionUI *actionUI = [actionNamesToSJActionUIDict objectForKey:actionName];
    NSString *actionStringFromUI = [actionUI XMLStringForAction];
    if(actionStringFromUI)
        [xmlString appendString:actionStringFromUI];
    [xmlString appendString:@"</actionsequence>"];
    [xmlString appendString:@"</actionsequenceondevice>"];
    NSError *xmlError;
    DDXMLDocument *action = [[DDXMLDocument alloc] initWithXMLString:xmlString options:0 error:&xmlError];
    if(action == nil) {
        NSLog(@"Failed to create action XML. Error = %@. String = %@.\n", xmlError, xmlString);
        return;
    }
    DDXMLNode *actionNode = [[action children] objectAtIndex:0];
    [[self actions] removeAllObjects];
    [[self actions] addObject:actionNode];
    // Dismiss
    [[self delegate] SJUIDefineActionViewControllerReadyForDismissal:self];
}


-(SwitchamajigDriver*) getCurrentlySelectedDriver {
    SwitchamajigDriver *driver;
    NSString *friendlyName = [self pickerView:actionPicker titleForRow:[actionPicker selectedRowInComponent:0] forComponent:0];
    if([friendlyName isEqualToString:@"Default"]) {
        if(![[[self appDelegate] friendlyNameSwitchamajigDictionary] count])
            return nil; // No driver available
        friendlyName = [[[[self appDelegate] friendlyNameSwitchamajigDictionary] allKeys] objectAtIndex:0];
    }
    driver = [[[self appDelegate] friendlyNameSwitchamajigDictionary] objectForKey:friendlyName];
    return driver;
}


// UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    if(pickerView == actionPicker)
        return 2;
    NSLog(@"defineActionViewController: numberOfComponentsInPickerView: PickerView unrecognized.");
    return 0;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(pickerView == actionPicker) {
        if(component == 0)
            return [friendlyNamesArray count];
        return [availableActions count];
    }
    NSLog(@"defineActionViewController: pickerView numberOfRowsInComponent: PickerView unrecognized.");
    return 0;
}

// UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if(pickerView == actionPicker) {
        if(component == 0) {
            // Inform the action UIs that the driver may have changed
            SJActionUI *actionUI;
            for(actionUI in [actionNamesToSJActionUIDict allValues]) {
                [actionUI driverSelectionDidChange];
            }
        }
        if(component == 1) {
            // Hide all the action UIs
            SJActionUI *actionUI;
            for(actionUI in [actionNamesToSJActionUIDict allValues]) {
                [actionUI setHidden:YES];
            }
            // Make the selected UI visible
            NSString *actionName = [self pickerView:actionPicker titleForRow:row forComponent:component];
            [[actionNamesToSJActionUIDict objectForKey:actionName] setHidden:NO];
        }
        return;
    } 
    NSLog(@"defineActionViewController: pickerView didSelectRow: PickerView unrecognized.");
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if(pickerView == actionPicker) {
        if(component == 0) {
            // Friendly names
            return [friendlyNamesArray objectAtIndex:row];
        }
        if(component == 1) {
            if(row >= [availableActions count]) {
                NSLog(@"Crashing bug: defineActionViewController: titleForRow: avaialbleActions out of bounds with row = %d, count = %d", row, [availableActions count]);
                return nil;
            }
            return [availableActions objectAtIndex:row];
       }
     }
    NSLog(@"defineActionViewController: pickerView titleForRow: PickerView unrecognized.");
    return nil;
}


- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    if(pickerView == actionPicker) {
        if(component == 0)
            return 300;
        return 250;
    }
   NSLog(@"defineActionViewController: pickerView widthForComponent: PickerView unrecognized.");
    return 0;
}


@end
