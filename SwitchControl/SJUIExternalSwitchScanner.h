//
//  SJUIExternalSwitchScanner.h
//  SwitchControl
//
//  Created by Phil Weaver on 11/7/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
enum {SCANNING_STYLE_NONE=0,SCANNING_STYLE_AUTO_SCAN=1,SCANNING_STYLE_STEP_SCAN=2};

@protocol SJUIExternalSwitchScannerDelegate <NSObject>
@required
- (void) SJUIExternalSwitchScannerItemWasSelected:(id)item;
- (void) SJUIExternalSwitchScannerItemWasActivated:(id)item;
@end

@interface SJUIExternalSwitchScanner : NSObject <UITextFieldDelegate>
{
@public
    NSMutableArray *buttonsToScan;
    int scanType;
    int indexOfSelection;
    UITextField *textField;
    CGRect originalRectOfCurrentButton;
    CGRect originalRectOfCurrentLabel;
    NSTimer *autoScanTimer;
}

@property (nonatomic) id<SJUIExternalSwitchScannerDelegate> delegate;
@property NSNumber *autoScanInterval;
- (void) addButtonToScan:(UIButton*)button withLabel:(UILabel*)label;
- (id) initWithSuperview:(UIView*)superview andScanType:(int)scanTypeInit;
- (UIButton*) currentlySelectedButton;
- (void) superviewDidAppear;
@end
