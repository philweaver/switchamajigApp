//
//  SJActionUITurnSwitchesOnOff.h
//  SwitchControl
//
//  Created by Phil Weaver on 8/31/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "SJActionUI.h"
#define NUM_SJIG_SWITCHES 6

@interface SJActionUITurnSwitchesOnOff : SJActionUI {
@public
    UIButton *switchButtons[NUM_SJIG_SWITCHES];
}
@end

@interface SJActionUITurnSwitchesOn : SJActionUITurnSwitchesOnOff

@end

@interface SJActionUITurnSwitchesOff : SJActionUITurnSwitchesOnOff

@end
