//
//  defineActionViewController.m
//  SwitchControl
//
//  Created by Phil Weaver on 7/25/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "defineActionViewController.h"
#import "../../KissXML/KissXML/DDXMLDocument.h"

@interface defineActionViewController ()
- (void) toggleSwitchButton:(id)sender;
@end

@implementation defineActionViewController
@synthesize actions;
@synthesize friendlyNames;

// There's probably a cleaner way, but here we are
#define NUM_ACTIONS 3
#define INDEX_FOR_TURNSWITCHESON 1
#define INDEX_FOR_TURNSWITCHESOFF 2
NSString *actionArray[NUM_ACTIONS] = {@"No Action", @"Turn Switches On", @"Turn Switches Off"};

- (id) initWithActions:(NSMutableArray *)actionsInit andFriendlyNames:(NSArray *)friendlyNamesInit {
    self = [super init];
    if(self != nil) {
        [self setActions:actionsInit];
        [self setFriendlyNames:[[NSMutableArray alloc] initWithCapacity:5]];
        [[self friendlyNames] setArray:friendlyNamesInit];
    }
    return self;
}

- (void)loadView {
    CGRect cgRct = CGRectMake(0, 0, 470, 768);
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
    actionPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(50, 50, 370, 100)];
    [actionPicker setDelegate:self];
    [actionPicker setDataSource:self];
    [actionPicker setShowsSelectionIndicator:YES];
    [actionPicker selectRow:startingFriendlyNameIndex inComponent:0 animated:NO];
    [myView addSubview:actionPicker];
    
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
    return 2;
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
    if(component == 0)
        return [[self friendlyNames] count];
    return NUM_ACTIONS;
}

// UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if((row == 1) || (row == 2)) {
        // Display the switch number buttons
        for(int i=0; i < NUM_SJIG_SWITCHES; ++i)
        {
            [switchButtons[i] setHidden:NO];
        }
    } else {
        for(int i=0; i < NUM_SJIG_SWITCHES; ++i)
        {
            [switchButtons[i] setHidden:YES];
        }
    }
    [self updateActions];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if(component == 0) {
        // Friendly names
        return [[self friendlyNames] objectAtIndex:row];
    }
    return actionArray[row];
}


- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    if(component == 0)
        return 150;
    return 200;
}

@end
