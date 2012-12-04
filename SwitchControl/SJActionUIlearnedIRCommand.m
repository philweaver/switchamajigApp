//
//  SJActionUIlearnedIRCommand.m
//  SwitchControl
//
//  Created by Phil Weaver on 8/31/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "SJActionUIlearnedIRCommand.h"
#import "Flurry.h"
@implementation SJActionUIlearnedIRCommand
+ (NSString *) name {
    return @"Learned IR Command";
};

- (void) createUI {
    if(![self defineActionVC])
        return;
    learnedIRCommands = [[NSMutableDictionary alloc] initWithCapacity:5];
    learnedIrPicker = [[UIPickerView alloc] initWithFrame:CGRectMake(250, 250, 300, 162)];
    [learnedIrPicker setDelegate:self];
    [learnedIrPicker setDataSource:self];
    [learnedIrPicker setShowsSelectionIndicator:YES];
    [[[self defineActionVC] view] addSubview:learnedIrPicker];
    
    learnedIRPickerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 200, 800, 44)];
    [learnedIRPickerLabel setBackgroundColor:[UIColor blackColor]];
    [learnedIRPickerLabel setTextColor:[UIColor whiteColor]];
    [learnedIRPickerLabel setText:@"Learned IR Command"];
    [learnedIRPickerLabel setTextAlignment:UITextAlignmentCenter];
    [learnedIRPickerLabel setFont:[UIFont systemFontOfSize:20]];
    [[[self defineActionVC] view] addSubview:learnedIRPickerLabel];
    
    learnIRButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [learnIRButton setFrame:CGRectMake(250, 462, 300, 44)];
    [learnIRButton setTitle:@"Learn New IR Command" forState:UIControlStateNormal];
    [learnIRButton addTarget:self action:@selector(learnNewIRCommand:) forControlEvents:UIControlEventTouchUpInside];
    [[[self defineActionVC] view] addSubview:learnIRButton];
    
#if 0
    // Don't support renaming and deleting commands until we also remember them
    renameLearnedIRCommandButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [renameLearnedIRCommandButton setFrame:CGRectMake(600, 250, 200, 44)];
    [renameLearnedIRCommandButton setTitle:@"Rename IR Command" forState:UIControlStateNormal];
    [renameLearnedIRCommandButton addTarget:self action:@selector(renameIRCommand:) forControlEvents:UIControlEventTouchUpInside];
    [[[self defineActionVC] view] addSubview:renameLearnedIRCommandButton];
    
    deleteLearnedIRCommandButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [deleteLearnedIRCommandButton setFrame:CGRectMake(600, 300, 200, 44)];
    [deleteLearnedIRCommandButton setTitle:@"Delete IR Command" forState:UIControlStateNormal];
    [deleteLearnedIRCommandButton addTarget:self action:@selector(deleteIRCommand:) forControlEvents:UIControlEventTouchUpInside];
    [[[self defineActionVC] view] addSubview:deleteLearnedIRCommandButton];
    
    confirmDeleteLearnedIRCommandButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [confirmDeleteLearnedIRCommandButton setFrame:CGRectMake(325, 550, 150, 44)];
    [confirmDeleteLearnedIRCommandButton setBackgroundImage:[[UIImage imageNamed:@"iphone_delete_button.png"] stretchableImageWithLeftCapWidth:8.0f topCapHeight:0.0f] forState:UIControlStateNormal];
    [confirmDeleteLearnedIRCommandButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [confirmDeleteLearnedIRCommandButton setTitle:@"Confirm Delete" forState:UIControlStateNormal];
    [confirmDeleteLearnedIRCommandButton addTarget:self action:@selector(deleteIRCommand:) forControlEvents:UIControlEventTouchUpInside];
    [[[self defineActionVC] view] addSubview:confirmDeleteLearnedIRCommandButton];
#endif
    
    testLearnedIRButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [testLearnedIRButton setFrame:CGRectMake(600, 350, 200, 44)];
    [testLearnedIRButton setTitle:@"Test IR Command" forState:UIControlStateNormal];
    [testLearnedIRButton addTarget:self action:@selector(testLearnedIRCommand:) forControlEvents:UIControlEventTouchUpInside];
    [[[self defineActionVC] view] addSubview:testLearnedIRButton];
    
    // UI when learning is in progress
    // Instructions
    learningIRInstructionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(225, 200, 350, 150)];
    [learningIRInstructionsLabel setBackgroundColor:[UIColor blackColor]];
    [learningIRInstructionsLabel setTextColor:[UIColor whiteColor]];
    [learningIRInstructionsLabel setText:@"Point your remote at the Switchamajig IR where it's marked 'IR Learning' and press the button you want to learn"];
    [learningIRInstructionsLabel setNumberOfLines:0];
    [learningIRInstructionsLabel setTextAlignment:UITextAlignmentCenter];
    [learningIRInstructionsLabel setFont:[UIFont systemFontOfSize:20]];
    [[[self defineActionVC] view] addSubview:learningIRInstructionsLabel];
    // Image
    learnIRImage = [[UIImageView alloc] initWithFrame:CGRectMake(250, 350, 300, 150)];
    [learnIRImage setImage:[UIImage imageNamed:@"learning_IR.png"]];
    [[[self defineActionVC] view] addSubview:learnIRImage];
    /* Cancel button
    learningIRCancelButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [learningIRCancelButton setFrame:CGRectMake(325, 550, 150, 44)];
    [learningIRCancelButton setTitle:@"Cancel IR Learning" forState:UIControlStateNormal];
    [learningIRCancelButton addTarget:self action:@selector(cancelIRLearning:) forControlEvents:UIControlEventTouchUpInside];
    [[[self defineActionVC] view] addSubview:learningIRCancelButton];*/
};
- (void) driverSelectionDidChange {
    [testLearnedIRButton setHidden:[learnedIrPicker isHidden]];
    [learnIRButton setHidden:[learnedIrPicker isHidden]];
    [[[[self defineActionVC] appDelegate] statusInfoLock] lock];
    SwitchamajigDriver *driver = [[self defineActionVC] getCurrentlySelectedDriver];
    if(![driver isKindOfClass:[SwitchamajigIRDeviceDriver class]]) {
        [testLearnedIRButton setHidden:YES];
        [learnIRButton setHidden:YES];
    }
    [[[[self defineActionVC] appDelegate] statusInfoLock] unlock];
};

- (void) setHidden:(BOOL)hidden{
    [learnedIrPicker setHidden:hidden];
    [learnedIRPickerLabel setHidden:hidden];
    //[renameLearnedIRCommandButton setHidden:hidden];
    //[deleteLearnedIRCommandButton setHidden:hidden];
    // Parts of the UI should only become visible when they are explicitly shown, but they should be hidden with the rest
    if(hidden) {
        //[confirmDeleteLearnedIRCommandButton setHidden:hidden];
        [learnIRImage setHidden:hidden];
        [learningIRInstructionsLabel setHidden:hidden];
        //[learningIRCancelButton setHidden:hidden];
    }
    // Other parts of the UI are shown only if the current driver supports IR
   [self driverSelectionDidChange];
};


- (NSString*) XMLStringForAction {
    int currentRow = [learnedIrPicker selectedRowInComponent:0];
    NSString *learnedCommandName = [self pickerView:learnedIrPicker titleForRow:currentRow forComponent:0];
    if(!learnedCommandName)
        return nil;
    NSString *learnedCommand = [learnedIRCommands objectForKey:learnedCommandName];
    if(!learnedCommand)
        return nil;
    NSString *irXmlCommand = [NSString stringWithFormat:@"<docommand key=\"0\" repeat=\"n\" seq=\"n\" command=\"Learned:%@\" ir_data=\"%@\" ch=\"0\"></docommand>", learnedCommandName, learnedCommand];
    NSLog(@"Learned IR XML Command = %@", irXmlCommand);
    [Flurry logEvent:@"IR Learned Command XMLStringForAction"];
    return irXmlCommand;
};


- (BOOL) setAction:(DDXMLNode*)action {
    if(![[action name] isEqualToString:@"docommand"])
        return NO;
    DDXMLElement *actionElement = (DDXMLElement *)action;
    DDXMLNode *commandNode = [actionElement attributeForName:@"command"];
    if(!commandNode)
        return NO;
    NSString *IRCommand = [commandNode stringValue];
    NSArray *irCommandParts = [IRCommand componentsSeparatedByString:@":"];
    if([irCommandParts count] < 1)
        return NO;
    if(![[irCommandParts objectAtIndex:0] isEqualToString:@"Learned"])
        return NO;
    DDXMLNode *IRDataNode = [actionElement attributeForName:@"ir_data"];
    if(!IRDataNode)
        return NO;
    NSString *IRDataString = [IRDataNode stringValue];
    if(!IRDataString)
        return NO;
    // Add command to dictionary
    NSString *commandName;
    unsigned int i=0;
    do {
        ++i;
        commandName = [NSString stringWithFormat:@"Learned IR Command %d", i];
    } while ([learnedIRCommands objectForKey:commandName]);
    [learnedIRCommands setObject:IRDataString forKey:commandName];
    [learnedIrPicker reloadAllComponents];
    return YES;
};

- (void) learnNewIRCommand:(id)sender {
    [[[[self defineActionVC] appDelegate] statusInfoLock] lock];
    SwitchamajigDriver *driver = [[self defineActionVC] getCurrentlySelectedDriver];
    if(!driver) {
        NSLog(@"defineActionViewController: learnNewIRCommand: Driver is nil");
        [[[[self defineActionVC] appDelegate] statusInfoLock] unlock];
        return;
    }
    if(![driver isKindOfClass:[SwitchamajigIRDeviceDriver class]]){
        NSLog(@"defineActionViewController: learnNewIRCommand: Driver is not for IR device");
        [[[[self defineActionVC] appDelegate] statusInfoLock] unlock];
        return;
    }
    // Show the learning UI
    [learnIRImage setHidden:NO];
    [learningIRInstructionsLabel setHidden:NO];
    //[learningIRCancelButton setHidden:NO];
    // Disable the rest of the UI
    [[self defineActionVC]->actionPicker setUserInteractionEnabled:NO];
    [[self defineActionVC]->doneButton setUserInteractionEnabled:NO];
    [[self defineActionVC]->cancelButton setUserInteractionEnabled:NO];
    //[confirmDeleteLearnedIRCommandButton setHidden:YES];
    //[renameLearnedIRCommandButton setUserInteractionEnabled:NO];
    //[deleteLearnedIRCommandButton setUserInteractionEnabled:NO];
    [testLearnedIRButton setUserInteractionEnabled:NO];
    SwitchamajigIRDeviceDriver *irDriver = (SwitchamajigIRDeviceDriver *)driver;
    [[[self defineActionVC] appDelegate] clearLastLearnedIRInfo];
    [irDriver startIRLearning];
    [[[[self defineActionVC] appDelegate] statusInfoLock] unlock];
    // Set up timer to poll the delegate for an IR command to arrive
    learnIRPollTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(learnIRPollCallback) userInfo:nil repeats:YES];
}

-(void)learnIRPollCallback {
    NSString *learnedIRCommand = [[[self defineActionVC] appDelegate] getLastLearnedIRCommand];
    NSError *irError = [[[self defineActionVC] appDelegate] getLastLearnedIRError];
    learnIRAnimationCounter++;
    switch(learnIRAnimationCounter & 0x03) {
        case 0: [learnIRImage setImage:[UIImage imageNamed:@"learning_IR.png"]]; break;
        case 1: [learnIRImage setImage:[UIImage imageNamed:@"learning_IR_1.png"]]; break;
        case 2: [learnIRImage setImage:[UIImage imageNamed:@"learning_IR_2.png"]]; break;
        case 3: [learnIRImage setImage:[UIImage imageNamed:@"learning_IR_3.png"]]; break;
    }
    if(learnedIRCommand || irError) {
        [learnIRPollTimer invalidate];
        NSLog(@"Receive IR command: %@", learnedIRCommand);
        if(irError) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"IR Timeout" message:@"Make sure to send the IR command right after starting learning." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alertView show];
        } else {
            // Add command to dictionary
            NSString *commandName;
            unsigned int i=0;
            do {
                ++i;
                commandName = [NSString stringWithFormat:@"Learned IR Command %d", i];
            } while ([learnedIRCommands objectForKey:commandName]);
            [learnedIRCommands setObject:learnedIRCommand forKey:commandName];
        }
        [learnedIrPicker reloadAllComponents];
        // Drop back to the standard UI
        [self cancelIRLearning:nil];
    }
}

-(void) cancelIRLearning:(id)sender {
    // Stop polling
    [learnIRPollTimer invalidate];
    // Make the learning UI disappear
    [learnIRImage setHidden:YES];
    [learningIRInstructionsLabel setHidden:YES];
    //[learningIRCancelButton setHidden:YES];
    NSLog(@"learnIRImage ishidden: %d", (int)[learnIRImage isHidden]);
    // Enable the rest of the UI
    [[self defineActionVC]->actionPicker setUserInteractionEnabled:YES];
    [[self defineActionVC]->doneButton setUserInteractionEnabled:YES];
    [[self defineActionVC]->cancelButton setUserInteractionEnabled:YES];
    //[renameLearnedIRCommandButton setUserInteractionEnabled:YES];
    //[deleteLearnedIRCommandButton setUserInteractionEnabled:YES];
    [testLearnedIRButton setUserInteractionEnabled:YES];
}

-(void) testLearnedIRCommand:(id)sender {
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

// UIPickerViewDataSource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    if(pickerView == learnedIrPicker)
        return 1;
    NSLog(@"SJActionUIlearnedIRCommand: numberOfComponentsInPickerView: PickerView unrecognized.");
    return 0;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    // Apparently in iOS 6 if your touch an empty picker the app crashes with "request for rect at invalid index path"
    if([learnedIRCommands count] == 0)
        return 1;
    if(pickerView == learnedIrPicker)
        return [learnedIRCommands count];
    NSLog(@"SJActionUIlearnedIRCommand: pickerView numberOfRowsInComponent: PickerView unrecognized.");
    return 0;
}

// UIPickerViewDelegate
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (pickerView == learnedIrPicker) {
        return;
    }
    NSLog(@"SJActionUIlearnedIRCommand: pickerView didSelectRow: PickerView unrecognized.");
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    if(pickerView == learnedIrPicker) {
        if([learnedIRCommands count]>row)
            return[[learnedIRCommands allKeys] objectAtIndex:row];
        if([learnedIRCommands count] == 0)
            return nil; // Don't report an error in this case since we're working around an iOS 6 bug
        NSLog(@"SJActionUIlearnedIRCommand: pickerView titleForRow out of bounds for learnedIRCommands");
        return nil;
    }
    NSLog(@"SJActionUIlearnedIRCommand: pickerView titleForRow: PickerView unrecognized.");
    return nil;
}


- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    if(pickerView == learnedIrPicker)
        return 250;
    NSLog(@"SJActionUIlearnedIRCommand: pickerView widthForComponent: PickerView unrecognized.");
    return 0;
}

@end
