//
//  fourSwitchAcrossView.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/27/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface fourSwitchAcrossView : UIViewController {
    int switch_state;
    UIButton *backButton;
}
@property (nonatomic, readwrite) int server_socket;
- (IBAction)activate1:(id)sender;
- (IBAction)deactivate1:(id)sender;
- (IBAction)activate2:(id)sender;
- (IBAction)deactivate2:(id)sender;
- (IBAction)activate3:(id)sender;
- (IBAction)deactivate3:(id)sender;
- (IBAction)activate4:(id)sender;
- (IBAction)deactivate4:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)enableBack:(id)sender;
@property (nonatomic, retain) IBOutlet UIButton *backButton;

@end
