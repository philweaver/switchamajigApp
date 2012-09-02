//
//  SJActionUIIRDatabaseCommand.h
//  SwitchControl
//
//  Created by Phil Weaver on 8/31/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "SJActionUI.h"

@interface SJActionUIIRDatabaseCommand : SJActionUI <UIPickerViewDataSource, UIPickerViewDelegate> {
@public
    UIPickerView *irPicker;
    UILabel *irPickerLabel;
    NSArray *brands;
    NSArray *devices;
    NSArray *codeSets;
    NSArray *functions;
    UIButton *filterBrandButton;
    UIButton *filterFunctionButton;
    UIButton *testIrButton;
}

@end
