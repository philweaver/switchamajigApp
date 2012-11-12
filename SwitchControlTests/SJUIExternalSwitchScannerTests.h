//
//  SJUIExternalSwitchScannerTests.h
//  SwitchControl
//
//  Created by Phil Weaver on 11/9/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "SJUIExternalSwitchScanner.h"

@interface SJUIExternalSwitchScannerTests : SenTestCase <SJUIExternalSwitchScannerDelegate>
{
    UIView *superView;
    CGRect originalRect, highlightedButtonRect, highlightedLabelRect;
    id lastSelectedItem;
    id lastActivatedItem;
}
@end
