//
//  defineActionViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/25/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol SJUIDefineActionViewController <NSObject>
- (void) SJUIDefineActionViewControllerReadyForDismissal:(id)viewController;
@end
#import "switchPanelViewController.h"
#import "SwitchControlAppDelegate.h"



@interface defineActionViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate> {
@public
    NSMutableArray *friendlyNamesArray;
    UIPickerView *actionPicker;
    NSDictionary *actionNamesToSJActionUIDict;
    NSMutableArray *availableActions;
    UIButton *cancelButton;
    UIButton *doneButton;
}
- (id) initWithActions:(NSMutableArray *)actionsInit appDelegate:(SwitchControlAppDelegate *)appDelegate;
-(SwitchamajigDriver*) getCurrentlySelectedDriver;
@property (nonatomic, strong) NSMutableArray *actions;
@property (nonatomic, strong) SwitchControlAppDelegate *appDelegate;
@property id<SJUIDefineActionViewController>delegate;
@end
