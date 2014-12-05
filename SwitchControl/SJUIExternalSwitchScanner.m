/*
Copyright 2014 PAW Solutions LLC

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

#import "SJUIExternalSwitchScanner.h"
#import <QuartzCore/QuartzCore.h>

@implementation SJUIExternalSwitchScanner
@synthesize delegate;
@synthesize autoScanInterval;

const int button_highlight_size_increase = 50;

- (id)initWithSuperview:(UIView*)superview andScanType:(int)scanTypeInit
{
    self = [super init];
    if (self) {
        scanType = scanTypeInit;
        [self setAutoScanInterval:[NSNumber numberWithInt:1]];
        indexOfSelection = -1;
        if(scanType != SCANNING_STYLE_NONE) {
            // Set up for scanning
            UITextField *tempTextField = [[UITextField alloc] initWithFrame:CGRectMake(0,0,1,1)];
            textField = tempTextField;
            [textField setHidden:YES];
            [textField setDelegate:self];
            [textField becomeFirstResponder];
            [superview addSubview:textField];
            buttonsToScan = [NSMutableArray arrayWithCapacity:10];
            autoScanTimer = nil;
        }
    }
    return self;
}

- (void) addButtonToScan:(UIButton*)button withLabel:(UILabel*)label {
    NSDictionary *controlDictionary = [NSDictionary dictionaryWithObjectsAndKeys:button, @"button", label, @"label", nil];
    [buttonsToScan addObject:controlDictionary];
}

- (void) removeAllScanButtons {
    [buttonsToScan removeAllObjects];
}

- (UIButton*) currentlySelectedButton {
    if(indexOfSelection < 0)
        return nil; // Nothing selected
    if([buttonsToScan count] <= indexOfSelection)
        return nil;
    NSDictionary *controlDictionary = [buttonsToScan objectAtIndex:indexOfSelection];
    return [controlDictionary objectForKey:@"button"];
}

- (void) moveToNextSelectedItem {
    if(indexOfSelection >= 0)
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

- (void) scanPressed:(id)sender {
    if(![buttonsToScan count])
        return;
    if(scanType == SCANNING_STYLE_STEP_SCAN) {
        [self moveToNextSelectedItem];
    }
}

- (void) activateCurrentSelection {
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

- (void) selectPressed:(id)sender {
    if(![buttonsToScan count])
        return;
    if(scanType == SCANNING_STYLE_STEP_SCAN) {
        [self activateCurrentSelection];
    }
    if(scanType == SCANNING_STYLE_AUTO_SCAN) {
        if(indexOfSelection >= 0) {
            // If a switch is already highlighted, activate it
            [self activateCurrentSelection];
            // Reset the scanning
            [self removeHighlightFromCurrentSelection];
            indexOfSelection = -1;
            [autoScanTimer invalidate];
            autoScanTimer = nil;
        }
        else {
            [self moveToNextSelectedItem];
            // Start timer to scan
            autoScanTimer = [NSTimer scheduledTimerWithTimeInterval:[[self autoScanInterval] floatValue] target:self selector:@selector(moveToNextSelectedItem) userInfo:nil repeats:YES];
        }
    }
}

- (void) superviewDidAppear {
    if(scanType == SCANNING_STYLE_STEP_SCAN) {
        if(indexOfSelection == -1)
            [self moveToNextSelectedItem];
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
