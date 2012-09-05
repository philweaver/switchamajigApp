//
//  chooseIconViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 9/4/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface chooseIconViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate> {
@public
    NSArray *iconImageNames;
    UIPickerView *iconPicker;
}
@property NSString *iconName;
@end
