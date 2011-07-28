//
//  singleSwitchView.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/23/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface singleSwitchView : UIViewController
{
    int switch_state;
    UIButton *backButton;
}
@property (nonatomic, readwrite) int server_socket;
- (IBAction)activate:(id)sender;
- (IBAction)deactivate:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)enableBack:(id)sender;
@property (nonatomic, retain) IBOutlet UIButton *backButton;

@end
