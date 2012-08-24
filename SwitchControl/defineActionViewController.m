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
@interface defineActionViewController ()
- (void) toggleSwitchButton:(id)sender;
@end

@implementation defineActionViewController
@synthesize actions;
@synthesize friendlyNames;

// There's probably a cleaner way, but here we are
#define NUM_ACTIONS 4
#define INDEX_FOR_TURNSWITCHESON 1
#define INDEX_FOR_TURNSWITCHESOFF 2
#define INDEX_FOR_IRCOMMAND 3
NSString *actionArray[NUM_ACTIONS] = {@"No Action", @"Turn Switches On", @"Turn Switches Off", @"IR Command"};

- (id) initWithActions:(NSMutableArray *)actionsInit andFriendlyNames:(NSArray *)friendlyNamesInit {
    self = [super init];
    if(self != nil) {
        [self setActions:actionsInit];
        [self setFriendlyNames:[[NSMutableArray alloc] initWithCapacity:5]];
        [[self friendlyNames] setArray:friendlyNamesInit];
        [self setContentSizeForViewInPopover:CGSizeMake(600, 600)];
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
    if(![[self friendlyNames] containsObject:@"Default"])
        [[self friendlyNames] insertObject:@"Default" atIndex:0];
    NSError *xmlError;
    DDXMLNode *action;
    for(action in [self actions]) {
        NSArray *friendlyNamesDDXML = [action nodesForXPath:@".//friendlyname" error:&xmlError];
        DDXMLNode *friendlyNameNode;
        for(friendlyNameNode in friendlyNamesDDXML) {
            NSString *friendlyName = [friendlyNameNode stringValue];
            NSInteger indexOfNameNode = [[self friendlyNames] indexOfObject:friendlyName];
            if(indexOfNameNode == NSNotFound) {
                [[self friendlyNames] insertObject:friendlyName atIndex:1];
                startingFriendlyNameIndex = 1;
            } else {
                startingFriendlyNameIndex = indexOfNameNode;
            }
        }
    }

    // Initialize Picker
    actionPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 50, 600, 100)];
    [actionPicker setDelegate:self];
    [actionPicker setDataSource:self];
    [actionPicker setShowsSelectionIndicator:YES];
    [actionPicker selectRow:startingFriendlyNameIndex inComponent:0 animated:NO];
    [myView addSubview:actionPicker];
    
    // Switches for turn switches on/off
    int x = 55, y = 225;
    for(int i=0; i < NUM_SJIG_SWITCHES; ++i) {
        switchButtons[i] = [UIButton buttonWithType:UIButtonTypeCustom];
        [switchButtons[i] setFrame:CGRectMake(x, y, 50, 50)];
        x += 60;
        [switchButtons[i] setBackgroundColor:[UIColor grayColor]];
        [switchButtons[i] setTitle:[NSString stringWithFormat:@"%d", (i+1)] forState:UIControlStateNormal];
        [switchButtons[i] setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [switchButtons[i] addTarget:self action:@selector(toggleSwitchButton:) forControlEvents:UIControlEventTouchUpInside];
        [switchButtons[i] setHidden:YES];
        [myView addSubview:switchButtons[i]];
    }
    // IR command chooser
    brands = [SwitchamajigIRDeviceDriver getIRDatabaseBrands];
    irPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 250, 600, 100)];
    [irPicker setDelegate:self];
    [irPicker setDataSource:self];
    [irPicker setShowsSelectionIndicator:YES];
    [irPicker selectRow:0 inComponent:0 animated:NO];
    [irPicker setHidden:YES];
    [myView addSubview:irPicker];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 10, 150, 44)];
    [label setBackgroundColor:[UIColor blackColor]];
    [label setTextColor:[UIColor whiteColor]];
    [label setText:@"Choose Device"];
    [label setTextAlignment:UITextAlignmentCenter];
    [label setFont:[UIFont systemFontOfSize:20]];
    [myView addSubview:label];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(225, 10, 150, 44)];
    [label setBackgroundColor:[UIColor blackColor]];
    [label setTextColor:[UIColor whiteColor]];
    [label setText:@"Choose Action"];
    [label setTextAlignment:UITextAlignmentCenter];
    [label setFont:[UIFont systemFontOfSize:20]];
    [myView addSubview:label];
    // Determine initial action
    if([[self actions] count] == 1) { // Only support a single action for now
        action = [[self actions] objectAtIndex:0];
        NSArray *actionSequences = [action nodesForXPath:@".//actionsequence" error:&xmlError];
        if([actionSequences count] == 1) { // Only support a single action for now
            DDXMLNode *actionSequence = [actionSequences objectAtIndex:0];
            int numUnsupportedThings = [[actionSequence nodesForXPath:@".//actionname" error:&xmlError] count];
            numUnsupportedThings += [[actionSequence nodesForXPath:@".//loop" error:&xmlError] count];
            numUnsupportedThings += [[actionSequence nodesForXPath:@".//delay" error:&xmlError] count];
            numUnsupportedThings += [[actionSequence nodesForXPath:@".//stopactionwithname" error:&xmlError] count];
            // Don't support unsupported actions
            if(numUnsupportedThings) {
                NSLog(@"Unsupported things in action sequence. Initializing configured action to 'No Action'");
            } else {
                NSArray *turnSwitchesOnCommands = [actionSequence nodesForXPath:@".//turnSwitchesOn" error:&xmlError];
                NSArray *turnSwitchesOffCommands = [actionSequence nodesForXPath:@".//turnSwitchesOff" error:&xmlError];
                if([turnSwitchesOnCommands count] + [turnSwitchesOffCommands count] != 1) {
                    NSLog(@"Don't have exactly one action in sequence. Initializing configured action to 'No Action'");
                } else {
                    DDXMLNode *switchCommandNode;
                    if([turnSwitchesOnCommands count]) {
                        switchCommandNode = [turnSwitchesOnCommands objectAtIndex:0];
                        [actionPicker selectRow:INDEX_FOR_TURNSWITCHESON inComponent:1 animated:NO];
                    } else {
                        switchCommandNode = [turnSwitchesOffCommands objectAtIndex:0];
                        [actionPicker selectRow:INDEX_FOR_TURNSWITCHESOFF inComponent:1 animated:NO];
                    }
                    // Set up the buttons to match the command
                    NSScanner *switchScan = [[NSScanner alloc] initWithString:[switchCommandNode stringValue]];
                    int switchNumber;
                    while([switchScan scanInt:&switchNumber]) {
                        if((switchNumber > 0) && (switchNumber <= NUM_SJIG_SWITCHES)) {
                            [switchButtons[switchNumber-1] setBackgroundColor:[UIColor redColor]];
                        }
                    }
                    // Make buttons visible
                    for(int i=0; i < NUM_SJIG_SWITCHES; ++i)
                    {
                        [switchButtons[i] setHidden:NO];
                    }
                } // Only one command
            } // Nothing unsupported
        } // Only one action in sequence
    } // Only one action sequence
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

- (void) toggleSwitchButton:(id)sender {
    UIButton *button = sender;
    if([[button backgroundColor] isEqual:[UIColor grayColor]])
        [button setBackgroundColor:[UIColor redColor]];
    else {
        [button setBackgroundColor:[UIColor grayColor]];
    }
    [self updateActions];
}


// UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    if(pickerView == actionPicker)
        return 2;
    if(pickerView == irPicker)
        return 3;
    NSLog(@"defineActionViewController: numberOfComponentsInPickerView: PickerView unrecognized.");
    return 0;
}

- (void) updateActions {
    NSMutableString *xmlString = [NSMutableString stringWithCapacity:500];
    [xmlString setString:@"<actionsequenceondevice>"];
    [xmlString appendString:@"<friendlyname>"];
    [xmlString appendString:[self pickerView:actionPicker titleForRow:[actionPicker selectedRowInComponent:0] forComponent:0]];
    [xmlString appendString:@"</friendlyname>"];
    [xmlString appendString:@"<actionsequence>"];
    int actionIndex = [actionPicker selectedRowInComponent:1];
    if(actionIndex == INDEX_FOR_TURNSWITCHESON) {
        [xmlString appendString:@"<turnSwitchesOn>"];
        for(int i=0; i < NUM_SJIG_SWITCHES; ++i) {
            if([[switchButtons[i] backgroundColor] isEqual:[UIColor redColor]])
                [xmlString appendString:[NSString stringWithFormat:@"%d ", i+1]];
        }
        [xmlString appendString:@"</turnSwitchesOn>"];
    }
    if(actionIndex == INDEX_FOR_TURNSWITCHESOFF) {
        [xmlString appendString:@"<turnSwitchesOff>"];
        for(int i=0; i < NUM_SJIG_SWITCHES; ++i) {
            if([[switchButtons[i] backgroundColor] isEqual:[UIColor redColor]])
                [xmlString appendString:[NSString stringWithFormat:@"%d ", i+1]];
        }
        [xmlString appendString:@"</turnSwitchesOff>"];
    }
    if(actionIndex == INDEX_FOR_IRCOMMAND) {
        NSString *brand = [self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:0] forComponent:0];
        NSString *device = [self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:1] forComponent:1];
        NSString *function = [self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:2] forComponent:2];
        NSString *irCommand = [SwitchamajigIRDeviceDriver irCodeForFunction:function onDevice:device forBrand:brand];
        [xmlString appendString:[NSString stringWithFormat:@"<docommand key=\"0\" repeat=\"n\" seq=\"n\" command=\"%@:%@:%@\" ir_data=\"%@\" ch=\"0\"></docommand>", brand, device, function, irCommand]];
    }

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
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(pickerView == actionPicker) {
        if(component == 0)
            return [[self friendlyNames] count];
        return NUM_ACTIONS;
    }
    if(pickerView == irPicker) {
        if(component == 0)
            return [brands count];
        if(component == 1)
            return [devices count];
        if(component == 2)
            return [functions count];
        return 0;
    }
    NSLog(@"defineActionViewController: pickerView numberOfRowsInComponent: PickerView unrecognized.");
    return 0;
}

// UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if(pickerView == actionPicker) {
        if(component == 1) {
            // Hide everything
            for(int i=0; i < NUM_SJIG_SWITCHES; ++i)
                [switchButtons[i] setHidden:YES];
            [irPicker setHidden:YES];
            switch (row) {
                case 1:
                case 2:
                    for(int i=0; i < NUM_SJIG_SWITCHES; ++i)
                        [switchButtons[i] setHidden:YES];
                    break;
                case 3:
                    [irPicker setHidden:NO];
           }
        }
        [self updateActions];
    } else if(pickerView == irPicker){
        if(component == 0) {
            devices = [SwitchamajigIRDeviceDriver getIRDatabaseDevicesForBrand:[self pickerView:irPicker titleForRow:row forComponent:0]];
            [irPicker reloadComponent:1];
            [irPicker selectRow:0 inComponent:1 animated:NO];
        } else if(component == 1) {
            functions = [SwitchamajigIRDeviceDriver getIRDatabaseFunctionsOnDevice:[self pickerView:irPicker titleForRow:row forComponent:1] forBrand:[self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:0] forComponent:0]];
            [irPicker reloadComponent:2];
            [irPicker selectRow:0 inComponent:2 animated:NO];
        } if(component == 2) {
            [self updateActions];
        }
        return;
    }
    NSLog(@"defineActionViewController: pickerView didSelectRow: PickerView unrecognized.");
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if(pickerView == actionPicker) {
        if(component == 0) {
            // Friendly names
            return [[self friendlyNames] objectAtIndex:row];
        }
        return actionArray[row];
    }
    if(pickerView == irPicker) {
        if(component == 0)
            return [brands objectAtIndex:row];
        if(component == 1)
            return [devices objectAtIndex:row];
        if(component == 2)
            return [functions objectAtIndex:row];
        return nil;
    }
    NSLog(@"defineActionViewController: pickerView titleForRow: PickerView unrecognized.");
    return nil;
}


- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    if(pickerView == actionPicker) {
        return 250;
    }
    if(pickerView == irPicker) {
        return 160;
    }
    NSLog(@"defineActionViewController: pickerView widthForComponent: PickerView unrecognized.");
    return 0;
}

@end
