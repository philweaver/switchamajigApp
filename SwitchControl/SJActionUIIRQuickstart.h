//
//  SJActionUIIRQuickstart.h
//  SwitchControl
//
//  Created by Phil Weaver on 9/19/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "SJActionUI.h"

@interface SJActionUIIRQuickstart : SJActionUI <UIPickerViewDataSource, UIPickerViewDelegate> {
@public
    UIPickerView *irPicker;
    UILabel *irPickerLabel;
    NSArray *minimalFunctionSet;
    UIButton *filterFunctionButton;
    UIButton *testIrButton;
    NSMutableDictionary *deviceTypesToFunctionsDictionary;
}
@end
