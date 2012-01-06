//
//  configViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 1/4/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface configViewController : UIViewController {
}
- (void)alertView:(UIAlertView *) alertView didDismissWithButtonIndex:(NSInteger) buttonIndex;
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView;
- (IBAction)setBackgroundWhite:(id)sender;
- (IBAction)setBackgroundBlack:(id)sender;
@property (retain, nonatomic) IBOutlet UILabel *ConfigTitle;
@property (retain, nonatomic) IBOutlet UILabel *ConfigAppLabel;
@property (retain, nonatomic) IBOutlet UILabel *BackgroundColorLabel;
@end
