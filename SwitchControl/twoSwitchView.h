//
//  twoSwitchView.h
//  SwitchControl
//
//  Created by Phil Weaver on 7/25/11.
//  Copyright 2011 PAW Solutions. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface twoSwitchView : UIViewController
{
    int switch_state;
}
@property (nonatomic, readwrite) int server_socket;
- (IBAction)activate1:(id)sender;
- (IBAction)deactivate1:(id)sender;
- (IBAction)activate2:(id)sender;
- (IBAction)deactivate2:(id)sender;

@end
