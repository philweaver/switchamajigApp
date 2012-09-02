//
//  SJActionUI.h
//  SwitchControl
//
//  Created by Phil Weaver on 8/31/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "defineActionViewController.h"

@interface SJActionUI : NSObject
+ (NSString *) name;
- (void) createUI;
- (void) driverSelectionDidChange;
- (void) setHidden:(BOOL)hidden;
- (NSString*) XMLStringForAction;
// setAction returns YES if the actionUI can produce the action
- (BOOL) setAction:(DDXMLNode*)action;
@property defineActionViewController *defineActionVC;
@end

@interface SJActionUINoAction:SJActionUI
@end
