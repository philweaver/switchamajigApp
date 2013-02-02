//
//  SJActionUIIRDatabaseCommand.m
//  SwitchControl
//
//  Created by Phil Weaver on 8/31/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "SJActionUIIRDatabaseCommand.h"
#import "Flurry.h"

@implementation SJActionUIIRDatabaseCommand
static NSArray *filterBrands(NSArray *bigListOfBrands);
static NSArray *filterFunctions(NSArray *bigListOfFunctions);

+ (NSString *) name {
    return @"IR from Database";
};

- (void) createUI {
    if(![self defineActionVC])
        return;
    brands = filterBrands([SwitchamajigIRDeviceDriver getIRDatabaseBrands]);
    filterBrandButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [filterBrandButton setFrame:CGRectMake(25, 462, 200, 44)];
    [filterBrandButton setTitle:@"Show More Brands" forState:UIControlStateNormal];
    [filterBrandButton addTarget:self action:@selector(filterBrandToggle:) forControlEvents:UIControlEventTouchUpInside];
    [filterBrandButton setHidden:YES];
    [[[self defineActionVC] view] addSubview:filterBrandButton];
    
    filterFunctionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [filterFunctionButton setFrame:CGRectMake(575, 462, 200, 44)];
    [filterFunctionButton setTitle:@"Show More Functions" forState:UIControlStateNormal];
    [filterFunctionButton addTarget:self action:@selector(filterFunctionToggle:) forControlEvents:UIControlEventTouchUpInside];
    [filterFunctionButton setHidden:YES];
    [[[self defineActionVC] view] addSubview:filterFunctionButton];
    
    irPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 300, 900, 162)];
    [irPicker setDelegate:self];
    [irPicker setDataSource:self];
    [irPicker setShowsSelectionIndicator:YES];
    [irPicker setHidden:YES];
    [[[self defineActionVC] view] addSubview:irPicker];
    // Initialize the picker
    [irPicker selectRow:0 inComponent:0 animated:NO];
    [self pickerView:irPicker didSelectRow:0 inComponent:0];
    
    irPickerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 250, 900, 44)];
    [irPickerLabel setBackgroundColor:[UIColor blackColor]];
    [irPickerLabel setTextColor:[UIColor whiteColor]];
    [irPickerLabel setText:@"Brand                         Device                         Code Set                Function              Repeat"];
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
};

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
    [filterBrandButton setHidden:hidden];
    [filterFunctionButton setHidden:hidden];
    // Check the driver to see if we need to display the test IR button
    [self driverSelectionDidChange];
};

- (NSString*) XMLStringForAction{
    NSString *brand = [self getCurrentBrand];
    NSString *device = [self getCurrentDevice];
    NSString *codeset = [self getCurrentCodeSet];
    NSString *function = [self getCurrentFunction];
    NSString *irCommand = [SwitchamajigIRDeviceDriver irCodeForFunction:function inCodeSet:codeset onDevice:device forBrand:brand];
    NSString *irXmlCommand = [NSString stringWithFormat:@"<docommand key=\"0\" repeat=\"%d\" seq=\"0\" command=\"%@:%@:%@:%@\" ir_data=\"%@\" ch=\"0\"></docommand>", [irPicker selectedRowInComponent:4], brand, device, codeset, function, irCommand];
    NSLog(@"irCommand = %@", irCommand);
    NSDictionary *commandDict = [NSDictionary dictionaryWithObjectsAndKeys:@"brand", brand, @"device", device, @"function", function, nil];
    [Flurry logEvent:@"IR Database Command XMLStringForAction" withParameters:commandDict];
    return irXmlCommand;
};

- (BOOL) setAction:(DDXMLNode*)action {
    if(![[action name] isEqualToString:@"docommand"])
        return NO;
    DDXMLElement *actionElement = (DDXMLElement *)action;
    DDXMLNode *IRCommandNode = [actionElement attributeForName:@"command"];
    NSString *IRCommand = [IRCommandNode stringValue];
    NSArray *irCommandParts = [IRCommand componentsSeparatedByString:@":"];
    if([irCommandParts count] != 4)
        return NO;
    // Database command
    int brandIndex = [brands indexOfObject:[irCommandParts objectAtIndex:0]];
    if((brandIndex == NSNotFound) && ([[filterBrandButton titleForState:UIControlStateNormal] isEqualToString:@"Show More Brands"])) {
        // Un-filter the brands
        [filterBrandButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        brandIndex = [brands indexOfObject:[irCommandParts objectAtIndex:0]];
    }
    if(brandIndex == NSNotFound)
        return NO;
    [irPicker selectRow:brandIndex inComponent:0 animated:NO];
    [self pickerView:irPicker didSelectRow:brandIndex inComponent:0];
    int deviceIndex = [devices indexOfObject:[irCommandParts objectAtIndex:1]];
    if(deviceIndex == NSNotFound)
        return NO;
    [irPicker selectRow:deviceIndex inComponent:1 animated:NO];
    [self pickerView:irPicker didSelectRow:deviceIndex inComponent:1];
    int codeSetIndex = [codeSets indexOfObject:[irCommandParts objectAtIndex:2]];
    if(codeSetIndex == NSNotFound)
        return NO;
    [irPicker selectRow:codeSetIndex inComponent:2 animated:NO];
    [self pickerView:irPicker didSelectRow:codeSetIndex inComponent:2];
    int functionIndex = [functions indexOfObject:[irCommandParts objectAtIndex:3]];
    if((functionIndex == NSNotFound) && ([[filterFunctionButton titleForState:UIControlStateNormal] isEqualToString:@"Show More Functions"])) {
        // Un-filter the brands
        [filterFunctionButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        functionIndex = [functions indexOfObject:[irCommandParts objectAtIndex:3]];
    }
    if(functionIndex == NSNotFound)
        return NO;
    [irPicker selectRow:functionIndex inComponent:3 animated:NO];
    [self pickerView:irPicker didSelectRow:functionIndex inComponent:3];
    DDXMLNode *repeatNode = [actionElement attributeForName:@"repeat"];
    if(!repeatNode)
        return NO;
    NSString *repeatString = [repeatNode stringValue];
    if(!repeatString)
        return NO;
    NSScanner *repeatScan = [[NSScanner alloc] initWithString:repeatString];
    int repeatCount;
    if(![repeatScan scanInt:&repeatCount])
        repeatCount = 0;
    [irPicker selectRow:repeatCount inComponent:4 animated:NO];

    return YES;
};

static NSArray *filterBrands(NSArray *bigListOfBrands) {
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

static NSArray *filterFunctions(NSArray *bigListOfFunctions) {
    NSMutableArray *filteredFunctions = [[NSMutableArray alloc] initWithCapacity:10];
    NSString *function;
    for(function in bigListOfFunctions) {
        if([function isEqualToString:@"POWER TOGGLE"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"POWER ON/OFF"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"PLAY"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"PAUSE"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"STOP"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"NEXT"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"PREVIOUS"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"FORWARD"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"REVERSE"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"OPEN CLOSE"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"PLAY PAUSE"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"SELECT"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"ENTER"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"OPEN"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"CANCEL"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"VOLUME UP"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"VOLUME DOWN"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"CHANNEL UP"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"CHANNEL DOWN"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"PREVIOUS CHANNEL"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"EJECT"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"HOME"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"OPEN/CLOSE"]) [filteredFunctions addObject:function];
        if([function isEqualToString:@"PLAY/PAUSE"]) [filteredFunctions addObject:function];
    }
    // If we've overfiltered, just leave the big list alone
    if([filteredFunctions count])
        return filteredFunctions;
    return bigListOfFunctions;
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
    if(brandIndex == NSNotFound) {
        brandIndex = 0;
        [irPicker selectRow:brandIndex inComponent:0 animated:NO];
        [self pickerView:irPicker didSelectRow:brandIndex inComponent:0];
    } else {
        // No need to reload other components
        [irPicker selectRow:brandIndex inComponent:0 animated:NO];
    }
}

- (void) filterFunctionToggle:(id)sender {
    NSString *brand = [self getCurrentBrand];
    NSString *device = [self getCurrentDevice];
    NSString *codeSet = [self getCurrentCodeSet];
    NSString *function = [self getCurrentFunction];
    functions = [SwitchamajigIRDeviceDriver getIRDatabaseFunctionsInCodeSet:codeSet onDevice:device forBrand:brand];
    NSString *currentTitle = [filterFunctionButton titleForState:UIControlStateNormal];
    if([currentTitle isEqualToString:@"Show More Functions"]) {
        [filterFunctionButton setTitle:@"Show Fewer Functions" forState:UIControlStateNormal];
    } else {
        [filterFunctionButton setTitle:@"Show More Functions" forState:UIControlStateNormal];
        functions = filterFunctions(functions);
    }
    int functionIndex = [functions indexOfObject:function];
    if(functionIndex == NSNotFound)
        functionIndex = 0;
    [irPicker reloadComponent:3];
    [irPicker selectRow:functionIndex inComponent:3 animated:NO];
    [self pickerView:irPicker didSelectRow:functionIndex inComponent:3];
}

-(NSString *) getCurrentBrand {
    return [self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:0] forComponent:0];
}

-(NSString *) getCurrentDevice {
    return [self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:1] forComponent:1];
}

-(NSString *) getCurrentCodeSet {
    int codesetIndex = [irPicker selectedRowInComponent:2];
    if([codeSets count] <= codesetIndex) {
        NSLog(@"getCurrentCodeSet: Crashing bug: codeSetIndex out of bounds.");
        return nil;
    }
    return [codeSets objectAtIndex:codesetIndex];
}

-(NSString *) getCurrentFunction {
    int functionIndex = [irPicker selectedRowInComponent:3];
    if([functions count] <= functionIndex) {
        NSLog(@"getCurrentFunction: Crashing bug: functionIndex out of bounds.");
        return nil;
    }
    return [functions objectAtIndex:functionIndex];
}

-(void) testIRCommand:(id)sender {
    NSString *irXmlCommand = [self XMLStringForAction];
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

#define NUM_REPEAT_COUNT_STRINGS 10
static NSString *RepeatCountStrings[NUM_REPEAT_COUNT_STRINGS] = {
    @"Once", @"2x", @"3x", @"4x", @"5x", @"6x", @"7x", @"8x", @"9x", @"10x"
};

// UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    if(pickerView == irPicker)
        return 5;
    NSLog(@"SJActionUIIRDatabaseCommand: numberOfComponentsInPickerView: PickerView unrecognized.");
    return 0;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    if(pickerView == irPicker) {
        if(component == 0)
            return [brands count];
        if(component == 1)
            return [devices count];
        if(component == 2)
            return [codeSets count];
        if(component == 3)
            return [functions count];
        if(component == 4)
            return NUM_REPEAT_COUNT_STRINGS;
        return 0;
    }
    NSLog(@"SJActionUIIRDatabaseCommand: pickerView numberOfRowsInComponent: PickerView unrecognized.");
    return 0;
}

// UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if(pickerView == irPicker) {
        if(component == 0) {
            devices = [SwitchamajigIRDeviceDriver getIRDatabaseDevicesForBrand:[self pickerView:irPicker titleForRow:row forComponent:0]];
            [irPicker reloadComponent:1];
            [irPicker selectRow:0 inComponent:1 animated:NO];
            [self pickerView:irPicker didSelectRow:0 inComponent:1];
        } else if(component == 1) {
            codeSets = [SwitchamajigIRDeviceDriver getIRDatabaseCodeSetsOnDevice:[self pickerView:irPicker titleForRow:row forComponent:1] forBrand:[self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:0] forComponent:0]];
            [irPicker reloadComponent:2];
            [irPicker selectRow:0 inComponent:2 animated:NO];
            [self pickerView:irPicker didSelectRow:0 inComponent:2];
        } else if(component == 2) {
            if([codeSets count] <= row) {
                NSLog(@"SJActionUIIRDatabaseCommand: didSelectRow: row out of bounds for codeSets [bug]");
                return;
            }
            NSString *codeSet = [codeSets objectAtIndex:row];
            functions = [SwitchamajigIRDeviceDriver getIRDatabaseFunctionsInCodeSet:codeSet onDevice:[self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:1] forComponent:1] forBrand:[self pickerView:irPicker titleForRow:[irPicker selectedRowInComponent:0] forComponent:0]];
            if([[filterFunctionButton titleForState:UIControlStateNormal] isEqualToString:@"Show More Functions"])
                functions = filterFunctions(functions);
            [irPicker reloadComponent:3];
            [irPicker selectRow:0 inComponent:3 animated:NO];
            [self pickerView:irPicker didSelectRow:0 inComponent:3];
        } 
        return;
    } 
    NSLog(@"SJActionUIIRDatabaseCommand: pickerView didSelectRow: PickerView unrecognized.");
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if(pickerView == irPicker) {
        if(component == 0) {
            if([brands count]>row)
                return [brands objectAtIndex:row];
            NSLog(@"SJActionUIIRDatabaseCommand: pickerView titleForRow out of bounds for brands");
            return nil;
        }
        if(component == 1) {
            if([devices count]>row)
                return [devices objectAtIndex:row];
            NSLog(@"SJActionUIIRDatabaseCommand: pickerView titleForRow out of bounds for devices");
            return nil;
        }
        if(component == 2) {
            if([codeSets count]>row) {
                //return [codeSets objectAtIndex:row];
                // The code set names are obscure and take up too much horizontal space
                return [NSString stringWithFormat:@"Code Set %d", row+1];
            }
            NSLog(@"SJActionUIIRDatabaseCommand: pickerView titleForRow out of bounds for codesets");
            return nil;
        }
        if(component == 3){
            if([functions count]>row)
                return [[functions objectAtIndex:row] capitalizedString];
            NSLog(@"SJActionUIIRDatabaseCommand: pickerView titleForRow out of bounds for functions");
            return nil;
        } else if (component == 4) {
            if(row < NUM_REPEAT_COUNT_STRINGS)
                return RepeatCountStrings[row];
            NSLog(@"SJActionUIIRDatabaseCommand: pickerView titleForRow out of bounds for RepeatCountStrings");
            return nil;
        }
        return nil;
    }
    NSLog(@"SJActionUIIRDatabaseCommand: pickerView titleForRow: PickerView unrecognized.");
    return nil;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    if(pickerView == irPicker) {
        switch(component) {
            case 0: return 200;
            case 1: return 225;
            case 2: return 125;
            case 3: return 200;
            case 4: return 100;
        }
    }
    NSLog(@"SJActionUIIRDatabaseCommand: pickerView widthForComponent: PickerView unrecognized.");
    return 0;
}

@end
