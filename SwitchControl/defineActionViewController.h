//
//  defineActionViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/25/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "switchPanelViewController.h"
#define NUM_SJIG_SWITCHES 6
@interface defineActionViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate> {
@public
    UIPickerView *actionPicker;
    UIButton *switchButtons[NUM_SJIG_SWITCHES];
}
- (id) initWithActions:(NSMutableArray *)actionsInit andFriendlyNames:(NSArray *)friendlyNamesInit;
@property (nonatomic, strong) NSMutableArray *actions;
@property (nonatomic, strong) NSMutableArray *friendlyNames;
@end
