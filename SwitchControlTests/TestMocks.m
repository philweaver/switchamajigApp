//
//  TestMocks.m
//  SwitchControl
//
//  Created by Phil Weaver on 11/9/12.
//  Copyright (c) 2012 PAW Solutions. All rights reserved.
//

#import "TestMocks.h"

@implementation MockNavigationController

- (void) pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    didReceivePushViewController = YES;
    lastViewController = viewController;
    [super pushViewController:viewController animated:animated];
}

- (UIViewController *) popViewControllerAnimated:(BOOL)animated {
    didReceivePopViewController = YES;
    return [super popViewControllerAnimated:animated];
}

@end

@implementation MockSwitchControlDelegate
- (void)performActionSequence:(DDXMLNode *)actionSequenceOnDevice {
    [commandsReceived addObject:actionSequenceOnDevice];
}
- (void) setIRBrand:(NSString *)brand andCodeSet:(NSString *)codeSet andDevice:(NSString *) device forDeviceGroup:(NSString *)deviceGroup {
    lastIRBrand = brand;
    lastIRCodeSet = codeSet;
    lastIRDevice = device;
    lastIRDeviceGroup = deviceGroup;
}
- (NSString *) getIRBrandForDeviceGroup:(NSString *)deviceGroup {
    return @"Panasonic";
}
- (NSString *) getIRCodeSetForDeviceGroup:(NSString *)deviceGroup {
    return irCodeSetToSend;
}
- (NSString *) getIRDeviceForDeviceGroup:(NSString *)deviceGroup {
    return @"TV";
}

@end

@implementation MockSwitchamajigIRDriver
- (void)issueCommandFromXMLNode:(DDXMLNode *)command error:(NSError **)err {
    //NSLog(@"Mock driver command issued. count = %d", [commandsReceived count]);
    //NSLog(@"Command = %@", [command XMLString]);
    [commandsReceived addObject:[command XMLString]];
    //NSLog(@"Mock driver count = %d on exit", [commandsReceived count]);
}

@end

@implementation MockSwitchamajigControllerDriver
- (void)issueCommandFromXMLNode:(DDXMLNode *)command error:(NSError **)err {
    //NSLog(@"Mock driver command issued. count = %d", [commandsReceived count]);
    //NSLog(@"Command = %@", [command XMLString]);
    [commandsReceived addObject:[command XMLString]];
    //NSLog(@"Mock driver count = %d on exit", [commandsReceived count]);
}

@end

@implementation HandyTestStuff

+ (id) findEditColorButtonInView:(UIView *)superview withColor:(UIColor *)color {
    UIView *view;
    for(view in [superview subviews]) {
        if(![view isKindOfClass:[UIButton class]])
            continue;
        CGRect frame = [view frame];
        if(frame.origin.x != 980)
            continue;
        UIButton *button = (UIButton *)view;
        if(([button buttonType] == UIButtonTypeCustom) && ([[button backgroundColor] isEqual:color]))
            return button;
    }
    return nil;
}

+ (id) findSubviewOf:(UIView *)view withText:(NSString *)text {
    UIView *subView;
    for(subView in [view subviews]) {
        if([subView isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *) subView;
            NSString *title = [button titleForState:UIControlStateNormal];
            //NSLog(@"Findsubview: looking for %@. Current text is %@.\n", text, title);
            if([title isEqualToString:text])
                return subView;
        }
    }
    return nil;
}


@end
