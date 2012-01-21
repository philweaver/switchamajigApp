//
//  configViewController.h
//  SwitchControl
//
//  Created by Phil Weaver on 1/4/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwitchControlAppDelegate.h"

@interface configViewController : UIViewController {
@public
    SwitchControlAppDelegate *appDelegate;
    NSString *switchName;
}
- (void)alertView:(UIAlertView *) alertView didDismissWithButtonIndex:(NSInteger) buttonIndex;
- (BOOL)alertViewShouldEnableFirstOtherButton:(UIAlertView *)alertView;
- (IBAction)Cancel:(id)sender;
@property (retain, nonatomic) IBOutlet UILabel *ConfigTitle;
@property (retain, nonatomic) IBOutlet UILabel *ConfigAppLabel;
@property (retain, nonatomic) IBOutlet UILabel *BackgroundColorLabel;
@property (retain, nonatomic) IBOutlet UILabel *ConfigureNetworkLabel;
@property (retain, nonatomic) IBOutlet UIActivityIndicatorView *ScanActivityIndicator;
@end
