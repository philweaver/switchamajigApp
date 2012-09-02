//
//  SJActionUI.m
//  SwitchControl
//
//  Created by Phil Weaver on 8/31/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "SJActionUI.h"

@implementation SJActionUI
@synthesize defineActionVC;
+ (NSString *) name {
    return nil;
};
- (void) createUI {};
- (void) driverSelectionDidChange{};
- (void) setHidden:(BOOL)hidden{};
- (NSString*) XMLStringForAction{ return nil; };
- (BOOL) setAction:(DDXMLNode*)action{
    return NO; // Didn't process anything
};
@end

@implementation SJActionUINoAction

+ (NSString *) name {
    return @"No Action";
};

- (BOOL) setAction:(DDXMLNode *)action {
    return YES;
}

@end