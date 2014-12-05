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
- (NSArray *) popToRootViewControllerAnimated:(BOOL)animated {
    didReceivePopToRootViewController = YES;
    return [super popToRootViewControllerAnimated:animated];
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

@implementation MockSwitchamajigInsteonDriver
- (void)issueCommandFromXMLNode:(DDXMLNode *)command error:(NSError **)err {
    //NSLog(@"Mock driver command issued. count = %d", [commandsReceived count]);
    //NSLog(@"Command = %@", [command XMLString]);
    [commandsReceived addObject:[command XMLString]];
    //NSLog(@"Mock driver count = %d on exit", [commandsReceived count]);
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


+ (vm_size_t) usedMemory {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0; // size in bytes
}

+ (vm_size_t) freeMemory {
    mach_port_t host_port = mach_host_self();
    mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    vm_size_t pagesize;
    vm_statistics_data_t vm_stat;
    
    host_page_size(host_port, &pagesize);
    (void) host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size);
    return vm_stat.free_count * pagesize;
}

#define DIFF_TO_REPORT -1
+ (void) logMemUsage {
    // compute memory usage and log if different by >= 100k
    static long prevMemUsage = 0;
    long curMemUsage = [HandyTestStuff usedMemory];
    long memUsageDiff = curMemUsage - prevMemUsage;
    
    if (memUsageDiff > DIFF_TO_REPORT || memUsageDiff < -DIFF_TO_REPORT) {
        prevMemUsage = curMemUsage;
        NSLog(@"Memory used %7.1f (%+5.0f), free %7.1f kb", curMemUsage/1000.0f, memUsageDiff/1000.0f, [HandyTestStuff freeMemory]/1000.0f);
    }
}

@end

