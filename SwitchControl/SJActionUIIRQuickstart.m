//
//  SJActionUIIRQuickstart.m
//  SwitchControl
//
//  Created by Phil Weaver on 9/19/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "SJActionUIIRQuickstart.h"

@implementation SJActionUIIRQuickstart
+ (NSString *) name {
    return @"Quickstart IR";
};

- (void) createUI {
    minimalFunctionSet = [NSArray arrayWithObjects:@"POWER TOGGLE", @"POWER ON/OFF", @"PLAY", @"PAUSE", @"STOP", @"NEXT", @"PREVIOUS", @"FORWARD", @"REVERSE", @"OPEN CLOSE", @"PLAY PAUSE", @"SELECT", @"ENTER", @"OPEN", @"CANCEL", @"VOLUME UP", @"VOLUME DOWN", @"CHANNEL UP", @"CHANNEL DOWN", @"PREVIOUS CHANNEL", @"EJECT", @"HOME", @"OPEN/CLOSE", @"PLAY/PAUSE", nil];
    NSArray *deviceGroups = [NSArray arrayWithObjects:@"TV", @"DVD/Blu Ray", @"Cable/Satellite", nil];

    deviceTypesToFunctionsDictionary = [[NSMutableDictionary alloc] initWithCapacity:10];
    NSString *deviceGroup;
    for (deviceGroup in deviceGroups) {
        NSString *brand = [[[self defineActionVC] appDelegate] getIRBrandForDeviceGroup:deviceGroup];
        NSString *device = [[[self defineActionVC] appDelegate] getIRDeviceForDeviceGroup:deviceGroup];
        NSString *codeSet = [[[self defineActionVC] appDelegate] getIRCodeSetForDeviceGroup:deviceGroup];
        NSMutableArray *functionsForThisDeviceGroup = [[NSMutableArray alloc] initWithCapacity:75];
        if(brand && device && codeSet) {
            // If we have a valid quick-start, use the functions for it
            NSArray *functionsForQuickStart = [SwitchamajigIRDeviceDriver getIRDatabaseFunctionsInCodeSet:codeSet onDevice:device forBrand:brand];
            [functionsForThisDeviceGroup addObjectsFromArray:functionsForQuickStart];
        } else {
            // If this device isn't configured, use the minimal function set
            [functionsForThisDeviceGroup addObjectsFromArray:minimalFunctionSet];
        }
        [deviceTypesToFunctionsDictionary setValue:functionsForThisDeviceGroup forKey:deviceGroup];
    }
    
    filterFunctionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [filterFunctionButton setFrame:CGRectMake(575, 462, 200, 44)];
    [filterFunctionButton setTitle:@"Show More Functions" forState:UIControlStateNormal];
    [filterFunctionButton addTarget:self action:@selector(filterFunctionToggle:) forControlEvents:UIControlEventTouchUpInside];
    [filterFunctionButton setHidden:YES];
    [[[self defineActionVC] view] addSubview:filterFunctionButton];
    
    irPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 300, 800, 162)];
    [irPicker setDelegate:self];
    [irPicker setDataSource:self];
    [irPicker setShowsSelectionIndicator:YES];
    [irPicker setHidden:YES];
    [[[self defineActionVC] view] addSubview:irPicker];
    // Initialize the picker
    [irPicker selectRow:0 inComponent:0 animated:NO];
    [self pickerView:irPicker didSelectRow:0 inComponent:0];
    
    irPickerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 250, 800, 44)];
    [irPickerLabel setBackgroundColor:[UIColor blackColor]];
    [irPickerLabel setTextColor:[UIColor whiteColor]];
    [irPickerLabel setText:@"Device                         Function"];
    [irPickerLabel setTextAlignment:UITextAlignmentCenter];
    [irPickerLabel setFont:[UIFont systemFontOfSize:20]];
    [irPickerLabel setHidden:YES];
    [[[self defineActionVC] view] addSubview:irPickerLabel];
    
    testIrButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [testIrButton setFrame:CGRectMake(250, 500, 300, 44)];
    [testIrButton setTitle:@"Test Command" forState:UIControlStateNormal];
    [testIrButton addTarget:self action:@selector(testIRCommand:) forControlEvents:UIControlEventTouchUpInside];
    [testIrButton setHidden:YES];
    [[[self defineActionVC] view] addSubview:testIrButton];
}

- (void) driverSelectionDidChange{
    BOOL uiIsHidden = [irPicker isHidden];
    [testIrButton setHidden:uiIsHidden];
    [[[[self defineActionVC] appDelegate] statusInfoLock] lock];
    SwitchamajigDriver *driver = [[self defineActionVC] getCurrentlySelectedDriver];
    if(![driver isKindOfClass:[SwitchamajigIRDeviceDriver class]]) {
        [testIrButton setHidden:YES];
    }
    [[[[self defineActionVC] appDelegate] statusInfoLock] unlock];
};

- (void) setHidden:(BOOL)hidden{
    [irPicker setHidden:hidden];
    [irPickerLabel setHidden:hidden];
    [filterFunctionButton setHidden:hidden];
    // Check the driver to see if we need to display the test IR button
    [self driverSelectionDidChange];
};
- (NSString*) XMLStringForAction{
    NSString *deviceType = [self getCurrentDeviceType];
    NSString *function = [self getCurrentFunction];
    NSString *irXmlCommand = [NSString stringWithFormat:@"<quickIRCommand><deviceType>%@</deviceType><function>%@</function></quickIRCommand>", deviceType, function];
    NSLog(@"quickIrCommand = %@", irXmlCommand);
    return irXmlCommand;
};

- (BOOL) setAction:(DDXMLNode*)action {
    if(![[action name] isEqualToString:@"quickIRCommand"])
        return NO;
    DDXMLElement *actionElement = (DDXMLElement *)action;
    NSError *xmlError;
    NSArray *deviceTypeNodes = [actionElement nodesForXPath:@"deviceType" error:&xmlError];
    if([deviceTypeNodes count] != 1)
        return NO;
    NSString *deviceType = [[deviceTypeNodes objectAtIndex:0] stringValue];
    int deviceTypeIndex = [[deviceTypesToFunctionsDictionary allKeys] indexOfObject:deviceType];
    if(deviceTypeIndex == NSNotFound)
        return NO;
    NSArray *functionNodes = [actionElement nodesForXPath:@"function" error:&xmlError];
    if([functionNodes count] == 0)
        return NO;
    [irPicker selectRow:deviceTypeIndex inComponent:0 animated:NO];
    [self pickerView:irPicker didSelectRow:deviceTypeIndex inComponent:0];
    
    // It's possible that there will be more than one function. Look for one in the picker list
    NSMutableArray *functionsInList = [deviceTypesToFunctionsDictionary objectForKey:deviceType];
    DDXMLNode *functionNode;
    int functionIndex;
    for(functionNode in functionNodes) {
        NSString *functionName = [functionNode stringValue];
        functionIndex = [functionsInList indexOfObject:functionName];
        if(functionIndex != NSNotFound)
            break; // Found it
    }
    // If none of the functions are in the list, add it
    if(functionIndex == NSNotFound) {
        NSString *functionName = [[functionNodes objectAtIndex:0] stringValue];
        [functionsInList addObject:functionName];
        functionIndex = [functionsInList indexOfObject:functionName];
    }
    [irPicker selectRow:functionIndex inComponent:1 animated:NO];
    [self pickerView:irPicker didSelectRow:functionIndex inComponent:0];
    return YES;
};

- (NSArray *) filterFunctions:(NSArray *) bigListOfFunctions {
    NSMutableArray *filteredFunctions = [[NSMutableArray alloc] initWithCapacity:10];
    NSString *function;
    for(function in bigListOfFunctions) {
        if([minimalFunctionSet containsObject:function])
            [filteredFunctions addObject:function];
    }
    // If we've overfiltered, just leave the big list alone
    if([filteredFunctions count])
        return filteredFunctions;
    return bigListOfFunctions;
}

- (void) filterFunctionToggle:(id)sender {
    NSString *function = [[self getCurrentFunction] capitalizedString];
    NSString *currentTitle = [filterFunctionButton titleForState:UIControlStateNormal];
    if([currentTitle isEqualToString:@"Show More Functions"]) {
        [filterFunctionButton setTitle:@"Show Fewer Functions" forState:UIControlStateNormal];
    } else {
        [filterFunctionButton setTitle:@"Show More Functions" forState:UIControlStateNormal];
    }
    [irPicker reloadComponent:1];
    // Look for title in picker
    int functionIndex = 0;
    for(int i=0; i < [self pickerView:irPicker numberOfRowsInComponent:1]; ++i) {
        if([function isEqualToString:[self pickerView:irPicker titleForRow:i forComponent:1]]) {
            functionIndex = i;
            break;
        }
    }
    [irPicker selectRow:functionIndex inComponent:1 animated:NO];
    [self pickerView:irPicker didSelectRow:functionIndex inComponent:1];
}

-(NSString *) getCurrentDeviceType {
    int deviceTypeIndex = [irPicker selectedRowInComponent:0];
    if([deviceTypesToFunctionsDictionary count] <= deviceTypeIndex) {
        NSLog(@"getCurrentFunction: Crashing bug: deviceTypeIndex out of bounds.");
        return nil;
    }
    return [[deviceTypesToFunctionsDictionary allKeys] objectAtIndex:deviceTypeIndex];
}

-(NSString *) getCurrentFunction {
    NSString *currentFunctionTitle =  [self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:1] forComponent:1];
    NSString *command = [currentFunctionTitle uppercaseString];
    return command;
}

-(void) testIRCommand:(id)sender {
    NSString *deviceType = [self getCurrentDeviceType];
    NSString *function = [self getCurrentFunction];
    NSString *brand = [[[self defineActionVC] appDelegate] getIRBrandForDeviceGroup:deviceType];
    NSString *codeSet = [[[self defineActionVC] appDelegate] getIRCodeSetForDeviceGroup:deviceType];
    NSString *device = [[[self defineActionVC] appDelegate] getIRDeviceForDeviceGroup:deviceType];
    if(brand && codeSet && device) {
        NSString *irCommand = [SwitchamajigIRDeviceDriver irCodeForFunction:function inCodeSet:codeSet onDevice:device forBrand:brand];
        NSLog(@"%@:%@:%@:%@  --  irCommand = %@", brand, device, codeSet, function, irCommand);
        if(irCommand) {
            // Wrap the command up as xml
            NSString *irXmlCommand = [NSString stringWithFormat:@"<docommand key=\"0\" repeat=\"n\" seq=\"n\" command=\"0\" ir_data=\"%@\" ch=\"0\"></docommand>", irCommand];
            NSError *xmlError;
            DDXMLDocument *action = [[DDXMLDocument alloc] initWithXMLString:irXmlCommand options:0 error:&xmlError];
            if(action == nil) {
                NSLog(@"testIRCommand: Failed to create action XML. Error = %@. String = %@.\n", xmlError, irXmlCommand);
                return;
            }
            DDXMLNode *actionNode = [[action children] objectAtIndex:0];
            [[[[self defineActionVC] appDelegate] statusInfoLock] lock];
            SwitchamajigDriver *driver = [[self defineActionVC] getCurrentlySelectedDriver];
            if(driver) {
                if([driver isKindOfClass:[SwitchamajigIRDeviceDriver class]]) {
                    NSError *error;
                    [driver issueCommandFromXMLNode:actionNode error:&error];
                }
            }
            [[[[self defineActionVC] appDelegate] statusInfoLock] unlock];
        }
    }
}


// UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    if(pickerView == irPicker)
        return 2;
    NSLog(@"SJActionUIIRQuickstart: numberOfComponentsInPickerView: PickerView unrecognized.");
    return 0;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(pickerView == irPicker) {
        if(component == 0)
            return [deviceTypesToFunctionsDictionary count];
        if(component == 1) {
            NSString *currentDeviceType = [self getCurrentDeviceType];
            NSArray *functionArray = [deviceTypesToFunctionsDictionary objectForKey:currentDeviceType];
            if([[filterFunctionButton titleForState:UIControlStateNormal] isEqualToString:@"Show More Functions"])
                functionArray = [self filterFunctions:functionArray];
            return [functionArray count];
        }
        return 0;
    }
    NSLog(@"SJActionUIIRQuickstart: pickerView numberOfRowsInComponent: PickerView unrecognized.");
    return 0;
}

// UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if(pickerView == irPicker) {
        if(component == 0) {
            [irPicker reloadComponent:1];
            [irPicker selectRow:0 inComponent:1 animated:NO];
            [self pickerView:irPicker didSelectRow:0 inComponent:1];
        } 
        return;
    }
    NSLog(@"SJActionUIIRQuickstart: pickerView didSelectRow: PickerView unrecognized.");
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if(pickerView == irPicker) {
        if(component == 0) {
            if([deviceTypesToFunctionsDictionary count]>row)
                return [[deviceTypesToFunctionsDictionary allKeys] objectAtIndex:row];
            NSLog(@"SJActionUIIRQuickstart: pickerView titleForRow out of bounds for brands");
            return nil;
        }
        if(component == 1) {
            NSString *currentDeviceType = [self getCurrentDeviceType];
            NSArray *functionArray = [deviceTypesToFunctionsDictionary objectForKey:currentDeviceType];
            if([[filterFunctionButton titleForState:UIControlStateNormal] isEqualToString:@"Show More Functions"])
                functionArray = [self filterFunctions:functionArray];
            if([functionArray count]>row)
                return [[functionArray objectAtIndex:row] capitalizedString];
            NSLog(@"SJActionUIIRQuickstart: pickerView titleForRow out of bounds for functions");
            return nil;
        }
        return nil;
    }
    NSLog(@"SJActionUIIRQuickstart: pickerView titleForRow: PickerView unrecognized.");
    return nil;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    if(pickerView == irPicker) {
        switch(component) {
            case 0: return 200;
            case 1: return 225;
        }
    }
    NSLog(@"SJActionUIIRQuickstart: pickerView widthForComponent: PickerView unrecognized.");
    return 0;
}

@end

