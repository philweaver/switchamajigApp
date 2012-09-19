//
//  quickIRConfigViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 9/14/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwitchControlAppDelegate.h"

@interface quickIRConfigViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate> {
@public
    NSMutableArray *brands;
    NSArray *codeSets;
}
@property (unsafe_unretained, nonatomic) IBOutlet UIPickerView *codeSetPickerView;
@property (unsafe_unretained, nonatomic) IBOutlet UIPickerView *brandPickerView;
@property NSString *deviceGroup; // device types separated with '/'
@property NSURL *urlForControlPanel;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *filterBrandButton;
@property SwitchControlAppDelegate *appDelegate;
- (IBAction)filterBrandToggle:(id)sender;
@end
