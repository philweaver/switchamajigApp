//
//  SJActionUITurnSwitchesOnOff.m
//  SwitchControl
//
//  Created by Phil Weaver on 8/31/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "SJActionUITurnSwitchesOnOff.h"

@implementation SJActionUITurnSwitchesOnOff
- (void) createUI {
    // Need an actionVC to create a UI
    if(![self defineActionVC])
        return;
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
        [[[self defineActionVC] view] addSubview:switchButtons[i]];
    }
}
- (void) driverSelectionDidChange{}; // Doesn't affect our view

- (void) setHidden:(BOOL)hidden{
    for(int i=0; i < NUM_SJIG_SWITCHES; ++i)
        [switchButtons[i] setHidden:hidden];
};

- (BOOL) setAction:(DDXMLNode*)action{
    NSString *myKindOfString;
    if([self isKindOfClass:[SJActionUITurnSwitchesOn class]])
        myKindOfString = @"turnSwitchesOn";
    if([self isKindOfClass:[SJActionUITurnSwitchesOff class]])
        myKindOfString = @"turnSwitchesOff";
    if([[action name] isEqualToString:myKindOfString]) {
        NSScanner *switchScan = [[NSScanner alloc] initWithString:[action stringValue]];
        int switchNumber;
        while([switchScan scanInt:&switchNumber]) {
            if((switchNumber > 0) && (switchNumber <= NUM_SJIG_SWITCHES)) {
                [switchButtons[switchNumber-1] setBackgroundColor:[UIColor redColor]];
            }
        }
        return YES;
    }
    return NO;
};

- (void) toggleSwitchButton:(id)sender {
    UIButton *button = sender;
    if([[button backgroundColor] isEqual:[UIColor grayColor]])
        [button setBackgroundColor:[UIColor redColor]];
    else {
        [button setBackgroundColor:[UIColor grayColor]];
    }
}

@end

@implementation SJActionUITurnSwitchesOn
+ (NSString *) name {
    return @"Turn Switches On";
};
- (NSString*) XMLStringForAction{
    NSMutableString *xmlString = [NSMutableString stringWithCapacity:100];
    [xmlString setString:@"<turnSwitchesOn>"];
    for(int i=0; i < NUM_SJIG_SWITCHES; ++i) {
        if([[switchButtons[i] backgroundColor] isEqual:[UIColor redColor]])
            [xmlString appendString:[NSString stringWithFormat:@"%d ", i+1]];
    }
    [xmlString appendString:@"</turnSwitchesOn>"];
    return xmlString;
};

@end

@implementation SJActionUITurnSwitchesOff
+ (NSString *) name {
    return @"Turn Switches Off";
};
- (NSString*) XMLStringForAction{
    NSMutableString *xmlString = [NSMutableString stringWithCapacity:100];
    [xmlString setString:@"<turnSwitchesOff>"];
    for(int i=0; i < NUM_SJIG_SWITCHES; ++i) {
        if([[switchButtons[i] backgroundColor] isEqual:[UIColor redColor]])
            [xmlString appendString:[NSString stringWithFormat:@"%d ", i+1]];
    }
    [xmlString appendString:@"</turnSwitchesOff>"];
    return xmlString;
};

@end
