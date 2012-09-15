//
//  quickIRConfigViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 9/14/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface quickIRConfigViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate> {
    
}
@property (unsafe_unretained, nonatomic) IBOutlet UIPickerView *codeSetPickerView;
@property (unsafe_unretained, nonatomic) IBOutlet UIPickerView *brandPickerView;

@end
