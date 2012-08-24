//
//  defineActionViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/25/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "switchPanelViewController.h"
#import "SwitchControlAppDelegate.h"
#define NUM_SJIG_SWITCHES 6
@interface defineActionViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate> {
@public
    UIPickerView *actionPicker;
    UIPickerView *irPicker;
    UIButton *switchButtons[NUM_SJIG_SWITCHES];
    NSArray *brands;
    NSArray *devices;
    NSArray *functions;
    UIButton *filterBrandButton;
    UIButton *testIrButton;
    NSMutableArray *friendlyNamesArray;
}
- (id) initWithActions:(NSMutableArray *)actionsInit appDelegate:(SwitchControlAppDelegate *)appDelegate;
@property (nonatomic, strong) NSMutableArray *actions;
@property (nonatomic, strong) SwitchControlAppDelegate *appDelegate;
@end
