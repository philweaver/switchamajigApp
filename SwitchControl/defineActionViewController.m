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
- (NSString*) generateIrXmlCommand;
@end

@implementation defineActionViewController
@synthesize actions;
NSArray *filterBrands(NSArray *bigListOfBrands);

// There's probably a cleaner way, but here we are
#define NUM_ACTIONS 4
#define INDEX_FOR_TURNSWITCHESON 1
#define INDEX_FOR_TURNSWITCHESOFF 2
#define INDEX_FOR_IRCOMMAND 3
NSString *actionArray[NUM_ACTIONS] = {@"No Action", @"Turn Switches On", @"Turn Switches Off", @"IR Command"};

- (id) initWithActions:(NSMutableArray *)actionsInit appDelegate:(SwitchControlAppDelegate *)appDelegate {
    self = [super init];
    if(self != nil) {
        [self setActions:actionsInit];
        [self setAppDelegate:appDelegate];
        [self setContentSizeForViewInPopover:CGSizeMake(800, 600)];
        [[appDelegate statusInfoLock] lock];
        friendlyNamesArray = [[NSMutableArray alloc] initWithArray:[[appDelegate friendlyNameSwitchamajigDictionary] allKeys]];
        [[appDelegate statusInfoLock] unlock];
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
    brands = filterBrands([SwitchamajigIRDeviceDriver getIRDatabaseBrands]);
    irPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 250, 800, 100)];
    [irPicker setDelegate:self];
    [irPicker setDataSource:self];
    [irPicker setShowsSelectionIndicator:YES];
    [irPicker selectRow:0 inComponent:0 animated:NO];
    [self pickerView:irPicker didSelectRow:0 inComponent:0];
    [irPicker setHidden:YES];
    [myView addSubview:irPicker];
    filterBrandButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [filterBrandButton setFrame:CGRectMake(50, 450, 150, 44)];
    [filterBrandButton setTitle:@"Show More Brands" forState:UIControlStateNormal];
    [filterBrandButton addTarget:self action:@selector(filterBrandToggle:) forControlEvents:UIControlEventTouchUpInside];
    [filterBrandButton setHidden:YES];
    [myView addSubview:filterBrandButton];
    

    testIrButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [testIrButton setFrame:CGRectMake(250, 500, 100, 44)];
    [testIrButton setTitle:@"Test Command" forState:UIControlStateNormal];
    [testIrButton addTarget:self action:@selector(testIRCommand:) forControlEvents:UIControlEventTouchUpInside];
    [testIrButton setHidden:YES];
    [myView addSubview:testIrButton];

    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(50, 10, 150, 44)];
    [label setBackgroundColor:[UIColor blackColor]];
    [label setTextColor:[UIColor whiteColor]];
    [label setText:@"Choose Device"];
    [label setTextAlignment:UITextAlignmentCenter];
    [label setFont:[UIFont systemFontOfSize:20]];
    [myView addSubview:label];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(200, 10, 200, 44)];
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

- (void) filterBrandToggle:(id)sender {
    NSString *currentBrand = [self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:0] forComponent:0];
    if([[filterBrandButton titleForState:UIControlStateNormal] isEqualToString:@"Show More Brands"]) {
        [filterBrandButton setTitle:@"Show Fewer Brands" forState:UIControlStateNormal];
        brands = [SwitchamajigIRDeviceDriver getIRDatabaseBrands];
    } else {
        [filterBrandButton setTitle:@"Show More Brands" forState:UIControlStateNormal];
        brands = filterBrands([SwitchamajigIRDeviceDriver getIRDatabaseBrands]);
    }
    int brandIndex = [brands indexOfObject:currentBrand];
    [irPicker reloadComponent:0];
    [irPicker selectRow:brandIndex inComponent:0 animated:NO];
}

-(void) testIRCommand:(id)sender {
    NSString *irXmlCommand = [self generateIrXmlCommand];
    NSError *xmlError;
    DDXMLDocument *action = [[DDXMLDocument alloc] initWithXMLString:irXmlCommand options:0 error:&xmlError];
    if(action == nil) {
        NSLog(@"testIRCommand: Failed to create action XML. Error = %@. String = %@.\n", xmlError, irXmlCommand);
        return;
    }
    DDXMLNode *actionNode = [[action children] objectAtIndex:0];
    NSString *friendlyName = [self pickerView:actionPicker titleForRow:[actionPicker selectedRowInComponent:0] forComponent:0];
    [[[self appDelegate] statusInfoLock] lock];
    SwitchamajigDriver *driver = [[[self appDelegate] friendlyNameSwitchamajigDictionary] objectForKey:friendlyName];
    if(driver) {
        if([driver isKindOfClass:[SwitchamajigIRDeviceDriver class]]) {
            NSError *error;
            [driver issueCommandFromXMLNode:actionNode error:&error];
        }
    }
    [[[self appDelegate] statusInfoLock] unlock];
}

- (NSString*) generateIrXmlCommand {
    NSString *brand = [self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:0] forComponent:0];
    NSString *device = [self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:1] forComponent:1];
    NSString *function = [self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:2] forComponent:2];
    if(!irCommands || ![irCommands count]) {
        NSLog(@"defineActionViewController: generateIrXmlCommand: irCommands is either nil or has 0 elements");
        return nil;
    }
    int commandIndex;
    if([irCommands count] == 1)
        commandIndex = 0;
    else {
        commandIndex = [irPicker selectedRowInComponent:3];
        if(commandIndex >= [irCommands count]) {
            NSLog(@"defineActionViewController: generateIrXmlCommand: commandIndex out of bounds [bug!]");
            commandIndex = 0;
        }
    }
    NSString *irCommand = [irCommands objectAtIndex:commandIndex];
    NSString *irXmlCommand = [NSString stringWithFormat:@"<docommand key=\"0\" repeat=\"n\" seq=\"n\" command=\"%@:%@:%@:%d\" ir_data=\"%@\" ch=\"0\"></docommand>", brand, device, function, commandIndex, irCommand];
    return irXmlCommand;
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
        NSString *irXmlCommand = [self generateIrXmlCommand];
        [xmlString appendString:irXmlCommand];
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

// UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    if(pickerView == actionPicker)
        return 2;
    if(pickerView == irPicker)
        return 4;
    NSLog(@"defineActionViewController: numberOfComponentsInPickerView: PickerView unrecognized.");
    return 0;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(pickerView == actionPicker) {
        if(component == 0)
            return [friendlyNamesArray count];
        return NUM_ACTIONS;
    }
    if(pickerView == irPicker) {
        if(component == 0)
            return [brands count];
        if(component == 1)
            return [devices count];
        if(component == 2)
            return [functions count];
        if(component == 3)
            return [irCommands count];
        return 0;
    }
    NSLog(@"defineActionViewController: pickerView numberOfRowsInComponent: PickerView unrecognized.");
    return 0;
}

// UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if(pickerView == actionPicker) {
        if(component == 0) {
            // Show testIR button if the current driver can handle it and we are already showing IR options.
            [testIrButton setHidden:YES];
            NSString *friendlyName = [self pickerView:pickerView titleForRow:row forComponent:0];
            [[[self appDelegate] statusInfoLock] lock];
            SwitchamajigDriver *driver = [[[self appDelegate] friendlyNameSwitchamajigDictionary] objectForKey:friendlyName];
            if(driver) {
                if([driver isKindOfClass:[SwitchamajigIRDeviceDriver class]]) {
                    if([[self pickerView:actionPicker titleForRow:[actionPicker selectedRowInComponent:1] forComponent:1] isEqualToString:actionArray[INDEX_FOR_IRCOMMAND]])
                        [testIrButton setHidden:NO];
                }
            }
            [[[self appDelegate] statusInfoLock] unlock];
        }
        if(component == 1) {
            // Hide everything
            for(int i=0; i < NUM_SJIG_SWITCHES; ++i)
                [switchButtons[i] setHidden:YES];
            [irPicker setHidden:YES];
            [filterBrandButton setHidden:YES];
            switch (row) {
                case INDEX_FOR_TURNSWITCHESON:
                case INDEX_FOR_TURNSWITCHESOFF:
                    for(int i=0; i < NUM_SJIG_SWITCHES; ++i)
                        [switchButtons[i] setHidden:NO];
                    break;
                case INDEX_FOR_IRCOMMAND:
                    [irPicker setHidden:NO];
                    [filterBrandButton setHidden:NO];
                    NSString *friendlyName = [self pickerView:pickerView titleForRow:[actionPicker selectedRowInComponent:0] forComponent:0];
                    [[[self appDelegate] statusInfoLock] lock];
                    SwitchamajigDriver *driver = [[[self appDelegate] friendlyNameSwitchamajigDictionary] objectForKey:friendlyName];
                    if(driver) {
                        if([driver isKindOfClass:[SwitchamajigIRDeviceDriver class]]) {
                            [testIrButton setHidden:NO];
                        }
                    }
                    [[[self appDelegate] statusInfoLock] unlock];
           }
        }
        [self updateActions];
        return;
    } else if(pickerView == irPicker) {
        if(component == 0) {
            devices = [SwitchamajigIRDeviceDriver getIRDatabaseDevicesForBrand:[self pickerView:irPicker titleForRow:row forComponent:0]];
            [irPicker reloadComponent:1];
            [irPicker selectRow:0 inComponent:1 animated:NO];
            [self pickerView:irPicker didSelectRow:0 inComponent:1];
        } else if(component == 1) {
            functions = [SwitchamajigIRDeviceDriver getIRDatabaseFunctionsOnDevice:[self pickerView:irPicker titleForRow:row forComponent:1] forBrand:[self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:0] forComponent:0]];
            [irPicker reloadComponent:2];
            [irPicker selectRow:0 inComponent:2 animated:NO];
            [self pickerView:irPicker didSelectRow:0 inComponent:2];
        } else if(component == 2) {
            irCommands = [SwitchamajigIRDeviceDriver irCodesForFunction:[self pickerView:irPicker titleForRow:row forComponent:2] onDevice:[self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:1] forComponent:1] forBrand:[self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:0] forComponent:0]];
            [irPicker reloadComponent:3];
            [irPicker selectRow:0 inComponent:3 animated:NO];
            [self pickerView:irPicker didSelectRow:0 inComponent:3];
        } if(component == 3) {
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
            return [friendlyNamesArray objectAtIndex:row];
        }
        return actionArray[row];
    }
    if(pickerView == irPicker) {
        if(component == 0) {
            if([brands count]>row)
                return [brands objectAtIndex:row];
            NSLog(@"defineActionViewController: pickerView titleForRow out of bounds for brands");
            return nil;
        }
        if(component == 1) {
            if([devices count]>row)
                return [devices objectAtIndex:row];
            NSLog(@"defineActionViewController: pickerView titleForRow out of bounds for devices");
            return nil;
        }
        if(component == 2) {
            if([functions count]>row)
                return [functions objectAtIndex:row];
            NSLog(@"defineActionViewController: pickerView titleForRow out of bounds for functions");
            return nil;
        }
        if(component == 3)
            return [NSString stringWithFormat:@"%d", row+1];
        return nil;
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
    if(pickerView == irPicker) {
        if(component == 3)
            return 50;
        return 250;
    }
    NSLog(@"defineActionViewController: pickerView widthForComponent: PickerView unrecognized.");
    return 0;
}

NSArray *filterBrands(NSArray *bigListOfBrands) {
    NSMutableArray *filteredBrands = [[NSMutableArray alloc] initWithCapacity:10];
    NSString *brand;
    for(brand in bigListOfBrands) {
        if([brand isEqualToString:@"Panasonic"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Sony"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Samsung"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Philips"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Tivo"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Time Warner"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Comcast"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Sharp"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Sanyo"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Scientific Atlanta"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Roku"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"RCA"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Motorola"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"DirecTV"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Dish"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Coby"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"LG"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Kenwood"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Pioneer"]) [filteredBrands addObject:brand];
        if([brand isEqualToString:@"Apple"]) [filteredBrands addObject:brand];
    }
    return filteredBrands;
}
@end
