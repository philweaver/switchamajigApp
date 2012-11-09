//
//  TestMocks.h
//  SwitchControl
//
//  Created by Phil Weaver on 11/9/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../../SwitchamajigDriver/SwitchamajigDriver/SwitchamajigDriver.h"
#import "../../SwitchamajigDriver/SwitchamajigDriver/SwitchamajigControllerDeviceDriver.h"
#import "SwitchControlAppDelegate.h"

@interface MockNavigationController : UINavigationController {
@public
    UIViewController *lastViewController;
    BOOL didReceivePushViewController;
    BOOL didReceivePopViewController;
}
@end

@interface MockSwitchControlDelegate : SwitchControlAppDelegate {
@public
    NSMutableArray *commandsReceived;
    NSString *lastIRBrand;
    NSString *lastIRCodeSet;
    NSString *lastIRDevice;
    NSString *lastIRDeviceGroup;
    NSString *irCodeSetToSend;
}
@end

@interface MockSwitchamajigIRDriver : SwitchamajigIRDeviceDriver {
@public
    NSMutableArray *commandsReceived;
}
@end

@interface MockSwitchamajigControllerDriver : SwitchamajigControllerDeviceDriver {
@public
    NSMutableArray *commandsReceived;
}
@end

@interface HandyTestStuff : NSObject {
}
+ (id) findEditColorButtonInView:(UIView *)superview withColor:(UIColor *)color;
+ (id) findSubviewOf:(UIView *)view withText:(NSString *)text;
@end
