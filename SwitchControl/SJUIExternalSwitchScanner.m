//
//  SJUIExternalSwitchScanner.m
//  SwitchControl
//
//  Created by Phil Weaver on 11/7/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "SJUIExternalSwitchScanner.h"
#import <QuartzCore/QuartzCore.h>

@implementation SJUIExternalSwitchScanner
@synthesize delegate;

const int button_highlight_size_increase = 50;

- (id)initWithSuperview:(UIView*)superview andScanType:(int)scanTypeInit
{
    self = [super init];
    if (self) {
        scanType = scanTypeInit;
        indexOfSelection = -1;
        if(scanType != SCANNING_STYLE_NONE) {
            // Set up for scanning
            textField = [[UITextField alloc] initWithFrame:CGRectMake(0,0,1,1)];
            [textField setHidden:YES];
            [textField setDelegate:self];
            [textField becomeFirstResponder];
            [superview addSubview:textField];
            buttonsToScan = [NSMutableArray arrayWithCapacity:10];
        }
    }
    return self;
}

- (void) addButtonToScan:(UIButton*)button withLabel:(UILabel*)label {
    NSDictionary *controlDictionary = [NSDictionary dictionaryWithObjectsAndKeys:button, @"button", label, @"label", nil];
    [buttonsToScan addObject:controlDictionary];
}

- (UIButton*) currentlySelectedButton {
    if(indexOfSelection < 0)
        return nil; // Nothing selected
    if([buttonsToScan count] <= indexOfSelection)
        return nil;
    NSDictionary *controlDictionary = [buttonsToScan objectAtIndex:indexOfSelection];
    return [controlDictionary objectForKey:@"button"];
}

- (void) scanPressed:(id)sender {
    if(![buttonsToScan count])
        return;
    if(scanType == SCANNING_STYLE_STEP_SCAN) {
        [self removeHighlightFromCurrentSelection];
        if(++indexOfSelection < 0)
            indexOfSelection = 0;
        if(indexOfSelection >= [buttonsToScan count])
            indexOfSelection = 0;
        [self highlightCurrentSelection];
        NSDictionary *scanItem = [buttonsToScan objectAtIndex:indexOfSelection];
        if(!scanItem) {
            NSLog(@"SJUIExternalSwitchScanner:highlightCurrentScanSelection: scan item is null (code bug");
            return;
        }
        UIButton *button = [scanItem objectForKey:@"button"];
        [delegate SJUIExternalSwitchScannerItemWasSelected:button];
    }
}

- (void) selectPressed:(id)sender {
    if(scanType == SCANNING_STYLE_STEP_SCAN) {
        if(indexOfSelection < 0)
            return; // Nothing selected
        NSDictionary *scanItem = [buttonsToScan objectAtIndex:indexOfSelection];
        if(!scanItem) {
            NSLog(@"SJUIExternalSwitchScanner:highlightCurrentScanSelection: scan item is null (code bug");
            return;
        }
        UIButton *button = [scanItem objectForKey:@"button"];
        [delegate SJUIExternalSwitchScannerItemWasActivated:button];
    }
}

- (void) superviewDidAppear {
    if(scanType == SCANNING_STYLE_STEP_SCAN) {
        if(indexOfSelection >= 0)
            [self removeHighlightFromCurrentSelection];
        if((indexOfSelection < 0) && [buttonsToScan count])
            indexOfSelection = 0;
        [self highlightCurrentSelection];
    }
}


- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    for(int i=0; i < [string length]; ++i) {
        unichar keystroke = [string characterAtIndex:i];
        if((keystroke == ' ') || (keystroke == '1'))
            [self scanPressed:nil];
        if((keystroke == '\n') || (keystroke == '3'))
            [self selectPressed:nil];
    }
    return NO; // This field isn't visible anyway; don't update it
}

// Highlight the current selection. Note that if you call this twice without calling unhighlight,
// you won't be able to get back to where you started
- (void) highlightCurrentSelection {
    if(![buttonsToScan count])
        return; // This action is pointless if there are no buttons to select
    if((indexOfSelection < 0) || (indexOfSelection >= [buttonsToScan count])) {
        NSLog(@"SJUIExternalSwitchScanner:highlightCurrentScanSelection: current selection is invalid (code bug)");
        return;
    }
    NSDictionary *scanItem = [buttonsToScan objectAtIndex:indexOfSelection];
    if(!scanItem) {
        NSLog(@"SJUIExternalSwitchScanner:highlightCurrentScanSelection: scan item is null (code bug");
        return;
    }
    UIButton *button = [scanItem objectForKey:@"button"];
    UILabel *label = [scanItem objectForKey:@"label"];
    // Expand panel when selected
    originalRectOfCurrentButton = button.layer.bounds;
    CGRect newPanelRect = originalRectOfCurrentButton;
    newPanelRect.size.width = originalRectOfCurrentButton.size.width+button_highlight_size_increase;
    newPanelRect.size.height = originalRectOfCurrentButton.size.height+button_highlight_size_increase;
    [UIView beginAnimations:nil context:NULL];
    CGAffineTransform scaling = CGAffineTransformMakeScale(newPanelRect.size.width/originalRectOfCurrentButton.size.width, newPanelRect.size.height/originalRectOfCurrentButton.size.height);
    button.transform = scaling;
    
    if(label) {
        // Note: Assuming label is below button
        // Translate label to keep it centered
        CGAffineTransform translatelabel = CGAffineTransformMakeTranslation(0, (newPanelRect.size.height-originalRectOfCurrentButton.size.height)/2);
        label.transform = translatelabel;
        // Consider changing the label, but we don't always have a label
        //[text setBackgroundColor:[UIColor colorWithRed:0.5 green:0.5 blue:1.0 alpha:1.0]];
        //[text setTextColor:[UIColor blackColor]];
    }
    [UIView commitAnimations];
}

- (void) removeHighlightFromCurrentSelection {
    if(![buttonsToScan count])
        return; // This action is pointless if there are no buttons to select
    if((indexOfSelection < 0) || (indexOfSelection >= [buttonsToScan count])) {
        NSLog(@"SJUIExternalSwitchScanner:removeHighlightFromCurrentSelection: current selection is invalid (code bug)");
        return;
    }
    NSDictionary *scanItem = [buttonsToScan objectAtIndex:indexOfSelection];
    if(!scanItem) {
        NSLog(@"SJUIExternalSwitchScanner:removeHighlightFromCurrentSelection: scan item is null (code bug");
        return;
    }
    UIButton *button = [scanItem objectForKey:@"button"];
    UILabel *label = [scanItem objectForKey:@"label"];
    // Expand panel when selected
    CGRect highlightedRect = button.layer.bounds;
    [UIView beginAnimations:nil context:NULL];
    CGAffineTransform scaling = CGAffineTransformMakeScale(originalRectOfCurrentButton.size.width/highlightedRect.size.width, originalRectOfCurrentButton.size.height/highlightedRect.size.height);
    button.transform = scaling;
    
    if(label) {
        // Note: Assuming label is below button
        // Translate label to keep it centered
        CGAffineTransform translatelabel = CGAffineTransformMakeTranslation(0, (originalRectOfCurrentButton.size.height-highlightedRect.size.height)/2);
        label.transform = translatelabel;
        // Consider changing the label, but we don't always have a label
        //[text setBackgroundColor:[UIColor colorWithRed:0.5 green:0.5 blue:1.0 alpha:1.0]];
        //[text setTextColor:[UIColor blackColor]];
    }
    [UIView commitAnimations];
}

@end
