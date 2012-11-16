//
//  SJActionUIBack.m
//  SwitchControl
//
//  Created by Phil Weaver on 11/13/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "SJActionUIBack.h"

@implementation SJActionUIBack
+ (NSString *) name {
    return @"Go Back To Main Screen";
};

- (BOOL) setAction:(DDXMLNode *)action {
    if([[action name] isEqualToString:@"back"])
        return YES;
    return NO;
}

- (NSString*) XMLStringForAction{
    NSString *xmlString = @"<back></back>";
    return xmlString;
};

@end
