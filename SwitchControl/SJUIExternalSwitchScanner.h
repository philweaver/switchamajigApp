/*
Copyright 2014 PAW Solutions LLC

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

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
    __weak UITextField *textField; // Prevents a strong reference loop
    CGRect originalRectOfCurrentButton;
    CGRect originalRectOfCurrentLabel;
    NSTimer *autoScanTimer;
}

@property (nonatomic, weak) id<SJUIExternalSwitchScannerDelegate> delegate;
@property NSNumber *autoScanInterval;
- (void) addButtonToScan:(UIButton*)button withLabel:(UILabel*)label;
- (void) removeAllScanButtons;
- (id) initWithSuperview:(UIView*)superview andScanType:(int)scanTypeInit;
- (UIButton*) currentlySelectedButton;
- (void) superviewDidAppear;
@end
