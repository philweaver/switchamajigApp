//
//  SJActionUIlearnedIRCommand.h
//  SwitchControl
//
//  Created by Phil Weaver on 8/31/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "SJActionUI.h"

@interface SJActionUIlearnedIRCommand : SJActionUI <UIPickerViewDataSource, UIPickerViewDelegate> {
    UIPickerView *learnedIrPicker;
    UILabel *learnedIRPickerLabel;
    UILabel *learningIRInstructionsLabel;
    UIButton *learningIRCancelButton;
    UIButton *learnIRButton;
    UIActivityIndicatorView *learnIRActivityView;
    UIImageView *learnIRImage;
    UIButton *renameLearnedIRCommandButton;
    UIButton *deleteLearnedIRCommandButton;
    UIButton *confirmDeleteLearnedIRCommandButton;
    UIButton *testLearnedIRButton;
    NSMutableDictionary *learnedIRCommands;
    NSTimer *learnIRPollTimer;
    int learnIRAnimationCounter;
    UIButton *testIrButton;
}

@end
