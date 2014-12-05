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

#import "SJUIExternalSwitchScannerTests.h"
#import "TestEnables.h"
#import "TestMocks.h"

@implementation SJUIExternalSwitchScannerTests
- (void) SJUIExternalSwitchScannerItemWasSelected:(id)item {
    lastSelectedItem = item;
}
- (void) SJUIExternalSwitchScannerItemWasActivated:(id)item {
    lastActivatedItem = item;
}

- (void)setUp
{
    [super setUp];
    superView = [[UIView alloc] init];
    originalRect = CGRectMake(0,0,10,10);
    highlightedButtonRect = CGRectMake(-25,-25,60,60);
    highlightedLabelRect = CGRectMake(0,25,10,10);
    // Create 3 buttons in the superview
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:originalRect];
    [superView addSubview:button];
    
    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:originalRect];
    [superView addSubview:button];
    
    button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setFrame:originalRect];
    [superView addSubview:button];

    [superView addSubview:[[UILabel alloc] initWithFrame:originalRect]];
}

- (void)tearDown
{
    [super tearDown];
    [HandyTestStuff logMemUsage];
}

- (void) setUpScanner:(SJUIExternalSwitchScanner*)scanner {
    [scanner setDelegate:self];
    [scanner addButtonToScan:[[superView subviews] objectAtIndex:0] withLabel:nil];
    [scanner addButtonToScan:[[superView subviews] objectAtIndex:1] withLabel:nil];
    [scanner addButtonToScan:[[superView subviews] objectAtIndex:2] withLabel:[[superView subviews] objectAtIndex:3]];
    [scanner superviewDidAppear];
}

BOOL rectsEqual(CGRect rect1, CGRect rect2);
BOOL rectsEqual(CGRect rect1, CGRect rect2) {
    if(rect1.origin.x != rect2.origin.x) {
        NSLog(@"Origin.x: rect1 = %f, rect2 = %f", rect1.origin.x, rect2.origin.x);
        return NO;
    }
    if(rect1.origin.y != rect2.origin.y){
        NSLog(@"Origin.y: rect1 = %f, rect2 = %f", rect1.origin.y, rect2.origin.y);
        return NO;
    }
    if(rect1.size.width != rect2.size.width){
        NSLog(@"Size.width: rect1 = %f, rect2 = %f", rect1.size.width, rect2.size.width);
        return NO;
    }
    if(rect1.size.height != rect2.size.height){
        NSLog(@"Size.height: rect1 = %f, rect2 = %f", rect1.size.height, rect2.size.height);
        return NO;
    }
    return YES;
}
#if RUN_ALL_SCANNER_TESTS

- (void)test_000_no_scanning {
    // Set the scanner for no scanning
    SJUIExternalSwitchScanner *scanner = [[SJUIExternalSwitchScanner alloc] initWithSuperview:superView andScanType:SCANNING_STYLE_NONE];
    [self setUpScanner:scanner];
    // Make sure nothing's been added to the superview
    STAssertTrue([[superView subviews] count] == 4, @"Scanner added extra stuff to superview when scanning disabled");
    // Check the state of the scanner
    STAssertNil(scanner->buttonsToScan, @"Scan buttons should not be initialized if not scanning");
    STAssertTrue(scanner->scanType == SCANNING_STYLE_NONE, @"Bad initialization of scantype");
    STAssertTrue(scanner->indexOfSelection == -1, @"Item selected when not scanning");
    STAssertNil(scanner->textField, @"Text field created when not scanning");
    STAssertNil(scanner->autoScanTimer, @"Timer created when not scanning");
    STAssertNil([scanner currentlySelectedButton], @"Scanner should not have anything selected when not scanning");
    // Make sure nothing in the view has changed
    UIView *subview;
    for(subview in [superView subviews])
        STAssertTrue(rectsEqual([subview frame], originalRect), @"Frame of buttons should not change when scanning is disabled");
}

- (void)test_001_auto_scanning {
    // Set the scanner for no scanning
    SJUIExternalSwitchScanner *scanner = [[SJUIExternalSwitchScanner alloc] initWithSuperview:superView andScanType:SCANNING_STYLE_AUTO_SCAN];
    [self setUpScanner:scanner];
    // There should now be a UITextView in the superview
    UITextField *textField = [[superView subviews] objectAtIndex:4];
    STAssertTrue([textField delegate] == (id)scanner, @"Scanner is not the delegate of the text view");
    STAssertTrue(scanner->textField == textField, @"Text fields are not the same");
    // Check the state of the scanner
    STAssertTrue([scanner->buttonsToScan count] == 3, @"Scanner has %d buttons", [scanner->buttonsToScan count]);
    STAssertEqualObjects([[scanner->buttonsToScan objectAtIndex:0] objectForKey:@"button"], [[superView subviews] objectAtIndex:0], @"Button not set up correctly");
    STAssertEqualObjects([[scanner->buttonsToScan objectAtIndex:1] objectForKey:@"button"], [[superView subviews] objectAtIndex:1], @"Button not set up correctly");
    STAssertEqualObjects([[scanner->buttonsToScan objectAtIndex:2] objectForKey:@"button"], [[superView subviews] objectAtIndex:2], @"Button not set up correctly");
    STAssertEqualObjects([[scanner->buttonsToScan objectAtIndex:2] objectForKey:@"label"], [[superView subviews] objectAtIndex:3], @"Label not set up correctly");
    STAssertTrue(scanner->scanType == SCANNING_STYLE_AUTO_SCAN, @"Bad initialization of scantype");
    STAssertTrue(scanner->indexOfSelection == -1, @"Item selected when not scanning");
    STAssertNil(scanner->autoScanTimer, @"Timer created when not scanning");
    STAssertNil([scanner currentlySelectedButton], @"Scanner should not have anything selected when not scanning");
    // Make sure nothing in the view has changed
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:0] frame], originalRect), @"Button 0 highlighted before start of auto scan");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:1] frame], originalRect), @"Button 1 highlighted at start of auto scan");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:2] frame], originalRect), @"Button 2  highlighted at start of auto scan");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:3] frame], originalRect), @"Label highlighted at start of auto scan");
    // Start scanning
    lastSelectedItem = nil;
    [scanner textField:textField shouldChangeCharactersInRange:NSMakeRange(0,0) replacementString:@"\n"];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)0.5]];
    // First button should be highlighted
    STAssertTrue(scanner->indexOfSelection == 0, @"Item 0 not selected instead have %d", scanner->indexOfSelection);
    STAssertEqualObjects([scanner currentlySelectedButton], [[superView subviews] objectAtIndex:0], @"Wrong button selected");
    STAssertEqualObjects(lastSelectedItem, [[superView subviews] objectAtIndex:0], @"Callback received different object");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:0] frame], highlightedButtonRect), @"Button 0 not highlighted at start of auto scan");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:1] frame], originalRect), @"Button 1 highlighted at start of auto scan");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:2] frame], originalRect), @"Button 2  highlighted at start of auto scan");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:3] frame], originalRect), @"Label highlighted at start of auto scan");
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Second button should be highlighted
    STAssertTrue(scanner->indexOfSelection == 1, @"Item 1 not selected instead have %d", scanner->indexOfSelection);
    STAssertEqualObjects([scanner currentlySelectedButton], [[superView subviews] objectAtIndex:1], @"Wrong button selected");
    STAssertEqualObjects(lastSelectedItem, [[superView subviews] objectAtIndex:1], @"Callback received different object");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:0] frame], originalRect), @"Button 0 highlighted at wrong time");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:1] frame], highlightedButtonRect), @"Button 1 should be highlighted");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:2] frame], originalRect), @"Button 2  highlighted at wrong time");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:3] frame], originalRect), @"Label highlighted at wrong time");
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Third button should be highlighted, and its label should as well
    STAssertTrue(scanner->indexOfSelection == 2, @"Item 2 not selected instead have %d", scanner->indexOfSelection);
    STAssertEqualObjects([scanner currentlySelectedButton], [[superView subviews] objectAtIndex:2], @"Wrong button selected");
    STAssertEqualObjects(lastSelectedItem, [[superView subviews] objectAtIndex:2], @"Callback received different object");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:0] frame], originalRect), @"Button 0 highlighted at wrong time");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:1] frame], originalRect), @"Button 1 highlighted at wrong time");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:2] frame], highlightedButtonRect), @"Button 2 should be highlighted");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:3] frame], highlightedLabelRect), @"Label should be highlighted");
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:(NSTimeInterval)1.0]];
    // Should be back to first button
    STAssertTrue(scanner->indexOfSelection == 0, @"Item 1 not selected instead have %d", scanner->indexOfSelection);
    STAssertEqualObjects([scanner currentlySelectedButton], [[superView subviews] objectAtIndex:0], @"Wrong button selected");
    STAssertEqualObjects(lastSelectedItem, [[superView subviews] objectAtIndex:0], @"Callback received different object");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:0] frame], highlightedButtonRect), @"Button 0 should be highlighted");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:1] frame], originalRect), @"Button 1 highlighted at wrong time");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:2] frame], originalRect), @"Button 2 highlighted at wrong time");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:3] frame], originalRect), @"Label highlighted at wrong time");
    // Activate button 0
    lastActivatedItem = nil;
    [scanner textField:textField shouldChangeCharactersInRange:NSMakeRange(0,0) replacementString:@"3"];
    STAssertEqualObjects(lastActivatedItem, [[superView subviews] objectAtIndex:0], @"Callback received different object");
    // Should be back to the no-scanning state
    STAssertTrue(scanner->indexOfSelection == -1, @"Item selected when not scanning");
    STAssertNil(scanner->autoScanTimer, @"Timer created when not scanning");
    STAssertNil([scanner currentlySelectedButton], @"Scanner should not have anything selected when not scanning");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:0] frame], originalRect), @"Button 0 highlighted after auto scan");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:1] frame], originalRect), @"Button 1 highlighted after auto scan");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:2] frame], originalRect), @"Button 2  highlighted after auto scan");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:3] frame], originalRect), @"Label highlighted after auto scan");
    [scanner removeAllScanButtons];
    STAssertTrue([scanner->buttonsToScan count] == 0, @"Failed to remove buttons from scanner.");
}

- (void)test_002_step_scanning {
    // Set the scanner for no scanning
    SJUIExternalSwitchScanner *scanner = [[SJUIExternalSwitchScanner alloc] initWithSuperview:superView andScanType:SCANNING_STYLE_STEP_SCAN];
    [self setUpScanner:scanner];
    // There should now be a UITextView in the superview
    UITextField *textField = [[superView subviews] objectAtIndex:4];
    STAssertTrue([textField delegate] == (id)scanner, @"Scanner is not the delegate of the text view");
    STAssertTrue(scanner->textField == textField, @"Text fields are not the same");
    // Check the state of the scanner
    STAssertTrue([scanner->buttonsToScan count] == 3, @"Scanner has %d buttons", [scanner->buttonsToScan count]);
    STAssertEqualObjects([[scanner->buttonsToScan objectAtIndex:0] objectForKey:@"button"], [[superView subviews] objectAtIndex:0], @"Button not set up correctly");
    STAssertEqualObjects([[scanner->buttonsToScan objectAtIndex:1] objectForKey:@"button"], [[superView subviews] objectAtIndex:1], @"Button not set up correctly");
    STAssertEqualObjects([[scanner->buttonsToScan objectAtIndex:2] objectForKey:@"button"], [[superView subviews] objectAtIndex:2], @"Button not set up correctly");
    STAssertEqualObjects([[scanner->buttonsToScan objectAtIndex:2] objectForKey:@"label"], [[superView subviews] objectAtIndex:3], @"Label not set up correctly");
    STAssertTrue(scanner->scanType == SCANNING_STYLE_STEP_SCAN, @"Bad initialization of scantype");
    STAssertTrue(scanner->indexOfSelection == 0, @"Item 0 not selected instead have %d", scanner->indexOfSelection);
    STAssertNil(scanner->autoScanTimer, @"Timer created for step scanning");
    STAssertEqualObjects([scanner currentlySelectedButton], [[superView subviews] objectAtIndex:0], @"Wrong initial selected button");
    STAssertEqualObjects(lastSelectedItem, [[superView subviews] objectAtIndex:0], @"Callback received different object");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:0] frame], highlightedButtonRect), @"Button 0 not highlighted at start of auto scan");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:1] frame], originalRect), @"Button 1 highlighted at start of auto scan");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:2] frame], originalRect), @"Button 2  highlighted at start of auto scan");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:3] frame], originalRect), @"Label highlighted at start of auto scan");
    [scanner textField:textField shouldChangeCharactersInRange:NSMakeRange(0,0) replacementString:@"1"];
    // Second button should be highlighted
    STAssertTrue(scanner->indexOfSelection == 1, @"Item 1 not selected instead have %d", scanner->indexOfSelection);
    STAssertEqualObjects([scanner currentlySelectedButton], [[superView subviews] objectAtIndex:1], @"Wrong button selected");
    STAssertEqualObjects(lastSelectedItem, [[superView subviews] objectAtIndex:1], @"Callback received different object");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:0] frame], originalRect), @"Button 0 highlighted at wrong time");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:1] frame], highlightedButtonRect), @"Button 1 should be highlighted");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:2] frame], originalRect), @"Button 2  highlighted at wrong time");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:3] frame], originalRect), @"Label highlighted at wrong time");
    [scanner textField:textField shouldChangeCharactersInRange:NSMakeRange(0,0) replacementString:@" "];
    // Third button should be highlighted, and its label should as well
    STAssertTrue(scanner->indexOfSelection == 2, @"Item 2 not selected instead have %d", scanner->indexOfSelection);
    STAssertEqualObjects([scanner currentlySelectedButton], [[superView subviews] objectAtIndex:2], @"Wrong button selected");
    STAssertEqualObjects(lastSelectedItem, [[superView subviews] objectAtIndex:2], @"Callback received different object");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:0] frame], originalRect), @"Button 0 highlighted at wrong time");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:1] frame], originalRect), @"Button 1 highlighted at wrong time");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:2] frame], highlightedButtonRect), @"Button 2 should be highlighted");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:3] frame], highlightedLabelRect), @"Label should be highlighted");
    [scanner textField:textField shouldChangeCharactersInRange:NSMakeRange(0,0) replacementString:@"~1"];
    // Should be back to first button
    STAssertTrue(scanner->indexOfSelection == 0, @"Item 0 not selected instead have %d", scanner->indexOfSelection);
    STAssertEqualObjects([scanner currentlySelectedButton], [[superView subviews] objectAtIndex:0], @"Wrong button selected");
    STAssertEqualObjects(lastSelectedItem, [[superView subviews] objectAtIndex:0], @"Callback received different object");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:0] frame], highlightedButtonRect), @"Button 0 should be highlighted");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:1] frame], originalRect), @"Button 1 highlighted at wrong time");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:2] frame], originalRect), @"Button 2 highlighted at wrong time");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:3] frame], originalRect), @"Label highlighted at wrong time");
    // Activate button 0
    lastActivatedItem = nil;
    [scanner textField:textField shouldChangeCharactersInRange:NSMakeRange(0,0) replacementString:@"\n"];
    STAssertEqualObjects(lastActivatedItem, [[superView subviews] objectAtIndex:0], @"Callback received different object");
    // Should keep same state
    STAssertTrue(scanner->indexOfSelection == 0, @"Item 0 not selected instead have %d", scanner->indexOfSelection);
    STAssertEqualObjects([scanner currentlySelectedButton], [[superView subviews] objectAtIndex:0], @"Wrong button selected");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:0] frame], highlightedButtonRect), @"Button 0 should be highlighted");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:1] frame], originalRect), @"Button 1 highlighted at wrong time");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:2] frame], originalRect), @"Button 2 highlighted at wrong time");
    STAssertTrue(rectsEqual([[[superView subviews] objectAtIndex:3] frame], originalRect), @"Label highlighted at wrong time");
    // Confirm that the other button has the same effect
    lastActivatedItem = nil;
    [scanner textField:textField shouldChangeCharactersInRange:NSMakeRange(0,0) replacementString:@"3"];
    STAssertEqualObjects(lastActivatedItem, [[superView subviews] objectAtIndex:0], @"Callback received different object");
}

#endif
@end
